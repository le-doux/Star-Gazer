package components;

import pincushion.components.EditorComponent;
import pincushion.Pin;

import luxe.Input;
import luxe.tween.Actuate;

class StarGazerTitle extends EditorComponent {

	var pin : Pin;


	override function init() {
		pin = cast entity;

		cast(pin.get("AnimateStrokes")).animate(5);

	}

	override function onmousedown(e : MouseEvent) {
		if (Main.main.canGameBegin) {

			for (v in pin.visualChildren) {
				Actuate.tween(v.color, 5, {a : 0.0});
			}	
		}
	}

}