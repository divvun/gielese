// $(document).bind("mobileinit", function () {
//     $.mobile.ajaxEnabled = false;
//     $.mobile.linkBindingEnabled = false;
//     $.mobile.hashListeningEnabled = false;
//     $.mobile.pushStateEnabled = false;
// });
$(document).bind("mobileinit", function () {
    $.mobile.ajaxEnabled = false;
    $.mobile.linkBindingEnabled = false;
    $.mobile.hashListeningEnabled = false;
    $.mobile.pushStateEnabled = false;

    // was hoping these things would prevent a 1px jump in page size, but nope
    // $.support.touchOverflow = false;
    // $.mobile.touchOverflowEnabled = false;

    $(document).ready(function () {
        // Remove page from DOM when it's being replaced
        $('div[data-role="page"]').live('pagehide', function (event, ui) {
            $(event.currentTarget).remove();
        });
    });
});
