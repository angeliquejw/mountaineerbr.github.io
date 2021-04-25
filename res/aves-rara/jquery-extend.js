/**
 * @file
 * jQuery improvements.
 */

;(function ($, Drupal, window, document, undefined) {

  /**
   * Find elements, but exclude the one's deeper then the mask.
   */
  $.fn.findExclude = function(selector, mask){
    return this.find(selector).not(this.find(mask).find(selector))
  };

  /**
   * Get closes CSS attribute value.
   */
  $.fn.closestCss = function (attr, ignore, fallback) {
    if (typeof ignore == 'undefined') ignore = [];

    var element = this
      , value;

    while (!(value = getOwnValue(element)) && !element.is('body')) {
      element = element.parent();
    }

    return value || fallback || null;

    /**
     * Gets a true own value or false in return.
     */
    function getOwnValue(element) {
      var value = element.css(attr);
      return ignore.indexOf(value) == -1 ? value : false;
    }
  };

})(jQuery, Drupal, this, this.document);
