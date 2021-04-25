/**
 * @file
 * IELA Masonry Style JavaScript activation.
 */

;(function ($, Drupal, window, document, undefined) {

/**
 * Apply masonry to container with selector.
 */
function initMasonry($container, itemSelector) {
  var options = {};

  if (itemSelector) options.itemSelector = itemSelector;
  if ($container.is('.row')) options.columnWidth = $container.width() / 12;

  $container.masonry(options);
}

Drupal.behaviors.ielaMasonry = {
  attach: function (context, settings) {

    if (!settings.ielaMasonry) return;
    if (Drupal.PanelsIPE) return;

    // Parse context.
    var $context = $(context);

    $.each(settings.ielaMasonry, function (id, options) {
      if (!id.match(/^#[a-zA-Z][\w:.-]*$/)) return true;

      var $wrapper = $context.find(id)
        , $container = $wrapper.findExclude(options.containerSelector || id, '.panel-display');

      if ($container.length) {
        setTimeout(function () {
          initMasonry($container, options.itemSelector);
        }, 200);
      } else {
        $wrapper = $context.closest(id);
        $container = $wrapper.findExclude(options.containerSelector || id, '.panel-display');

        if ($container.length && $container.data('masonry')) {
          initMasonry($container.masonry('destroy'), options.itemSelector);
        }
      }
    });
  }
};

})(jQuery, Drupal, this, this.document);
