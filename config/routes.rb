Traktflix::Application.routes.draw do
  get "main/index"

  get "main/connect"
  match "/connect" => "main#connect"

  get "main/select"
  match "/select" => "main#select"

  get "main/submit"
  post "main/submit"
  match "/submit" => "main#submit"

  root :to => "main#index"
end
