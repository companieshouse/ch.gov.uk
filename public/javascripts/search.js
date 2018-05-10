function gammaSearch(id) {
    $(id).autocomplete({
        delay: 75,
        source: function( request, response ) {
			var ajaxManager = $.manageAjax.create('squeue',{queue:true,cacheResponse:false});
            var postData1 = {
                query: {
                    text: {
                        _all: {
                            query: request.term
                            //operator: 'or',
                            //phrase_slop: 3
                        }
                    }
                }
            };
            // Good phrase searching - does not work effectively across fields
            // so officers are difficult to match. Really of use for documents
            var postData2 = {
                query: {
                    text_phrase: {
                        _all: {
                            query: request.term
                        }
                    }
                }
            };
            // Excellent 'complete as you type' phrase searching - does not
            // work effectively across fields so officers are difficult to
            // match. Really of use for doccuments
            var postData3 = {
                query: {
                    text_phrase_prefix: {
                        _all: {
                            query: request.term
                        }
                    }
                }
            };
            ajaxManager.add({
                url: 'http://127.0.0.1:9200/company/_search?pretty=true',
                type: "POST",
                dataType: "json",
                data: JSON.stringify(postData1),
                success: function( data ) {
                    response( $.map( data.hits.hits, function( item ) {
                            // Compile the data to be output in the match.
                            if (item._source.name.surname)
                            {
                                var name = item._source.name;
                                return { label: name.title + ' ' + name.first + ' ' + name.second + ' ' + name.surname,
                                         dob: item._source.dateofbirth,
                                         posttown: item._source.posttown,
                                         postcode: item._source.postcode,
                                         };
                                }
                            else
                            {
                                // Company
                                var address = item._source.address;
                                var status  = '['+item._source.status+']';
                                if( status == '[LIVE]' )
                                {
                                    status = '';
                                }
                                return { label: item._source.name, 
                                         cnumb: item._source.number,
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
//{
//    "took" : 1,
//    "timed_out" : false,
//    "_shards" : {
//        "total" : 5,
//        "successful" : 5,
//        "failed" : 0
//    },
//    "hits" : {
//        "total" : 1,
//        "max_score" : 2.252763,
//        "hits" : [ {
//            "_index" : "company",
//            "_type" : "names",
//            "_id" : "ZbIia6szSdSPDR8aM7C5kA",
//            "_score" : 2.252763,
//            "_source" : {
//                "number" : "00165899",
//                "name" : "BROADBENT DRIVES LIMITED"
//            }
//        } ]
//    }
//}
// ----
// ----
//                query: { text: { _all: request.term } }
// ----
// ----
//            var postData = {
//                query: {
//                    text: {
//                        _all: {
//                            query: request.term,
//                            operator: 'and',
//                            phrase_slop: 3
//                        }
//                    }
//                }
//            };
// ----
