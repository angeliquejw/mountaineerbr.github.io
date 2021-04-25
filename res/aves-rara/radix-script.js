/**
 * @file
 * JS for Radix.
 */
(function ($, Drupal, window, document, undefined) {

  // Show dropdown on hover.
  Drupal.behaviors.radix_dropdown = {
    attach: function(context, setting) {
      $('.dropdown > a.dropdown-toggle').once('radix-dropdown-toggle', function(){
        $(this).click(function(e) {
          e.preventDefault();
          var href = $(this).attr('href');
          if (href) {
            window.location.href = $(this).attr('href');
          }
        });
      });
    }
  }

  // Bootstrap tooltip.
  Drupal.behaviors.radix_tooltip = {
    attach: function(context, setting) {
      $("[data-toggle='tooltip']").once('radix-tooltip', function () {
        $(this).tooltip();
      });
    }
  }

  // Bootstrap popover.
  Drupal.behaviors.radix_popover = {
    attach: function(context, setting) {
      $("[data-toggle='popover']").once('radix-popover', function () {
        $(this).popover();
      });
    }
  }

  // Bootstrap tabs.
  Drupal.behaviors.radix_tab = {
    attach: function (context, settings) {
      $(context).find('.nav-tabs > li:first-child a[href*="#"]').tab('show');
      if (hash = window.location.hash) {
        $(context).find('.nav-tabs > li > a[href$=' + hash + ']').tab('show');
      }
    }
  };
})(jQuery, Drupal, this, this.document);
