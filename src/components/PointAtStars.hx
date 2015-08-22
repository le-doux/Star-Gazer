package components;

import pincushion.components.EditorComponent;
import pincushion.Pin;

import luxe.Input;
import luxe.tween.Actuate;

class PointAtStars extends EditorComponent {
	
	var pin : Pin;
	
	override function init() {
		pin = cast entity;

		Luxe.events.listen("touch_star", on_touch_star);
	}

	function on_touch_star( e: Dynamic ) {

		pin.animate("animation0", 1).onComplete(
				function() { 
					pin.animate("animation0", 2).reverse().delay(0.5); 
				});
		
	}
}