// Source: https://github.com/gdkraus/accessible-modal-window     Author:Greg Kraus

// jQuery formatted selector to search for focusable items
var focusableElementsString ="a[href], area[href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), button:not([disabled]), iframe, object, embed, *[tabindex], *[contenteditable]";

// store the item that has focus before opening the modal window
var focusedElementBeforeModal;

$(document).ready(function() {
	jQuery('#startModal').click(function(e) {showModal($('#modal'));});
	jQuery('#cancel').click(function(e) {hideModal();});
	jQuery('#cancelButton').click(function(e) {hideModal();});
	jQuery('#enter').click(function(e) {enterButtonModal();});
	jQuery('#modalCloseButton').click(function(e) {hideModal();});
	jQuery('#modalCloseButton').keydown(function(event){trapSpaceKey($(this),event,hideModal);})
	jQuery('#modal').keydown(function(event){trapTabKey($(this),event);})
	jQuery('#modal').keydown(function(event){trapEscapeKey($(this),event);})

	
	// WebKit shim
	// Screen readers for WebKit browsers, VoiceOver and ChromeVox, repeat the the aria-labelledby attribute each time the focus changes within the element that has the aria-labelledby attribute, which makes a very verbose experience. These screen readers only announce the aria-describedby attribute once when the element with that attribute receives focus. This changes the aria-labelledby attribute to an aria-describedby attribute
	if(usingWebKit()) {
//		jQuery('#modal').attr('aria-describedby',jQuery('#modal').attr('aria-labelledby'));
//		jQuery('#modal').removeAttr('aria-labelledby');
	}

});


function usingWebKit(){
	var ua = navigator.userAgent.toLowerCase(); 
	if (ua.indexOf('safari')!=-1){ 
		if(ua.indexOf('chrome')  > -1){
			return true; // chrome
		}else{
			return true; // safari
		}
	} else {
		return false;
	}
	
}

function trapSpaceKey(obj,evt,f) {
	// if space key pressed
	if ( evt.which == 32 ) {
		// fire the user passed event
		f();
		evt.preventDefault();
	}	
}

function trapEscapeKey(obj,evt) {

	// if escape pressed
	if ( evt.which == 27 ) {

		// get list of all children elements in given object
		var o = obj.find('*');

		// get list of focusable items
		var cancelElement;
		cancelElement = o.filter("#cancel")

		// close the modal window
		cancelElement.click();
		evt.preventDefault();
	}	

}

function trapTabKey(obj,evt) {
	
	// if tab or shift-tab pressed
	if ( evt.which == 9 ) {

		// get list of all children elements in given object
		var o = obj.find('*');

		// get list of focusable items
		var focusableItems;
		focusableItems = o.filter(focusableElementsString).filter(':visible')

		// get currently focused item
		var focusedItem;
		focusedItem = jQuery(':focus');

		// get the number of focusable items
		var numberOfFocusableItems;
		numberOfFocusableItems = focusableItems.length

		// get the index of the currently focused item
		var focusedItemIndex;
		focusedItemIndex = focusableItems.index(focusedItem);

		if (evt.shiftKey) {
			//back tab
			// if focused on first item and user preses back-tab, go to the last focusable item
			if(focusedItemIndex==0){
				focusableItems.get(numberOfFocusableItems-1).focus();
				//focusableItems.get(numberOfFocusableItems-1).select();
				evt.preventDefault();
			}
			
		} else {
			//forward tab
			// if focused on the last item and user preses tab, go to the first focusable item
			if(focusedItemIndex==numberOfFocusableItems-1){
				focusableItems.get(0).focus();
				//focusableItems.get(numberOfFocusableItems-1).select();
				evt.preventDefault();				
			}
		}
	}

}

function setInitialFocusModal(obj){
	// get list of all children elements in given object
	var o = obj.find('*');

	// set focus to first focusable item
	var focusableItems;
	focusableItems = o.filter(focusableElementsString).filter(':visible').first().focus();

}

function enterButtonModal(){
	// BEGIN logic for executing the Enter button action for the modal window
	alert('form submitted');
	// END logic for executing the Enter button action for the modal window
	hideModal();
}

function showModal(obj){
	jQuery('#mainPage').attr('aria-hidden','true'); // mark the main page as hidden
	jQuery('#modalOverlay').css('display','block'); // insert an overlay to prevent clicking and make a visual change to indicate the main apge is not available
	jQuery('#modal').css('display','block'); // make the modal window visible
	jQuery('#modal').attr('aria-hidden','false'); // mark the modal window as visible

	// save current focus
	focusedElementBeforeModal = jQuery(':focus');

	// get list of all children elements in given object
	var o = obj.find('*');

	// WebKit shim
	// if WebKit based browser, set the initial focus to the modal window itself instead of the first keyboard focusable item. This causes VoiceOver and ChromeVox to announce the aria-describedby attribute since they don't accurately announce the aria-labelled by attribute in this case.
	if(usingWebKit()){
		// set the focus to the modal window itself
		obj.focus();
	} else {
		// set the focus to the first keyboard focusable item
		o.filter(focusableElementsString).filter(':visible').first().focus();
	}
	
	
}

function hideModal(){
	jQuery('#modalOverlay').css('display','none'); // remove the overlay in order to make the main screen available again
	jQuery('#modal').css('display','none'); // hide the modal window
	jQuery('#modal').attr('aria-hidden','true'); // mark the modal window as hidden
	jQuery('#mainPage').attr('aria-hidden','false'); // mark the main page as visible

	// set focus back to element that had it before the modal was opened
	focusedElementBeforeModal.focus();
}