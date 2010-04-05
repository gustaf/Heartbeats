// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
jQuery.ajaxSetup({
    "beforeSend": function (xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
    });

$(document).ready(function (){
    $("a.like_link").live("click", function() {
      $.post($(this).attr("href"), null, null, "script");
      return false;
      });

    $("a.unlike_link").live("click", function() {
      $.ajax({
        type:"delete",
        url:$(this).attr("href"),
        data:null,
        success:null,
        dataType:"script"
        });
      return false;
      });

    $("div.more/a").click(function() {
      $("div.hidden_playlist", $(this).parent()).slideToggle();
      if($("a", this).html() == 'less') {
        $("a", this).html('more');
        $("span", $(this)).html('&raquo;');
      } else {
        $("a", this).html('less');
        $("span", $(this)).html('&laquo;');
      }
      });
    });

function register_likes() {

}
