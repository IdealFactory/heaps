package h3d.scene;

@:access(h3d.scene.Skin)
class IKBone {

    public var skin:h3d.scene.Skin;
    public var bone1:h3d.anim.Skin.Joint;
    public var bone2:h3d.anim.Skin.Joint;
    public var transform:h3d.Matrix;
    public var initial:h3d.Vector = new h3d.Vector();
    public var bone1Pos:h3d.Vector = new h3d.Vector();
    public var bone2Pos:h3d.Vector = new h3d.Vector();
    public var target:h3d.Vector = new h3d.Vector();

    // public var maxAngle = new h3d.Vector();
    // public var minAngle = new h3d.Vector();


    public var maxAngle:Float = 0;
    public var maxReach:Float = 0;
    var bone1Length:Float = 0;
    var bone2Length:Float = 0;


    public function new( j:h3d.anim.Skin.Joint, s:h3d.scene.Skin ) {
        skin = s;

        bone2 = j;
        bone1 = j.parent;
        transform = h3d.Matrix.I();
        initial = bone2Pos = getJointAbsPos(j);

        if (bone1==null) return;
        bone1Pos = getJointAbsPos(bone1);
        bone2Length = bone2Pos.distance(bone1Pos);
        if (bone1.parent != null) {
            var bone0Pos = getJointAbsPos( bone1.parent );
            bone1Length = bone1Pos.distance(bone0Pos);
        }
        trace("BONE: Pos="+initial+" B2->B1="+bone2Length+" B1->B0="+bone1Length);
    }

    var maxIterations:Int = 5;

    function buildChain() {

    }

    public function sync() {
        if (bone1==null) return;

        var m = bone2.transPos.clone();
		m.multiply(m, transform);
		m.invert();
		if (bone2.parent!=null) {
			var parentTransform:Matrix = getTransform( skin, bone2.parent );
			parentTransform.invert();
			m.multiply(m, parentTransform);
		}
		skin.currentRelPose[bone2.index] = m;
		skin.jointsUpdated = true;

        // // Magic calcs
        // var bonePos:h3d.Vector = new h3d.Vector();

        // var a = bone1Length;
        // var b = bone2Length;

        // var c = bone2Pos.distance( target );

        // if (maxReach > 0) {
        //     c = Math.min(maxReach, c);
        // }

        // var acosa = (b * b + c * c - a * a) / (2 * b * c);
        // var acosb = (c * c + a * a - b * b) / (2 * c * a);

        // if (acosa > 1) {
        //     acosa = 1;
        // }

        // if (acosb > 1) {
        //     acosb = 1;
        // }

        // if (acosa < -1) {
        //     acosa = -1;
        // }

        // if (acosb < -1) {
        //     acosb = -1;
        // }

        // var angA = Math.acos(acosa);
        // var angB = Math.acos(acosb);

        // var angC = -angA - angB;

        // trace("Sync: b="+bone2.name+" a="+a+" b="+b+" c="+c+" angA="+angA+" angB="+angB+" angC="+angC);
    }

    // private function setMaxAngle(ang:Float) {
    //     if (ang < 0) {
    //         ang = 0;
    //     }

    //     if (ang > Math.PI) {
    //         ang = Math.PI;
    //     }

    //     maxAngle = ang;

    //     var a = bone1Length;
    //     var b = bone2Length;

    //     maxReach = Math.sqrt(a * a + b * b - 2 * a * b * Math.cos(ang));
    // }

    function getTransform(mesh:h3d.scene.Skin, j:h3d.anim.Skin.Joint):Matrix {
		var m = j.defMat.clone();
		if (j.parent != null) {
			m.multiply(m, getTransform(mesh, j.parent));
		}
		return m;
	}

    function getJointAbsPos(j:h3d.anim.Skin.Joint):h3d.Vector {
        var m = skin.currentAbsPose[j.index];
        if (m==null) return null;
		return new h3d.Vector(m._41, m._42, m._43);
    }

    public static function hasBone(j:h3d.anim.Skin.Joint, skin:h3d.scene.Skin) {
        return skin.currentAbsPose[j.index]!=null;
    }

    inline function r(v:Float) return Std.int((v * 10000) + 0.5) / 10000;
	function mtos(m:h3d.Matrix, preF:String = "") return m==null ? "--NULL--" : (preF==null ? "" : preF+": ")+r(m._11)+","+r(m._12)+","+r(m._13)+","+r(m._14)+","+r(m._21)+","+r(m._22)+","+r(m._23)+","+r(m._24)+","+r(m._31)+","+r(m._32)+","+r(m._33)+","+r(m._34)+","+r(m._41)+","+r(m._42)+","+r(m._43)+","+r(m._44);
}
