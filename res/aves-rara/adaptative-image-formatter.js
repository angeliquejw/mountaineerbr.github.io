/**
 * @file
 * Adaptative Image Formatter script.
 */

;(function ($, Drupal, window, document, undefined) {

/**
 * Initializes adaptative images.
 */ 
Drupal.behaviors.adaptativeImageFormatter = {
  attach: function (context) {
    $('[data-srcset]', context).autoSrcset().filter(':not(img)').on('update.autoSrcset', function (e) {
      var $element = $(this);
      if ($element.is(e.target)) {
        $element.css('background-image', 'url("' + $element.attr('src') + '")');
      }
    });
  }
};

})(jQuery, Drupal, this, this.document);
