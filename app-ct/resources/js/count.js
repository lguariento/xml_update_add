        $( document ).ready(function() {

            var hits = ($('td.KWIC').children('p').length);
            if (hits == 1){
                $("#hitcount").text(hits+" Hit ");
            }
            else {
                $("#hitcount").text(hits+" Hits ");
            }
            $("#searchexpr").text(decodeURIComponent($.urlParam("searchexpr")));
        });