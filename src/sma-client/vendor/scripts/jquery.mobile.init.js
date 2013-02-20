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
    $.mobile.pushStateEnabled = true;

    $(document).ready(function () {
        // Remove page from DOM when it's being replaced
        $('div[data-role="page"]').live('pagehide', function (event, ui) {
            $(event.currentTarget).remove();
        });
    });
});
