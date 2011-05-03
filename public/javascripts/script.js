$(function() {
	// harmonize the click behaviour on each title, between the container (<li>) and the checkbox (<input>)
	$('#netflix-select-container ul li').click(function(e) {
		$(this).toggleClass('selected');
		$(this).children('input:checkbox').attr('checked', $(this).hasClass('selected'));
	});

	// aggregate selection options
	$('#netflix-select-container .select-options a.option-all').click(function(e) {
		$('#netflix-select-container ul li input:checkbox').attr('checked', true);
		$('#netflix-select-container ul li').addClass('selected');
		e.preventDefault();
	});
	$('#netflix-select-container .select-options a.option-none').click(function(e) {
		$('#netflix-select-container ul li input:checkbox').attr('checked', false);
		$('#netflix-select-container ul li').removeClass('selected');
		e.preventDefault();
	});
	$('#netflix-select-container .select-options a.option-inv').click(function(e) {
		$('#netflix-select-container ul li input:checkbox').attr('checked', function(i, val) { return !val });
		$('#netflix-select-container ul li').toggleClass('selected');
		e.preventDefault();
	});

	$('#step-submit a.submit-form').click(function() {
		$('#netflix-select-container form').submit();
		return false;
	});
});
