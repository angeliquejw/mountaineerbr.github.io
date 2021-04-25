/*!
 * jQuery Srcset Plugin
 * Original author: Lucas Constantino Silva
 * Licensed under the MIT license
 */

;(function ($, window, document, undefined) {

  var pluginName = 'autoSrcset'
    , instance = null
    , commands = {
        update: update
      , destroy: destroy
      }
    , $window = $(window);

  $.fn[pluginName] = function (options) {
    return (options && commands[options] && commands[options].call(this)) || this.each(function () {
      if (!$.data(this, pluginName)) {
        $.data(this, pluginName, new AutoSrcset(this, options));
      }
    });
  };

  /**
   * AutoSrcset element class.
   */
  function AutoSrcset(element, options) {

    // Bind update method.
    var update = this.update.bind(this);

    // Generate accessible plugin data.
    this.element = element;
    this.$element = $(element);
    this.defaultSource = element.src;

    // Parse original image.
    this.originalSrc = parseSrc(this.$element.attr('data-original-image') || '');
    this.$element.data('original-image', this.originalSrc);

    // Parse srcset.
    this.srcset = parseDataSrcset(this.$element.attr('data-srcset') || '');
    this.$element.data('srcset', this.srcset);

    // Bind update to resize and load events.
    this.$element.on('resize.autoSrcset', update).one('load.autoSrcset', update);

    // First update.
    this.$element.trigger('resize.autoSrcset');
  }

  /**
   * Modifies src with ideal url from srcset.
   */
  AutoSrcset.prototype.update = function () {
    var element = this.element
      , $element = this.$element
      , width = element.width || $element.width()
      , height = element.height || $element.height()
      , src = element.src || $element.attr('src')

        // Get srcset with delta for current image.
      , srcset = (this.srcset || []).map(function (set) {
          set.hDelta = (set.width || 0) / (width || 1);
          set.vDelta = (set.height || 0) / (height || 1);
          return set;
        }).sort(function (a, b) {
          // @todo : consider height as well.
          return a.hDelta > b.hDelta ? 1 : a.hDelta < b.hDelta ? -1 : 0;
        })

        // Find current set if in the list.
      , curr = this.curr || srcset.filter(function (set) {
          return set.src == src;
        })[0]

        // Find ideal set based on image current width.
      , ideal = srcset.filter(function (set) {
          // @todo : consider height as well.
          return set.hDelta >= 1;
        })[0] || srcset[srcset.length - 1];

    // Conditional change.
    // @todo : consider height as well.
    if (ideal && (!curr || curr.width < ideal.width)) {
      this.curr = ideal;
      $('<img />').on('load', function () {
        $element.attr('src', ideal.src).trigger('update.autoSrcset');
        if ($element.is('[forced-width]')) {
          $element.removeAttr('width').removeAttr('forced-width');
        }
      }).attr('src', ideal.src);
    }
  };

  /**
   * Uninstantiate plugin.
   */
  AutoSrcset.prototype.destroy = function () {
    this.$element.off('.autoSrcset');
    this.element.src = this.defaultSource;
  };


  /*
   * Command functions
   * -----------------
   */

  /**
   * Update command.
   */
  function update() {
    this.each(function () {
      if (instance = $.data(this, pluginName) && instance.$element) {
        instance.update();
      }
    });

    // Chainable command.
    return this;
  }

  /**
   * Destroy command.
   */
  function destroy() {
    this.each(function () {
      if (instance = $.data(this, pluginName) && instance.$element) {
        var event = $.Event(pluginName + ':destroy');
        instance.$element.trigger(event);
        if (!event.isDefaultPrevented()) instance.destroy();
      }
    });

    // Chainable command.
    return this;
  }


  /*
   * Helper functions
   * ----------------
   */

  /**
   * Parse data-srcset value.
   */
  function parseDataSrcset(value) {
    return value.split(',').map(parseSrc).filter(notNull);
  }

  /**
   * Parse src definition.
   */
  function parseSrc(src) {
    var parts = src.trim().replace(/ {2,}/g, ' ').split(' ').map(function (value, key) {
      return key == 0 ? value : parseFloat(value);
    });

    return parts && parts.length && {
      src:    parts[0]
    , width:  parts[1] || 0
    , height: parts[2] || 0
    } || null;
  }

  /**
   * Not null filter.
   */
  function notNull(value) {
    return value !== null;
  }

})(jQuery, window, document);