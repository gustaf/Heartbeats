// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function (){
    $("div.more/a").click(function() {
      $("div.hidden_playlist", $(this).parent()).slideToggle();
      if($("a", this).html() == 'less') {
        $("a", this).html('more');
        $("span", $(this)).html('&raquo;');
      } else {
        $("a", this).html('less');
        $("span", $(this)).html('&laquo;');
      }
      //$("a", this).toggle(function() {$(this).html('less');}, function() {$(this).html('more');});
      });
    });
