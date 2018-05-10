 
 
     $('#hidden-address').hide();
     $('#bilingual-current').hide();
     $('#address-complete').hide();

        $('.expander').click( function () {
                      $('#hidden-address').toggle("slow");
                      $('.expander').hide();
        });

       $('#bilingual-pending').click( function () {
                              $('#address-current').hide();
                              $('#address-complete').show();
                              $('#bilingual-pending').hide();
                              $('#bilingual-current').show();
       });

    try{
       var postcodeFieldValue = document.getElementById("address-postcode").value;
    }catch(err){}

       if(postcodeFieldValue != ''){
                      $('#hidden-address').toggle("slow");
                      $('.expander').hide();
                      }

