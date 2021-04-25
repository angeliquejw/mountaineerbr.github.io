/**
 * @file
 * IELA Same Height Style JavaScript activation.
 */

;(function ($, Drupal, window, document, undefined) {

  /**
   * Match height behavior.
   */
  Drupal.behaviors.ielaMatchHeight = {
    defaults: {
      byRow: true
    },
    attach: function (context, settings) {

      // Early return.
      if (!settings.ielaSameHeight || !$.fn.matchHeight) return;

      var $context = $(context);
      var defaults = this.defaults;

      $.each(settings.ielaSameHeight, function (wrapperSelector, configs) {
        if (typeof wrapperSelector === 'string' && !wrapperSelector.match(/^#[a-zA-Z][\w:.-]*$/)) return true;
        if (!$.isArray(configs)) configs = [configs];

        $.each(configs, function (index, config) {
          config = $.extend(true, {}, defaults, typeof config === 'object' ? config : {
            selector: config
          });

          var $wrappers = $context.find(wrapperSelector);
          if (!$wrappers.length) $wrappers = $context.closest(wrapperSelector);

          $wrappers.each(function () {
            var $wrapper = $(this);
            $.each($.isArray(config.selector) ? config.selector : [config.selector], function (i, selector) {
              var $elements = $wrapper.findExclude(selector, '.panel-display');

              // Instantiate plugin.
              if ($elements.length > 1) $elements.matchHeight(config.byRow);
            });
          });
        });
      });
    }
  };

})(jQuery, Drupal, this, this.document);
