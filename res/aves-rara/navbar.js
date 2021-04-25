/**
 * @file
 * Navbar adjustments.
 */

;(function ($, Drupal, window, document, undefined) {

var initiated = {}
  , previous  = {}
  , $body = $html = null;

/**
 * Sort navbars.
 */
function sortNavbars(a, b) {
  return a.settings.weight >= b.settings.weight;
}

/**
 * Helper method to run callback on every container width change.
 */
Drupal.ielaOnWidthChange = function (callback) {
  var responsive = false;
  if (Drupal.Breakpoints) Drupal.Breakpoints.register('any', function () {
    // Make sure we execute it at start.
    callback();

    // Turn on/off window resize listening event.
    $(window)[Drupal.Breakpoints.isCurrent('xs') ? 'on' : 'off']('resize', callback);
  });
};

/**
 * Activates sticky jQuery plugin to navbars.
 */
Drupal.behaviors.ielaStickyNavbar = {
  attach: function (context, settings) {

    // Avoid waste of processing if Sticky is not loaded.
    if ($.fn.sticky) {

      if (!$body) $body = $('body');

      var newItems      = false
        , modifiedItems = false
        , stopMain      = false
        , zIndex        = 500
        , ordered       = []
        , onlyMain      = $body.hasClass('stick-main-navbar');

      // Hold previous settings.
      previous = initiated;

      // Refresh initiated.
      initiated = {};

      // Load items.
      $.each(!onlyMain && settings.ielaStickyNavbar || {}, function (selector, settings) {

        // Clean navbar settings values.
        settings.weight = parseInt(settings.weight) || 0;
        settings.stopMain = Boolean(settings.stopMain);

        // Add to list.
        ordered.push({
          selector: selector,
          settings: settings
        });

        // Hold update information.
        if (!previous[selector]) newItems = true;
        if (previous[selector] && previous[selector].weight != settings.weight) modifiedItems = true;
        if (previous[selector] && previous[selector].stopMain != settings.stopMain) modifiedItems = true;
        if (settings.stopMain) stopMain = true;
      });

      // Sort weights of navbars.
      ordered.sort(sortNavbars);

      // Start main navbar.
      if (!stopMain && !previous['#header']) {
        ordered.unshift({
          selector: '#header',
          settings: {}
        });

        newItems = true;
      }

      // Avoid further processing.
      if (!ordered.length || (!newItems && !modifiedItems)) return;

      // Register navbar for initiation.
      ordered.forEach(function (item) {
        initiated[item.selector] = $.extend(previous[item.selector] || {}, item.settings);
      });

      // Clean current configurations.
      if (newItems || modifiedItems) $.each(previous, function (selector, settings) {
        settings && settings.$element && settings.$element.unstick();
      });

      var $adminBar  = $('#navbar-bar')
        , topSpacing = $adminBar.height() || 0;

      // Initiate all navbars.
      $.each(initiated, function (selector, navbar) {

        // Grab DOM element.
        navbar.$element = navbar.$element || $(selector + ' .navbar').eq(0);

        var initialWidth = navbar.$element.width()
          , bodyMaxWidth = $body.width()
          , $toggle = navbar.$element.find('.navbar-toggle')
          , $collapse = navbar.$element.find('.navbar-collapse');

        // Save reference.
        navbar.topSpacing = topSpacing;

        // Initiate plugin.
        navbar.$element.sticky({
          topSpacing: topSpacing
        }).css({
          'max-width': initialWidth + 'px',
          'z-index': zIndex
        });

        zIndex -= 10;
        topSpacing += navbar.$element.outerHeight();

        // Save reference.
        navbar.offsetTop = topSpacing;

        $(window).resize(function () {
          if (bodyMaxWidth < (bodyMaxWidth = Math.max($body.width(), bodyMaxWidth))) {
            navbar.$element.css('max-width', navbar.$element.parent().width());
          }
        });

        // Handle fixed navbar collapsibles.
        if ($toggle.length && $collapse.length) {
          Drupal.Breakpoints.register('any', function () {
            var maxNavbarCollapseHeight = window.innerHeight - (navbar.offsetTop + 20);
            $collapse.css('max-height', !Drupal.Breakpoints.isCurrent('xs') ? maxNavbarCollapseHeight : 'none');
          });
        }
      });
    }
  }
};

/**
 * Handle z-index for navbars.
 */
Drupal.behaviors.ielaNavbarZIndex = {
  attach: function (context, settings) {
    var $navbars = $('.navbar')
      , zIndex = 100 + $navbars.length;

    $navbars.each(function () {
      var $navbar = $(this);  
      return $navbar.parent().is('.sticky-wrapper') ? null : $navbar.css('z-index', zIndex--);
    });
  }
};

/**
 * Handle mobile menu activation.
 */
Drupal.behaviors.ielaNavbarFloat = {
  attach: function (context, settings) {

    // Early return.
    if (!Drupal.Breakpoints) return;

    $(context).find('.navbar').each(function () {
      var componentSelectors = ['.menu.nav', '.navbar-brand']
        , $navbar = $(this)
        , $components = $navbar.findExclude(componentSelectors.join(', '), '.dropdown-mini-panel-menu')
        , responsive = false
        , collapsed = false
        , breakWidth = 99999;

      // Initial fake 'media'.
      $navbar.addClass('not-collapsed');
      $navbar.removeClass('is-collapsed');

      Drupal.ielaOnWidthChange(function () {
        setTimeout(checkFloating, 1);
      });

      /**
       * Check current floating state.
       */
      function checkFloating() {

        // Reset.
        $navbar.addClass('not-collapsed');
        $navbar.removeClass('is-collapsed');

        var breaking = hasFloatingBreak($components)
          , $lists = $components.filter('ul,ol');

        // If any of the items are lists, check break on them too.
        if (!breaking && $lists.length) breaking = hasFloatingBreak($lists.find('> li'));

        // Update breaking width.
        if (breaking) breakWidth = Math.max(window.innerWidth, breakWidth == 99999 ? 0 : breakWidth);

        // Update collapsed state.
        $navbar.toggleClass('not-collapsed', !(collapsed = breaking));
        $navbar.toggleClass('is-collapsed', collapsed);
      };
    });
  }
};

/**
 * Helper method to see sibling components have a floating break.
 */
function hasFloatingBreak($components) {
  var outsets = []
    , breaking = false;

  $components.each(function () {
    var $component = $(this)
      , componentOffset = $component.offset()
      , i = 0;

    // Find break.
    for (; i < outsets.length; i++) {
      if (outsets[i].top <= componentOffset.top) return !(breaking = true);
      if (outsets[i].left >= componentOffset.left) return !(breaking = true);
    }

    // Add offset list.
    outsets.push({
      top: componentOffset.top + $component.height(),
      left: componentOffset.left
    });
  });

  return breaking;
}

})(jQuery, Drupal, this, this.document);
