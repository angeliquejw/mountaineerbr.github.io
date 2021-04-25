/**
 * @file
 * Footer JavaScript adjustments.
 */

;(function ($, Drupal, window, document, undefined) {

/**
 * E-mail validation.
 */
function isValidEmailAddress(emailAddress) {
  var pattern = new RegExp(/^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i);
  return pattern.test(emailAddress);
};

Drupal.behaviors.simplenewsFormAjax = {
  attach: function (context, settings) {
    // Subscription.
    $('.simplenews', context).once('iela-subscribe', function () {

      var $form = $(this)
        , $wrapper = $form.find('> div')
        , $mail = $form.find('input[name="mail"]')
        , $result = $('<div />', {
          'class': 'simplenews-result'
        })
        , subscribe = $form.hasClass('simplenews-subscribe');

      $result.html(subscribe ? Drupal.t('Thanks for subscribing!') : Drupal.t('You\'ll no longer receive our mails!'));

      /**
       * Clear e-mail validation.
       */
      function clearValidation() {
        if (!$mail.val()) $mail.closest('.form-group').removeClass('has-error');
      }

      /**
       * Handle form submition.
       */
      function ajaxSubmit(e) {

        // Avoid default submit.
        e.preventDefault();

        // Simple e-mail validation.
        if ($mail.length && !isValidEmailAddress($mail.val())) {
          return $mail.closest('.form-group').addClass('has-error');
        }

        // Send data.
        $.ajax({
          type: 'post'
        , url: $form.attr('action')
        , data: $form.serialize()
        , encode: true
        });

        $wrapper.fadeOut(500, function () {
          $wrapper.html('').append($result).fadeIn(750);
        })
      }

      $mail.on('keyup', clearValidation);
      $form.on('submit', ajaxSubmit);
    });
  }
};

Drupal.behaviors.ielaSiteMap = {
  attach: function (context, settings) {

    // Easy access.
    var $footer = $('#footer', context);

    // Early return.
    if (!$footer.length) return;

    // Site map.
    if ($.fn.masonry) {
      $footer.find('#sitemap').once('sitemap-masonry', function () {
        $(this).masonry({
          itemSelector: '.sitemap > li'
        });
      });
    }
  }
};

})(jQuery, Drupal, this, this.document);
