$(function() {
    $( "#company" ).autocomplete({
        source: function( request, response ) {
            var wildcard = { "name": "*"+request.term+"*" };
            var postData = {
                "query": { "wildcard": wildcard },
                "facets" : {
                  "tags" : {
                    "terms" : {
                        "field" : "tags",
                        "size"  : "10"
                    }
                  }
                }
            };
            $.ajax({
                url: "http://chrispc:9200/articles-terms-facet/_search?pretty=true",
                type: "POST",
                dataType: "json",
                data: JSON.stringify(postData),
                success: function( data ) {
                    response( $.map( data.hits.hits, function( item ) {
                        return {
                            label: item.fields.name,
                            id: item.fields._id
                        }
                    }));
                }
            });
        },
        minLength: 2,
        select: function( event, ui ) {
            $("#company_id").val(ui.item.id);
        },
        open: function() {
            $( this ).removeClass( "ui-corner-all" ).addClass( "ui-corner-top" );
        },
        close: function() {
            $( this ).removeClass( "ui-corner-top" ).addClass( "ui-corner-all" );
        }
    })
});
