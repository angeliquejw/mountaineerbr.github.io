/**
 * @file
 * Panels IPE customization.
 */

;(function ($, Drupal, window, document, undefined) {

Drupal.behaviors.ielaPanelsVariantName = {
  attach: function (context, settings) {

    // Don't bother applying dump.
    if (!settings.ielaPanels || !settings.ielaPanels.variantName) return;

    // Parse context.
    var $context = $(context)
      , variantName = settings.ielaPanels.variantName;

    $context.find('.panels-ipe-control .panels-ipe-pseudobutton-container a').each(function () {
      var $button = $(this);
      $button.text($button.text().replace('this', '"' + variantName + '"'));
    });

    $context.find('#panels-ipe-edit-control-form #panels-ipe-save').each(function () {
      var $button = $(this);
      $button.attr('value', $button.attr('value') + ' "' + variantName + '"');
    });

    $context.find('.panels-choose-layout').closest('.modal-content').find('#modal-title').each(function () {
      var $title = $(this);
      $title.text(Drupal.t('Change layout for "@variant"', {
        '@variant': variantName
      }));
    });
  }
};

})(jQuery, Drupal, this, this.document);