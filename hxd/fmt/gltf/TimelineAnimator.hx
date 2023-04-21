package hxd.fmt.gltf;

import StringTools;
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

	public function playAnimation(name:String, loop:Bool = false) {
		for (animationObject in anims) {
			if(StringTools.contains(animationObject.anim.name, name)) {

				animationObject.anim.loop = loop;
				animationObject.obj.stopAnimation(true);
				animationObject.obj.playAnimation(animationObject.anim);
			}
		}
	}

	public function playAnimationByIndex(index:Int, loop:Bool = false) {
		if(index >= 0 && index < anims.length && anims[index] != null) {
			anims[index].anim.loop = loop;
			anims[index].obj.playAnimation(anims[index].anim);
		}
	}

    public function playAllAnimations(loop:Bool = false) {
        for (a in anims) {
			a.anim.loop = loop;
			a.obj.alwaysSync = true;
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

    public function stopAllAnimations() {
        for (a in anims) {
            a.obj.stopAnimation(true);
        }
    }

	public function getAnimationsLength():Int {
		return anims.length;
	}

	public function getAnimationsNames():Array<String> {
		var result = [];
		for (anim in anims) {
			result.push(anim.anim.name);
			result.push(anim.obj.name);
		}
		return result;
	}

    function contains( o, a ) {
        for (anim in anims) {
            if (anim.obj == o && anim.anim == a) return true;
        }
        return false;
    }
}