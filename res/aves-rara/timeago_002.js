/**
 * @file
 * Timeago adjustments.
 */

;(function ($, Drupal, window, document, undefined) {

/**
 * Override default timeago strings.
 * @type {Object}
 */
Drupal.behaviors.timeago = {
  attach: function (context) {
    delete Drupal.settings.timeago.strings;
    $.extend($.timeago.settings, Drupal.settings.timeago);
    $('abbr.timeago, span.timeago, time.timeago', context).timeago();
  }
};

})(jQuery, Drupal, this, this.document);
