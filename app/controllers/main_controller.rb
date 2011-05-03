require 'yaml'           # for third-party config parsing
require 'oauth/consumer' # for Netflix API authentication
require 'rexml/document' # for Netflix API XML parsing
require 'digest/sha1'    # for Trakt password
require 'net/http'       # for Trakt API requests

include REXML

class MainController < ApplicationController
    def index
    end

    def connect
        # retrieve config settings for the Netflix API
        thirdparty = YAML::load(File.open("#{RAILS_ROOT}/config/thirdparty.yml"))
        nflxconf   = thirdparty['netflix']

        # construct a callback URL for the OAuth handshake
        callback_url = url_for(:action => 'connect', :only_path => false)

        # first time at this action, send user to OAuth authorization URL
        if session[:request_token].nil?
            @consumer = OAuth::Consumer.new nflxconf['application_key'], nflxconf['shared_secret'], {
                :request_token_url => NFLX_URL_REQUEST_TOKEN,
                :authorize_url     => NFLX_URL_AUTHORIZE_USER,
                :access_token_url  => NFLX_URL_ACCESS_TOKEN
            }

            @request_token = @consumer.get_request_token :oauth_callback => callback_url
            session[:request_token] = @request_token

            redirect_to @request_token.authorize_url(:oauth_callback => callback_url,
                :oauth_consumer_key => nflxconf['application_key'])

        # user has triumphantly returned, retrieve and save an access token
        else
            @request_token = session[:request_token]
            @access_token = @request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
            session[:access_token] = @access_token
            session[:request_token] = nil

            redirect_to :action => 'select'

        end

        # an Unauthorized from the Netflix API, try again
        #rescue OAuth::Unauthorized
        #    session[:request_token] = nil
        #    redirect_to :action => 'connect'
    end

    def select
        # ensure that an access_token is available
        redirect_to :action => 'index' unless session[:access_token]

        @access_token = session[:access_token]

        # get the current user base URL
        current_user = @access_token.get(NFLX_URL_CURRENT_USER)
        doc = Document.new current_user.read_body
        current_user_base_url = doc.get_elements("/resource/link").first.attributes["href"]

        # get the Netflix instant watched history
        watched_history = @access_token.get(current_user_base_url + NFLX_URL_USER_WATCHED_HISTORY_SUFFIX)
        doc = Document.new watched_history.read_body
        @rental_history_items = doc.get_elements("/rental_history/rental_history_item")

        # get the Netflix instant watched history
        returned_history = @access_token.get(current_user_base_url + NFLX_URL_USER_RETURNED_HISTORY_SUFFIX)
        doc = Document.new returned_history.read_body
        @rental_history_items = @rental_history_items + doc.get_elements("/rental_history/rental_history_item")
    end

    def submit
        # retrieve config settings for the Netflix API
        thirdparty = YAML::load(File.open("#{RAILS_ROOT}/config/thirdparty.yml"))
        traktconf  = thirdparty['trakt']

        # ensure that an access_token is available
        redirect_to :action => 'index' unless session[:access_token]

        # ensure that movies were specified in POST params
        redirect_to :action => 'select' if params[:movie].nil?

        @access_token = session[:access_token]

        # setup the request to the Trakt API
        @trakt_out = {'username' => params[:trakt_username],
        'password' => Digest::SHA1.hexdigest(params[:trakt_password]),
        'movies' => []
        }

        # populate the Trakt API request with selected movies
        params[:movie].each do |item|
            catalog = @access_token.get(NFLX_URL_CATALOG_BASE + item)
            doc = Document.new catalog.read_body
            @trakt_out['movies'].push({
                'title' => doc.root.elements["title"].attributes["regular"],
                'year' => doc.root.elements['release_year'].text
            })
        end

        # perform the Trakt API POST request to commit movies to the user's library
        web  = Net::HTTP.new TRAKT_URL_API
        resp = web.post(TRAKT_URI_API_MOVIES_SEEN + traktconf['api_key'],
            ActiveSupport::JSON.encode(@trakt_out))
puts resp.read_body
        @trakt_in = ActiveSupport::JSON.decode resp.read_body
    end
end

