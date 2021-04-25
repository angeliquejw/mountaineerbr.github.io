$(document).ready(function(){
	var altura = $('#menu').offset().top;

	$(window).on('scroll', function(){
		if  ($(window).scrollTop() > altura){
			$('#menu').addClass('menu-transition').removeClass('menu-opacity');
		} else {
			$('#menu').removeClass('menu-transition').addClass('menu-opacity');
		}
	});
});
