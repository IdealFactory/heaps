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

    public function addAnimtion( o, a ) {

        if (!contains( o, a ))
            anims.push( {obj:o, anim:a} );

        @:privateAccess if (a.totalDuration > globalDuration) {
            globalDuration = a.totalDuration;
            @:privateAccess for (anim in anims) anim.anim.totalDuration = globalDuration;
            trace("Updating all anims ("+anims.length+") with globaDuration="+globalDuration);
        }
    }

    public function playAnimation() {
        for (a in anims) {
            a.obj.playAnimation( a.anim );
        }
    }

    function contains( o, a ) {
        for (anim in anims) {
            if (anim.obj == o && anim.anim == a) return true;
        }
        return false;
    }
}