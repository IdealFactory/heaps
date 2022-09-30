package hxd.fmt.gltf;

import haxe.Timer;

typedef ObjectAnimation = {
    var obj:h3d.scene.Object;
    var anim:h3d.anim.TimelineAnimation;
}

class TimelineAnimator {

    var anims:Array<ObjectAnimation>;
    var globalDuration:Float;

    public function new() {
        globalDuration = 0;
        anims = [];
    }

    public function addAnimation( o, a ) {
        if (!contains( o, a ))
            anims.push( {obj:o, anim:a} );

        @:privateAccess if (a.totalDuration > globalDuration) {
            globalDuration = a.totalDuration;
            @:privateAccess for (anim in anims) anim.anim.totalDuration = globalDuration;
        }
    }

    public function playAnimation() {
        for (a in anims) {
            playObjAnimation( a.obj, a.anim );
        }
    }

    function playObjAnimation( o:h3d.scene.Object, a:h3d.anim.TimelineAnimation ) {

        o.playAnimation( a );
        if (o.numChildren > 0) {
            for (cI in 0...o.numChildren) {
                var c = o.getChildAt( cI );
                    playObjAnimation( c, a );
            }
        }

    }

    function contains( o, a ) {
        for (anim in anims) {
            if (anim.obj == o && anim.anim == a) return true;
        }
        return false;
    }
}