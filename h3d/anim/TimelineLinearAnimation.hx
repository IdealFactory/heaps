package h3d.anim;
import h3d.anim.Animation;
import h3d.anim.LinearAnimation;

class TimelineLinearFrame {
	public var tx : Float;
	public var ty : Float;
	public var tz : Float;
	public var qx : Float;
	public var qy : Float;
	public var qz : Float;
	public var qw : Float;
	public var sx : Float;
	public var sy : Float;
	public var sz : Float;
	public var t0x : Float;
	public var t0y : Float;
	public var t0z : Float;
	public var t0w : Float;
	public var t1x : Float;
	public var t1y : Float;
	public var t1z : Float;
	public var t1w : Float;
	public var w : Array<Float>;
	public var keyTime : Float;
	public function new() {
		w = [];
	}
	public function toMatrix() {
		var m = new h3d.Matrix();
		new h3d.Quat(qx, qy, qz, qw).toMatrix(m);
		m.prependScale(sx, sy, sz);
		m.translate(tx, ty, tz);
		return m;
	}
}

class TimelineLinearObject extends AnimatedObject {
	public var hasPosition : Bool = true;
	public var hasRotation : Bool;
	public var hasScale : Bool;
	public var hasWeights : Bool;
	public var frames : haxe.ds.Vector<TimelineLinearFrame>;
	public var alphas : haxe.ds.Vector<Float>;
	public var uvs : haxe.ds.Vector<Float>;
	public var propName:  String;
	public var propValues : haxe.ds.Vector<Float>;
	public var matrix : h3d.Matrix;
	public var tMat : h3d.Matrix;
	public var rMat : h3d.Matrix;
	public var sMat : h3d.Matrix;
	public var propCurrentValue : Float;
	public var currentFrame : Int = 0;
	override function clone() : AnimatedObject {
		var o = new TimelineLinearObject(objectName);
		o.hasPosition = hasPosition;
		o.hasRotation = hasRotation;
		o.hasScale = hasScale;
		o.hasWeights = hasWeights;
		o.frames = frames;
		o.alphas = alphas;
		o.uvs = uvs;
		o.propName = propName;
		o.propValues = propValues;
		return o;
	}
}

enum abstract Easing(String) {
	var Linear = "LINEAR";
	var Step = "STEP";
	var CubicSpline = "CUBICSPLINE";

	public inline function toString():String { return this; }
}

class TimelineLinearAnimation extends TimelineAnimation {

	public var easing:Easing; 

	var syncFrame : Float;

	public function new(name,frame,totalDuration,easing) {
		super(name,frame,totalDuration);
		this.easing = easing;
		syncFrame = -1;
	}

	public function addCurve( objName, frames, hasPos, hasRot, hasScale, hasWeights ) {
		var f = new TimelineLinearObject(objName);
		f.frames = frames;
		f.hasPosition = hasPos;
		f.hasRotation = hasRot;
		f.hasScale = hasScale;
		f.hasWeights = hasWeights;
		objects.push(f);
	}

	public function addAlphaCurve( objName, alphas ) {
		var f = new TimelineLinearObject(objName);
		f.alphas = alphas;
		objects.push(f);
	}

	public function addUVCurve( objName, uvs ) {
		var f = new TimelineLinearObject(objName);
		f.uvs = uvs;
		objects.push(f);
	}

	public function addPropCurve( objName, propName, values ) {
		var f = new TimelineLinearObject(objName);
		f.propName = propName;
		f.propValues = values;
		objects.push(f);
	}

	inline function getTargetObjects() : Array<TimelineLinearObject> {
		return cast objects;
	}

	override function clone(?a:Animation) {
		if( a == null )
			a = new TimelineLinearAnimation(name, frameCount, totalDuration, easing);
		super.clone(a);
		return a;
	}

	override function endFrame() {
		return loop ? frameCount : frameCount - 1;
	}

	public function mergeOrAddCurve( objName, frames:haxe.ds.Vector<TimelineLinearFrame>, hasPos, hasRot, hasScale, hasWeights ) {
		var merged = false;
		for (o in objects) {
			var tla:TimelineLinearObject = cast o;

			// Check object names match
			if (tla.objectName == objName) {
				// If the anim already has pos/rot/scale/weights - skip
				if ((tla.hasPosition && hasPos) || (tla.hasRotation && hasRot) || (tla.hasScale && hasScale) || (tla.hasWeights && hasWeights)) {
					break;
				}

				var frameMatch = true;
				// Check frame times are the same, if not break and add a new one
				if (frames.length != tla.frames.length ) 
					frameMatch = false;
				else 
					for (f in 0...frames.length) {
						var f1 = frames[f];
						var f2 = tla.frames[f];
						if (frames[f].keyTime != tla.frames[f].keyTime) {
							frameMatch = false;
							break;
						}
					}

				if (frameMatch) {
					for (f in 0...frames.length) {
						var tlaf:TimelineLinearFrame = cast frames[f];
						var objf:TimelineLinearFrame = cast tla.frames[f];
						if (hasPos) {
							tla.hasPosition = true;
							objf.tx = tlaf.tx;
							objf.ty = tlaf.ty;
							objf.tz = tlaf.tz;
						}
						if (hasRot) {
							tla.hasRotation = true;
							objf.qx = tlaf.qx;
							objf.qy = tlaf.qy;
							objf.qz = tlaf.qz;
							objf.qw = tlaf.qw;
						}
						if (hasScale) {
							tla.hasScale = true;
							objf.sx = tlaf.sx;
							objf.sy = tlaf.sy;
							objf.sz = tlaf.sz;
						}
						if (hasWeights) {
							tla.hasWeights = true;
							objf.w = tlaf.w;
						}
					}
					merged = true;
				}

			}
		}

		if (!merged)
			addCurve( objName, frames, hasPos, hasRot, hasScale, hasWeights );
	}

	#if !(dataOnly || macro)

	override function initInstance() {
		super.initInstance();
		var objs = getTargetObjects();
		for( a in objs ) {
			if( a.propValues != null ) {
				a.propCurrentValue = a.propValues[0];
				continue;
			}
			if( a.alphas != null && (a.targetObject == null || !a.targetObject.isMesh()) )
				throw a.objectName + " should be a mesh (for alpha animation)";
			if( a.uvs != null || a.alphas != null ) continue;
			a.matrix = new h3d.Matrix();
			a.matrix.identity();
			// store default position in our matrix unused parts
			if( a.targetSkin != null ) {
				var m2 = a.targetSkin.getSkinData().allJoints[a.targetJoint].defMat;
				a.matrix._14 = m2._41;
				a.matrix._24 = m2._42;
				a.matrix._34 = m2._43;
			}
		}
		// makes sure that all single frame anims are at the end so we can break early when isSync=true
		objs.sort(sortByFrameCountDesc);
	}

	function sortByFrameCountDesc( o1 : TimelineLinearObject, o2 : TimelineLinearObject ) {
		return (o2.frames == null ? 10 : o2.frames.length) - (o1.frames == null ? 10 : o1.frames.length);
	}

	inline function uvLerp( v1 : Float, v2 : Float, k : Float ) {
		v1 %= 1.;
		v2 %= 1.;
		if( v1 < v2 - 0.5 )
			v1 += 1;
		else if( v1 > v2 + 0.5 )
			v1 -= 1;
		return v1 * (1 - k) + v2 * k;
	}

	function cubicSpline() {

	}

	@:access(h3d.scene.Skin)
	@:noDebug
	override function sync( decompose = false ) {
		if( frame == syncFrame && !decompose )
			return;
		#if debug_timelineanim
		trace("TimelineLinearAnimation.sync: frame="+frame+" syncFrame="+syncFrame+" easing:"+easing);
		#end

		for( o in getTargetObjects() ) {

			if( o.targetObject == null && o.targetSkin == null || (o.frames==null || o.frames.length==0)) continue;
			
			if (restartAnim) o.currentFrame = 0;

			var frame1 = getTimeFrame( o );
			var frame2 = frame1+1;
			if (frame1==-1 && o.frames.length > 0) frame1 = 0; 
			if (frame2 > o.frames.length-1) frame2=frame1;
			var t = o.frames[frame2].keyTime - o.frames[frame1].keyTime;
			var k2:Float = 0;
			switch (easing) {
				case Linear, CubicSpline: k2 = t==0 ? o.frames[frame1].keyTime : (frame - o.frames[frame1].keyTime) / t;
				case Step: k2 = 0;
			}

			var k1:Float = 1 - k2;
			syncFrame = frame;
			if( decompose ) isSync = false;

			#if debug_timelineanim
			trace("Target"+(o.targetObject!=null ? "Object:"+o.targetObject.name : "Skin:"+o.targetSkin.name)+" fLen:"+o.frames.length+" f1="+frame1+" f2="+frame2+" t="+t+" k2="+k2+" k1="+k1+" syncFrame="+syncFrame+" keyTime1="+o.frames[frame1].keyTime+" keyTime2="+o.frames[frame2].keyTime);
			#end
			
			o.currentFrame = frame1;
			
			if( o.alphas != null ) {
				var mat = o.targetObject.toMesh().material;
				if( mat.blendMode == None ) mat.blendMode = Alpha;
				mat.color.w = o.alphas[frame1] * k1 + o.alphas[frame2] * k2;
				continue;
			}
			if( o.uvs != null ) {
				var mat = o.targetObject.toMesh().material;
				var s = mat.mainPass.getShader(h3d.shader.UVDelta);
				if( s == null ) {
					s = mat.mainPass.addShader(new h3d.shader.UVDelta());
					mat.texture.wrap = Repeat;
				}
				s.uvDelta.x = uvLerp(o.uvs[frame1 << 1],o.uvs[frame2 << 1],k2);
				s.uvDelta.y = uvLerp(o.uvs[(frame1 << 1) | 1],o.uvs[(frame2 << 1) | 1],k2);
				continue;
			}
			if( o.propValues != null ) {
				o.propCurrentValue = o.propValues[frame1] * k1 + o.propValues[frame2] * k2;
				continue;
			}

			var frame1 = frame1, frame2 = frame2;

			// if we have a single frame
			if( o.frames.length == 1 ) {
				if( isSync )
					break;
				frame1 = frame2 = 0;
			}

			var f1 = o.frames[frame1], f2 = o.frames[frame2];

			if (o.targetObject!=null) {
				if( o.hasScale ) {
					o.targetObject.scaleX = ilerp(f1.sx, k1, f2.sx, k2, f1.t0x, f1.t1x);
					o.targetObject.scaleY = ilerp(f1.sy, k1, f2.sy, k2, f1.t0y, f1.t1y);
					o.targetObject.scaleZ = ilerp(f1.sz, k1, f2.sz, k2, f1.t0z, f1.t1z);
					#if debug_timelineanim
					trace(" - scale: f1="+f1.sx+", "+f1.sy+", "+f1.sz+" f2="+f2.sx+", "+f2.sy+", "+f2.sz+" current="+o.targetObject.scaleX+", "+o.targetObject.scaleY+", "+o.targetObject.scaleY);
					#end
				} 
				if (o.hasRotation) {
					// qlerp nearest
					var dot = f1.qx * f2.qx + f1.qy * f2.qy + f1.qz * f2.qz + f1.qw * f2.qw;
					var q2 = dot < 0 ? -k2 : k2;
					var qx = ilerp(f1.qx, k1, f2.qx, q2, f1.t0x, f1.t1x);
					var qy = ilerp(f1.qy, k1, f2.qy, q2, f1.t0y, f1.t1y);
					var qz = ilerp(f1.qz, k1, f2.qz, q2, f1.t0z, f1.t1z);
					var qw = ilerp(f1.qw, k1, f2.qw, q2, f1.t0w, f1.t1w);
					// make sure the resulting quaternion is normalized
					var ql = 1 / Math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw);
					qx *= ql;
					qy *= ql;
					qz *= ql;
					qw *= ql;

					var q = new h3d.Quat( qx, qy, qz, qw );
					o.targetObject.setRotationQuat( q );
					#if debug_timelineanim
					trace(" - rotation: f1="+f1.qx+", "+f1.qy+", "+f1.qz+", "+f1.qw+" f2="+f2.qx+", "+f2.qy+", "+f2.qz+", "+f2.qw+" current="+q);
					#end
				}
				if (o.hasPosition) {
					o.targetObject.x = ilerp(f1.tx, k1, f2.tx, k2, f1.t0x, f1.t1x);
					o.targetObject.y = ilerp(f1.ty, k1, f2.ty, k2, f1.t0y, f1.t1y);
					o.targetObject.z = ilerp(f1.tz, k1, f2.tz, k2, f1.t0z, f1.t1z);
					#if debug_timelineanim
					trace(" - translation: f1="+f1.tx+", "+f1.ty+", "+f1.tz+" f2="+f2.tx+", "+f2.ty+", "+f2.tz+" current="+o.targetObject.x+", "+o.targetObject.y+", "+o.targetObject.z);
					#end
				}

				if (o.hasWeights) {
					updateWeightData( o.targetObject, f1, f2, k1, k2 );
				}
			} 
			if( o.targetSkin != null ) {

				var m = o.matrix;
				if( o.hasPosition ) {
					m._41 = f1.tx * k1 + f2.tx * k2;
					m._42 = f1.ty * k1 + f2.ty * k2;
					m._43 = f1.tz * k1 + f2.tz * k2;
				}

				if( o.hasRotation ) {
					// qlerp nearest
					var dot = f1.qx * f2.qx + f1.qy * f2.qy + f1.qz * f2.qz + f1.qw * f2.qw;
					var q2 = dot < 0 ? -k2 : k2;
					var qx:Float = f1.qx * k1 + f2.qx * q2;
					var qy:Float = f1.qy * k1 + f2.qy * q2;
					var qz:Float = f1.qz * k1 + f2.qz * q2;
					var qw:Float = f1.qw * k1 + f2.qw * q2;
					// make sure the resulting quaternion is normalized
					var ql:Float = 1 / Math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw);
					qx *= ql;
					qy *= ql;
					qz *= ql;
					qw *= ql;

					if( decompose ) {
						m._12 = qx;
						m._13 = qy;
						m._21 = qz;
						m._23 = qw;
						if( o.hasScale ) {
							m._11 = f1.sx * k1 + f2.sx * k2;
							m._22 = f1.sy * k1 + f2.sy * k2;
							m._33 = f1.sz * k1 + f2.sz * k2;
						} else {
							m._11 = 1;
							m._22 = 1;
							m._33 = 1;
						}
					} else {
						// quaternion to matrix
						var xx = qx * qx;
						var xy = qx * qy;
						var xz = qx * qz;
						var xw = qx * qw;
						var yy = qy * qy;
						var yz = qy * qz;
						var yw = qy * qw;
						var zz = qz * qz;
						var zw = qz * qw;
						m._11 = 1 - 2 * ( yy + zz );
						m._12 = 2 * ( xy + zw );
						m._13 = 2 * ( xz - yw );
						m._21 = 2 * ( xy - zw );
						m._22 = 1 - 2 * ( xx + zz );
						m._23 = 2 * ( yz + xw );
						m._31 = 2 * ( xz + yw );
						m._32 = 2 * ( yz - xw );
						m._33 = 1 - 2 * ( xx + yy );
						if( o.hasScale ) {
							var sx = f1.sx * k1 + f2.sx * k2;
							var sy = f1.sy * k1 + f2.sy * k2;
							var sz = f1.sz * k1 + f2.sz * k2;
							m._11 *= sx;
							m._12 *= sx;
							m._13 *= sx;
							m._21 *= sy;
							m._22 *= sy;
							m._23 *= sy;
							m._31 *= sz;
							m._32 *= sz;
							m._33 *= sz;
						}
					}

				} else {
					m._12 = 0;
					m._13 = 0;
					m._21 = 0;
					m._23 = decompose ? 1 : 0;

					if( o.hasScale ) {
						m._11 = f1.sx * k1 + f2.sx * k2;
						m._22 = f1.sy * k1 + f2.sy * k2;
						m._33 = f1.sz * k1 + f2.sz * k2;
					} else {
						m._11 = 1;
						m._22 = 1;
						m._33 = 1;
					}
				}
				o.targetSkin.currentRelPose[o.targetJoint] = m;
				o.targetSkin.jointsUpdated = true;
			} 
		}
		if( !decompose ) isSync = true;

		restartAnim = false;
	}

	public static inline function rightHandToLeft( m : h3d.Matrix ) {
		// if [x,y,z] is our original point and M the matrix
		// in right hand we have [x,y,z] * M = [x',y',z']
		// we need to ensure that left hand matrix convey the x axis flip,
		// in order to have [-x,y,z] * M = [-x',y',z']
		m._12 = -m._12;
		m._13 = -m._13;
		m._21 = -m._21;
		m._31 = -m._31;
		m._41 = -m._41;
	}
	
	// result[i] = ((2*tCub - 3*tSq + 1) * p0) + ((tCub - 2*tSq + t) * m0) + ((-2*tCub + 3*tSq) * p1) + ((tCub - tSq) * m1);
	// result[i] = ((2*tCub - 3*tSq + 1) * v0) + ((tCub - 2*tSq + t) * b) + ((-2*tCub + 3*tSq) * v1) + ((tCub - tSq) * a);
	inline function ilerp( v1:Float, k1:Float, v2:Float, k2:Float, m0:Float, m1:Float ) {
		if (easing==CubicSpline) {
			var t3 = k2*k2*k2;
			var t2 = k2*k2;
			var res = ((2*t3 - 3*t2 + 1) * v1) + ((t3 - 2*t2 + k2) * m0) + ((-2*t3 + 3*t2) * v2) + ((t3 - t2) * m1);
			#if debug_timelineanim
			trace(" -  cubicspline: t="+k2+" tIn="+m0+" v="+v1+" tOut="+m1+" res="+res);
			#end
			return res;
		} else 
			return v1 * k1 + v2 * k2;
	}

	@:access(h3d.scene.Object)
	function updateWeightData( o:h3d.scene.Object, f1:TimelineLinearFrame, f2:TimelineLinearFrame, k1:Float, k2:Float ) {
		if (Std.is(o, h3d.scene.Mesh)) {
			var m:h3d.scene.Mesh = cast o;
			@:privateAccess for (s in m.material.mainPass.shaders) {
				if (Std.is(s, h3d.shader.GLTFMorphTarget)) {
					cast(s, h3d.shader.GLTFMorphTarget).weight = f1.w[0] * k1 + f2.w[0] * k2;
				}
				if (Std.is(s, h3d.shader.GLTFMorphTarget2)) {
					cast(s, h3d.shader.GLTFMorphTarget2).weight = f1.w[1] * k1 + f2.w[1] * k2;
				}
			}
		}
		if (o.children!= null) {
			for (c in o.children) {
				updateWeightData( c, f1, f2, k1, k2 );
			}
		}
	}
	#end

}