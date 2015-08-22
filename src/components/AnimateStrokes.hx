package components;

import luxe.Vector;
import luxe.tween.Actuate;

import pincushion.components.EditorComponent;
import pincushion.Pin;
import pincushion.Polystroke;

using pincushion.utilities.VectorExtender;

class AnimateStrokes extends EditorComponent {
	var pin : Pin;
	var animationDelta (default, set) : Float;

	var strokes : Array<Polystroke> = [];
	var strokeLengths = [];
	var strokeData : Array<Array<Vector>> = [];
	var totalStrokeLength = 0.0;
	
	override function init() {
		pin = cast entity;

		for (v in pin.visualChildren) {
			if (Std.is(v, Polystroke)) {
				var s : Polystroke = cast v;
				var strokeLen = 0.0;

				for (i in 1 ... s.points.length) {
					var p0 = s.points[i-1];
					var p1 = s.points[i];

					var dist = p0.distance(p1);

					strokeLen += dist;
				}

				strokeLengths.push(strokeLen);
				totalStrokeLength += strokeLen;

				strokeData.push(s.points.copy());

				strokes.push(s);
			}
		}

		//animate(10);
	}

	public function animate(time : Float) {
		animationDelta = 0.0;
		return Actuate.tween(this, time, {animationDelta : 1.0});
	}

	function set_animationDelta(d : Float) : Float { //d is betwen 0 and 1

		animationDelta = d;

		var curLen = totalStrokeLength * d;

		for (i in 0 ... strokes.length) {
			if (curLen <= 0) { //this stroke is invisible
				strokes[i].visible = false;
			}
			else if (curLen >= strokeLengths[i]) { //this stroke is completely visible
				strokes[i].visible = true; //I may need more than this at some point

				if (strokes[i].points != strokeData[i]) { //.length < strokeData[i].length) {
					strokes[i].points = strokeData[i];
					strokes[i].generateMesh();
				}
			}
			else { //this stroke is in the middle of being revealed

				strokes[i].visible = true;

				var partialLen = 0.0;
				var isLastPointDone = false;

				var partialPoints = [];
				partialPoints.push(strokeData[i][0]);
				for (j in 1 ... strokeData[i].length) {

					//this feel messy as fuck
					
					var d = strokeData[i][j-1].distance(strokeData[i][j]);
					partialLen += d;

					if (partialLen < curLen) {
						partialPoints.push(strokeData[i][j]);
					}
					else if (!isLastPointDone) {
						var vToNextP = Vector.Subtract(strokeData[i][j], strokeData[i][j-1]).normalized;
						vToNextP.multiplyScalar(curLen - partialLen + d);
						var p = Vector.Add(strokeData[i][j-1], vToNextP);
						partialPoints.push(p);

						isLastPointDone = true;
					}
				}

				strokes[i].points = partialPoints;
				strokes[i].generateMesh();
			}

			curLen -= strokeLengths[i];
		}

		return animationDelta;
	}
}