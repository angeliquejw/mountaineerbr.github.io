/**
 * @file
 * Inserts Smooth Scroll.
 */

;(function ($, Drupal, window, document, undefined) {

Drupal.behaviors.smoothScroll = {
  attach: function (context, settings) {

    var $context = $(context)
      , togglers = $context.find('a[href*=#]:not([href=#])').filter(targetExists);

    // smoothScrol plugin works on all links, but activates for those who have
    // data-scroll attribute set.
    togglers.attr('data-scroll', '');


    /*
     * Text link adjustments.
     */

    togglers.filter(targetInText).each(function () {
      try {
        var $toggler = $(this)
          , currentOptions = JSON.parse($toggler.attr('data-options') || '{}')
          , options = $.extend(true, {}, currentOptions, {
              offset: 100
            });

        $toggler.attr('data-options', JSON.stringify(options));
      } catch (e) {}
    });

    smoothScroll && smoothScroll.init({
      easing: 'easeInOutCubic',
      offset: 60
    });
  }
};

/**
 * Filtering function that checks toggler's hash target exists.
 */
function targetExists() {
  return $(this.hash).length;
}

/**
 * Filtering function that checks if toggler's hash targets resides in text.
 */
function targetInText() {
  return $(this.hash).closest('.panopoly-wysiwyg-text').length;
}

})(jQuery, Drupal, this, this.document);
