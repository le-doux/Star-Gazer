import pincushion.Pincushion;

import components.PointAtStars;
import components.AnimateStrokes;
import components.StarGazerTitle;
import components.TrailRenderer;

import luxe.Input;
import luxe.Color;
import luxe.tween.Actuate;
import luxe.Visual;
import luxe.Vector;
import luxe.utils.Maths;
import luxe.utils.Random;
import phoenix.Batcher;
import luxe.Camera;

using pincushion.utilities.VectorExtender;

class Main extends Pincushion {

    public static var main : Main;

    public var canGameBegin = true;
    public var hasGameBegun = false;

    var stars = [];
    public var starBatcher : Batcher;
    var starCam : Camera;

    var skyColor : ColorHSL;
    var isSkyChanging = false;

    var rand : Random;

    public var curShootingStar = null;

    override function ready() {
        this.isReleaseBuild = true;
        this.startScene = "stargazing";

        super.ready();

        main = this;
    }

    override function on_start_game(e : Dynamic) {

        Luxe.snow.window.title = "Star Gazer";

        skyColor = ( makeColor(76, 76, 128) ).toColorHSL();

        Luxe.renderer.clear_color = skyColor.toColor();
        Luxe.camera.minimum_zoom = 0.001;

        starCam = new Camera({name:"starCam", scene: Luxe.scene});
        starCam.size = Luxe.screen.size;
        starCam.size_mode = SizeMode.contain;
        starBatcher = Luxe.renderer.create_batcher({name: "starBatcher", layer: -10, camera: starCam.view});

        rand = new Random(1234.2342);

    }

    function makeColor(r : Float, g : Float, b : Float) : Color {
        return new Color(r / 255.0, g / 255.0, b / 255.0);
    }

    override function onmousedown(e : MouseEvent) {
        super.onmousedown(e);

        if (canGameBegin) {
            createStars();
            canGameBegin = false;
        }

        if (hasGameBegun && curShootingStar != null) {

            if (e.pos.distance(curShootingStar.pos) < 20) {
                Luxe.events.fire("touch_star");
                
                Actuate.tween(Luxe.camera, 4, {zoom : Luxe.camera.zoom * 0.5}).delay(2);

                Actuate.stop(curShootingStar);
                curShootingStar.destroy();
                curShootingStar = null;

                //create explosion
                var explosion = new Visual({
                    pos : e.pos
                });
                explosion.geometry = Luxe.draw.circle({
                    r : 10,
                    color : new Color(1, 1, 1),
                    batcher : starBatcher
                });
                Actuate.tween(explosion.color, 2, {a: 0}, false);
                Actuate.tween(explosion.scale, 2, {x: 6, y: 6}, false)
                            .ease(luxe.tween.easing.Elastic.easeOut)
                                .onComplete(function() {explosion.destroy();});
                
                //Luxe.timer.schedule(rand.float(2, 10), function() { shootingStar(); });
            }
            
        }
    }

    override function update(dt : Float) {
        super.update(dt);

        if (isSkyChanging) {
            Luxe.renderer.clear_color = (skyColor.toColor());
        }

    }

    override function onwindowresized(e) {
        starCam.size = Luxe.screen.size; 
    }

    function createStars() {
        //create stars  
        var starMinSize = 1;
        var starMaxSize = 2;
        var starMinPulse = 0.5;
        var starMaxPulse = 4.0;
        var starMinPulseTime = 0.5;
        var starMaxPulseTime = 2.0;
        var starRange = 1000;

        for (i in 0 ... 500) {
            var star = new Visual({
                pos : Vector.Add( new Vector(500, 500), new Vector( rand.float(-starRange, starRange), rand.float(-starRange, starRange) ) )
            });
            star.geometry = Luxe.draw.circle({
                r : rand.float(starMinSize, starMaxSize),
                color : new Color(1, 1, 1),
                batcher : starBatcher
            });
            star.scale.x = 0.0;
            star.scale.y = 0.0;

            var pulseVal = rand.float(starMinPulse, starMaxPulse);

            Actuate.tween(star.scale, 1, {x: 1.0, y: 1.0}).delay(rand.float(7, 18)).onComplete(function() {
                    Actuate.tween(star.scale, rand.float(starMinPulseTime, starMaxPulseTime), {x: pulseVal, y:pulseVal}).repeat().reflect();
                });
        }

        isSkyChanging = true;
        Actuate.tween(skyColor, 20, {l: 0.0}).onComplete(function() { isSkyChanging = false; startGame(); });
    }

    function startGame() {
        hasGameBegun = true;

        Luxe.timer.schedule(rand.float(2, 10), function() { shootingStar(); });
    }

    function shootingStar() {
        //create star
        var star = new Visual({
            pos : new Vector( rand.float(0, Luxe.screen.size.x), rand.float(0, Luxe.screen.size.y) )
        });
        star.geometry = Luxe.draw.circle({
            r : 10,
            color : new Color(1, 1, 1, 0.0),
            batcher : starBatcher
        });

        //animate star
        star.scale.x = 0;
        star.scale.y = 0;

        Actuate.tween(star.scale, 1.0, {x: 1, y: 1}, false);
        Actuate.tween(star.color, 1.0, {a: 1.0}, false);

        Actuate.tween(star.scale, 2.0, {x: 0, y: 0}, false).delay(3);
        Actuate.tween(star.color, 1.0, {a: 0.0}, false).delay(4);

        //move star
        Actuate.tween(star.pos, 5, {x: star.pos.x + rand.float(-300, -600), y: star.pos.y + rand.float(60, 150)}, false)
            .onComplete(function() {
                star.destroy();
                curShootingStar = null;
                Luxe.timer.schedule(rand.float(2, 10), function() { shootingStar(); });
            });

        //create trail
        var trail = new TrailRenderer({name: "trail"});
        star.add(trail);

        //animate trail
        trail.trailColor.a = 0;
        trail.startSize = 0;

        Actuate.tween(trail, 1.0, {startSize: 8}, false);
        Actuate.tween(trail.trailColor, 1.0, {a: 1.0}, false);

        Actuate.tween(trail, 2.0, {startSize: 0}, false).delay(3);
        Actuate.tween(trail.trailColor, 1.0, {a: 0.0}, false).delay(4);

        //set current shooting star
        curShootingStar = star;
    }

} //Main
