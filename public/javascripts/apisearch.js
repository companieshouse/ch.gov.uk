function gammaSearch(id) {
    var apiurl = $(id).data("api-url");
    $(id).autocomplete({
        delay: 75,
        source: function( request, response ) {
			var ajaxManager = $.manageAjax.create('squeue',{queue:true,cacheResponse:false});
            ajaxManager.add({
                url: apiurl+'/search?q='+request.term,
                type: "GET",
                dataType: "json",
                success: function( data ) {
                    response( $.map( data.results, function( item ) {
                            // Compile the data to be output in the match.
                            if (item.name.surname)
                            {
                                var name = item.name;
                                return { label: name.title + ' ' + name.forename + ' ' + name.othername + ' ' + name.surname,
                                         dob: item.dateofbirth,
                                         posttown: item.posttown,
                                         postcode: item.postcode
                                };
                            }
                            else
                            {
                                // Company
                                var address = item.address;
                                var status  = '['+item.status+']';
                                if( status == '[LIVE]' )
                                {
                                    status = '';
                                }
                                return { label: item.name, 
                                         cnumb: item.number,
                                         status: status,
                                         postcode: address.premises + ' ' + address.street + ' ' + address.area + ' '+ address.posttown + ' ' + address.postcode };
                            }
                    }));
                }
            });
        },
        minLength: 4,
        select: function( event, ui ) {
            $("#search").val(ui.item._id);
        }
    }).data("autocomplete")._renderItem = function( ul, item ) {
        var tmp = $("<div>").setTemplate($("#templateHolder").html() );
        tmp.processTemplate(item);
        return $("<li></li>").data("item.autocomplete", item)
                       .append($(tmp).html())
                       .appendTo(ul);
    };
};
