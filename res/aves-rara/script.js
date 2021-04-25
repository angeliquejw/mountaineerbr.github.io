/**
 * @file
 * Generic JavaScript adjustments.
 */

;(function ($, Drupal, window, document, undefined) {

  // Remove unwanted radix behaviors.
  delete Drupal.behaviors.radix_tab;

  var IELAUpdateListeners = {};

  /**
   * Register a new update listener.
   */
  Drupal.IELAUpdateListener = function (name, updateFunction) {
    IELAUpdateListeners[name] = updateFunction;
  };

  /**
   * Calling this will execute all update listeners.
   */
  Drupal.IELAUpdate = function (options) {
    $.each(IELAUpdateListeners, function (name, updateFunction) {
      if (updateFunction && updateFunction.apply) {
        updateFunction.apply(null, options && options[name] || null);
      }
    });
  };

  /**
   * Generates a unique ID.
   */
  function unique() {
    return Math.round(new Date().getTime() + (Math.random() * 100));
  }

  /**
   * Adjust extra margin for tables with caption.
   */
  Drupal.behaviors.tableCaption = {
    attach: function (context, settings) {
      $(context).find('.table > caption').parent().addClass('has-caption');
    }
  };

  /**
   * Adjust WYSWYG fields.
   */
  Drupal.behaviors.ielaWYSIWYGField = {
    attach: function (context, settings) {
      // @todo better identify WYSIWYG formatted fields.
      $('.panopoly-wysiwyg-text', context).each(function () {
        var $field = $(this)
          , $images = $field.find('img');

        /*
         * Adjust image width for adaptative images.
         */
        $images.filter('[data-original-image]').each(function () {
          var $image = $(this)
            , originalImage = $image.data('original-image');

          if (originalImage && originalImage.width && !$image.get(0).style.width) {
            $image.width(originalImage.width);
          }
        });

        /*
         * Adjust center-aligned media elements.
         */
        $images.filter('.pull-center').closest('div,p').css('text-align', 'center');
      });
    }
  };

  /**
   * Adjust node embed alingment.
   */
  Drupal.behaviors.wysiwygNodeEmbed = {
    attach: function (context, settings) {
      $('.panopoly-wysiwyg-text .node-node-embed', context).each(function () {
        var $node       = $(this)
          , $container  = $node.closest('div').not('.field-item').not('.field-items')
          , classes     = $container.attr('class');

        if (classes) {
          $container.attr('class', '');
          $node.addClass(classes);
        }
      });
    }
  };

  /**
   * Attach clickable areas.
   */
  Drupal.behaviors.ielaDataClick = {
    attach: function (context, settings) {
      $('[data-click]', context).each(ielaDataClick);
    }
  };

  /**
   * Handles click on wrapping containers.
   */
  function ielaDataClick() {
    var $clickable = $(this)
      , $links = $clickable.find('a')
      , href = $clickable.attr('data-click') || $clickable.attr('href')
      , target = $clickable.attr('data-click-target') || '_self';

    if (href) {
      $links.on('click', function (e) {
        e.stopPropagation();
      });

      $clickable.css('cursor', 'pointer').on('click', function (e) {
        navigate(e, href, target);
      });
    }
  }

  /**
   * Adds context to Bootstrap data-target.
   */
  Drupal.behaviors.ielaDataToggleContext = {
    attach: function (context, settings) {
      $('[iela-data-target-context]', context).once('iela-data-target-context', function () {
        var $toggler      = $(this)
          , target        = $toggler.attr('data-target')
          , targetContext = $toggler.attr('iela-data-target-context')
          , $context, id, targetContextSelector;

        $context = $toggler.closest(targetContext);
        id = unique();
        targetContextSelector = '[iela-data-target-context=' + id + ']';

        // Mark context.
        $context.attr('iela-data-target-context', id);

        // Update target.
        $toggler.attr('data-target', targetContextSelector + ' ' + target);
      });
    }
  };

  /**
   * Attach dropdown toggler on dropdown menus.
   */
  Drupal.behaviors.tallerDropdown = {
    attach: function(context, setting) {
      $('.dropdown > a.dropdown-toggle', context).each(tallerDropdownToggle);
    }
  };

  // Overrid radix dropdown behavior.
  Drupal.behaviors.radix_dropdown = {
    attach: function(context, setting) {}
  };

  var tallerDropdownToggleAttachListeners = []
    , tallerDropdownToggleDettachListeners = [];

  $(function () {
    Drupal.Breakpoints.register(['xs', 'sm'], function () {
      tallerCallAll(tallerDropdownToggleDettachListeners);
    });

    Drupal.Breakpoints.register(['md', 'lg'], function () {
      tallerCallAll(tallerDropdownToggleAttachListeners);
    });
  });

  /**
   * Helper method to call all callbacks from a given array, optionally
   * with attributes.
   */
  function tallerCallAll(callbacks) {
    var args = [].slice.call(arguments, 1);
    callbacks.forEach(function (callback) {
      callback.apply(null, args);
    });
  }

  /**
   * Activate dropdown toggling on a navbar menu item.
   */
  function tallerDropdownToggle() {
    var $toggler = $(this)
      , $item = $toggler.parent()
      , action = $toggler.attr('data-dropdown-action') || 'hover'
      , target = $toggler.attr('target') || '_self'
      , event = action + '.taller.dropdown'
      , href;

    // Always handle clicks.
    $toggler.on('click.taller.dropdown', onClick);

    // At least handle something buggy when no Breakpoints are available.
    if (!Drupal.Breakpoints || !Drupal.Breakpoints.isCurrent(['md', 'lg'])) attach();

    tallerDropdownToggleAttachListeners.push(attach);
    tallerDropdownToggleDettachListeners.push(dettach);

    /**
     * Attach listeners.
     */
    function attach() {
      switch (action) {
        case 'hover':
          $item.on('mouseenter.taller.dropdown', show);
          $item.on('mouseleave.taller.dropdown', hide);
        case 'focus':
          $item.on('focusin.taller.dropdown', show);
          $item.on('focusout.taller.dropdown', hide);
          break;
        default:
          $toggler.on(event, toggle);
          break;
      }
    }

    /**
     * Remove listeners.
     */
    function dettach() {
      $item.off('.taller.dropdown');
      $toggler.off(event);
    }

    /**
     * Toggle dropdown state.
     */
    function toggle() {
      // debugger;
      $toggler.attr('aria-expanded', $item.toggleClass('open').hasClass('open'));
    }

    /**
     * Show dropdown.
     */
    function show() {
      $item.addClass('open');
      $toggler.attr('aria-expanded', true);
    }

    /**
     * Show dropdown.
     */
    function hide() {
      $item.removeClass('open');
      $toggler.attr('aria-expanded', false);
    }

    /**
     * Navigates main dropdown link, when desired.
     */
    function onClick(e) {
      e.preventDefault();
      if ((action !== 'click' || e.ctrlKey || e.which == 2) && (href = $(this).attr('href'))) {
        navigate(e, href, target);
      }
    }
  }

  /**
   * Navigation generic method.
   */
  function navigate(e, href, target) {
    e.preventDefault();
    e.stopImmediatePropagation();
    window.open(href, e.ctrlKey || e.which == 2 ? '_blank' : target || '_self');
    return false;
  }

  /**
   * Toggle breakpoint classes.
   */
  $(function () {

    // Early return.
    if (!Drupal.Breakpoints || !Drupal.settings.breakpoints) return;

    var $html = $('html');

    // Keep document aware of current breakpoint.
    Drupal.Breakpoints.register('any', function () {
      $.each(Drupal.settings.breakpoints, function (machineName, breakpoint) {
        $html.toggleClass('breakpoint-' + breakpoint.name, Drupal.Breakpoints.isCurrent(machineName));
      });
    });
  });

  /**
   * Shame!
   */
  Drupal.behaviors.ielaShame = {
    attach: function (context, settings) {

      var $context = $(context);

      // @todo: User profiles use a image style that wraps the image in a
      // link to the entity. The link is created even thought the user is
      // blocked, which is definitelly a security bug.
      $context.find('.field-name-field-user-picture a').on('click', function (e) {
        e.preventDefault();
      }).css('cursor', 'default');
    }
  };

})(jQuery, Drupal, this, this.document);
