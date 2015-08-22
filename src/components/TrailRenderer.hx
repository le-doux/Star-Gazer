package components;
import pincushion.components.EditorComponent;
import luxe.Component;

import luxe.Vector;
import phoenix.geometry.Vertex;
import phoenix.geometry.*;
import phoenix.Batcher;
import luxe.Color;
import luxe.utils.Maths;
import luxe.Visual;

using pincushion.utilities.VectorExtender;

class TrailRenderer extends EditorComponent {

	var points : Array<Vector>;
	var trailGeometry : Geometry;

	public var startSize : Float = 10.0;
	var endSize : Float = 0.0;

	public var trailColor : Color = new Color(1,1,1);

	public var minPointDist = 0.1;

	public var arePointsCulledWithTime = true;
	var maxLength : Float = 300.0;
	var cullTime : Float = 1.0;

	override function init() {
		points = [pos.clone()];

		//the batcher shit is a hack
		trailGeometry = new Geometry({batcher: Main.main.starBatcher, primitive_type: PrimitiveType.triangles, depth: cast(entity, Visual).geometry.depth - 0.1});
	}

	override function update(dt : Float) {
		if (points[0].distance(pos) > minPointDist) {
			points.insert(0, pos.clone());		
			if (arePointsCulledWithTime) {
				//create a point, schedule time to remove a point
				Luxe.timer.schedule(cullTime, function() { 
					points.remove(points[points.length-1]); //remove oldest point
					updateGeometry(); 
				});
			} else {
				cullPoints();
			} 
			updateGeometry();
		}
	}

	override function onremoved() {
		Main.main.starBatcher.remove(trailGeometry);
	}

	function cullPoints() {
		var totalLength : Float = 0;
		var prevPoint = null;
		var count = 0;
		for (p in points) {

			if (prevPoint != null) {
				totalLength += Vector.Subtract(p, prevPoint).length;
			}

			if (totalLength > maxLength) {
				break;
			}

			prevPoint = p;
			count++;
		}
		points = points.slice(0,count);
	}

	function updateGeometry() {
		trailGeometry.vertices = []; //clear vertices

		var prevPoint = null;
		var count : Float = 0;

		var mustFillGap = false;
		var prevQ2 = new Vector(0,0);
		var prevQ3 = new Vector(0,0);

		for (p in points) {

			if (prevPoint != null) {
				//tangent
				var tangent = Vector.Subtract(p, prevPoint).normalized.tangent2D();

				//changing size of trail
				var size0 = Maths.lerp(startSize, endSize, (count-1) / points.length);
				var size1 = Maths.lerp(startSize, endSize, count / points.length);

				//quad points
				var q0 = Vector.Add(prevPoint, Vector.Multiply(tangent, size0));
				var q1 = Vector.Add(prevPoint, Vector.Multiply(tangent, -1 * size0));
				var q2 = Vector.Add(p, Vector.Multiply(tangent, size1));
				var q3 = Vector.Add(p, Vector.Multiply(tangent, -1 * size1));

				//tri 1
				trailGeometry.add(new Vertex(q0));
				trailGeometry.add(new Vertex(q1));
				trailGeometry.add(new Vertex(q2));

				//tri 2
				trailGeometry.add(new Vertex(q3));
				trailGeometry.add(new Vertex(q2));
				trailGeometry.add(new Vertex(q1));

				//fill gaps w/ tris
				if (mustFillGap) {
					trailGeometry.add(new Vertex(prevPoint.clone()));
					trailGeometry.add(new Vertex(prevQ2.clone()));
					trailGeometry.add(new Vertex(q0));

					trailGeometry.add(new Vertex(prevPoint.clone()));
					trailGeometry.add(new Vertex(prevQ3.clone()));
					trailGeometry.add(new Vertex(q1));
				}

				//save values
				prevQ2 = q2;
				prevQ3 = q3;
				mustFillGap = true;
			}

			prevPoint = p;
			count++;
		}

		//re-apply color
		trailGeometry.color = trailColor;
	}
}
