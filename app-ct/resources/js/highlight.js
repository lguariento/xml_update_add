$(document).ready(function(){
   /*http://stackoverflow.com/questions/16090487/find-a-string-of-text-in-an-element-and-wrap-some-span-tags-round-it*/
   var fetched_url_param = decodeURIComponent($.urlParam('searchexpr'));
     console.log(fetched_url_param);
     $('#transcribed_text').html(function(_, html) {
       var re = new RegExp(fetched_url_param, "g");
       return  html.replace(re, '<span style="background-color: yellow;">'+fetched_url_param+'</span>')
     });
 });