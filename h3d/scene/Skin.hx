package h3d.scene;

class Joint extends Object {
	@:s public var skin : Skin;
	@:s public var index : Int;

	public function new(skin, j : h3d.anim.Skin.Joint ) {
		super(null);
		name = j.name;
		this.skin = skin;
		// fake parent
		this.parent = skin;
		this.index = j.index;
	}

	override function getObjectByName(name:String) {
		var sk = skin.getSkinData();
		var j = sk.namedJoints.get(name);
		if( j == null )
			return null;
		var cur = sk.allJoints[index];
		if( cur.index != index ) throw "assert";
		var jp = j.parent;
		while( jp != null ) {
			if( jp == cur ) {
				var jo = new Joint(skin, j);
				jo.parent = this;
				return jo;
			}
			jp = jp.parent;
		}
		return null;
	}

	@:access(h3d.scene.Skin)
	override function syncPos() {
		// check if one of our parents has changed
		// we don't have a posChanged flag since the Joint
		// is not actualy part of the hierarchy
		var p = parent;
		while( p != null ) {
			if( p.posChanged ) {
				// save the inverse absPos that was used to build the joints absPos
				if( skin.jointsAbsPosInv == null ) {
					skin.jointsAbsPosInv = new h3d.Matrix();
					skin.jointsAbsPosInv.zero();
				}
				if( skin.jointsAbsPosInv._44 == 0 )
					skin.jointsAbsPosInv.inverse3x4(parent.absPos);
				parent.syncPos();
				lastFrame = -1;
				break;
			}
			p = p.parent;
		}
		if( lastFrame != skin.lastFrame ) {
			lastFrame = skin.lastFrame;
			absPos.load(skin.currentAbsPose[index]);
			if( skin.jointsAbsPosInv != null && skin.jointsAbsPosInv._44 != 0 ) {
				absPos.multiply3x4(absPos, skin.jointsAbsPosInv);
				absPos.multiply3x4(absPos, parent.absPos);
			}
		}
	}
}

class Skin extends MultiMaterial {

	var skinData : h3d.anim.Skin;
	var currentRelPose : Array<h3d.Matrix>;
	var currentAbsPose : Array<h3d.Matrix>;
	var currentPalette : Array<h3d.Matrix>;
	var splitPalette : Array<Array<h3d.Matrix>>;
	var jointsUpdated : Bool;
	var jointsAbsPosInv : h3d.Matrix;
	var paletteChanged : Bool;
	var skinShader : h3d.shader.SkinBase;
	var jointsGraphics : Graphics;

	public var showJoints : Bool = false;

	public function new(s, ?mat, ?parent) {
		super(null, mat, parent);
		if( s != null )
			setSkinData(s);
	}

	override function clone( ?o : Object ) {
		var s = o == null ? new Skin(null,materials.copy()) : cast o;
		super.clone(s);
		s.setSkinData(skinData);
		s.currentRelPose = currentRelPose.copy(); // copy current pose
		return s;
	}

	override function getBoundsRec( b : h3d.col.Bounds ) {
		b = super.getBoundsRec(b);
		var tmp = primitive.getBounds().clone();
		var b0 = skinData.allJoints[0];
		// not sure if that's the good joint
		if( b0 != null && b0.parent == null ) {
			var mtmp = absPos.clone();
			var r = currentRelPose[b0.index];
			if( r != null )
				mtmp.multiply3x4(r, mtmp);
			else
				mtmp.multiply3x4(b0.defMat, mtmp);
			if( b0.transPos != null )
				mtmp.multiply3x4(b0.transPos, mtmp);
			tmp.transform(mtmp);
		} else
			tmp.transform(absPos);
		b.add(tmp);
		return b;
	}

	override function getObjectByName( name : String ) : h3d.scene.Object {
		// we can reference the object by both its model name and skin name
		if( skinData != null && skinData.name == name )
			return this;
		var o = super.getObjectByName(name);
		if( o != null ) return o;
		// create a fake object targeted at the bone, not persistant but matrixes are shared
		if( skinData != null ) {
			var j = skinData.namedJoints.get(name);
			if( j != null )
				return new Joint(this, j);
		}
		return null;
	}

	override function getLocalCollider() {
		throw "Not implemented";
		return null;
	}

	override function getGlobalCollider() {
		var col = cast(primitive.getCollider(), h3d.col.Collider.OptimizedCollider);
		cast(primitive, h3d.prim.HMDModel).loadSkin(skinData);
		return new h3d.col.SkinCollider(this, cast(col.b, h3d.col.PolygonBuffer));
	}

	override function calcAbsPos() {
		super.calcAbsPos();
		// if we update our absolute position, rebuild the matrixes
		jointsUpdated = true;
	}

	public function getSkinData() {
		return skinData;
	}

	public function setSkinData( s, shaderInit = true ) {
		skinData = s;
		jointsUpdated = true;
		primitive = s.primitive;
		if( shaderInit ) {
			var hasNormalMap = false;
			for( m in materials )
				if( m != null && m.normalMap != null ) {
					hasNormalMap = true;
					break;
				}
			skinShader = hasNormalMap ? new h3d.shader.SkinTangent() : skinData.bonesPerVertex==4 ? new h3d.shader.Skin4() : new h3d.shader.Skin();
			var maxBones = 0;
			if( skinData.splitJoints != null ) {
				for( s in skinData.splitJoints )
					if( s.joints.length > maxBones )
						maxBones = s.joints.length;
			} else
				maxBones = skinData.boundJoints.length;
			if( skinShader.MaxBones < maxBones )
				skinShader.MaxBones = maxBones;
			for( m in materials )
				if( m != null ) {
					if( m.normalMap != null )
						@:privateAccess m.mainPass.addShaderAtIndex(skinShader, m.mainPass.getShaderIndex(m.normalShader) + 1);
					else
						m.mainPass.addShader(skinShader);
					if( skinData.splitJoints != null ) m.mainPass.dynamicParameters = true;
				}
		}
		currentRelPose = [];
		currentAbsPose = [];
		currentPalette = [];
		paletteChanged = true;
		for( j in skinData.allJoints )
			currentAbsPose.push(h3d.Matrix.I());
		trace("BoundJoints:"+skinData.boundJoints.length);
		for( i in 0...skinData.boundJoints.length )
			currentPalette.push(h3d.Matrix.I());
		if( skinData.splitJoints != null ) {
			splitPalette = [];
			for( a in skinData.splitJoints )
				splitPalette.push([for( j in a.joints ) currentPalette[j.bindIndex]]);
		} else
			splitPalette = null;
	}

	override function sync( ctx : RenderContext ) {
		if( !ctx.visibleFlag && !alwaysSync )
			return;
		syncJoints();
	}

	@:noDebug
	function syncJoints() {
		if( !jointsUpdated ) return;
		for( j in skinData.allJoints ) {
			var sm = this.getAbsPos().clone();
			var id = j.index;
			var m = currentAbsPose[id];
			var r = currentRelPose[id];
			var bid = j.bindIndex;
			if( r == null ) r = j.defMat else if( j.retargetAnim ) { r._41 = j.defMat._41; r._42 = j.defMat._42; r._43 = j.defMat._43; }
			// if( j.parent == null )
			// 	m.multiply3x4inline(r, absPos);
			// else
			// 	m.multiply3x4inline(r, currentAbsPose[j.parent.index]);
			// if( bid >= 0 )
			// 	currentPalette[bid].multiply3x4inline(j.transPos, m);

			// r = r.clone();
			var t:h3d.Matrix = null;
			var res = new h3d.Matrix();
			if( j.parent == null ) {
				m.multiply(r, absPos);
				// m.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
				// m.rotate(1.57, 0, 0);
			} else
				m.multiply(r, currentAbsPose[j.parent.index]);
			if( bid >= 0 ) {
				//t = this.getScene().getObjectByName(j.name).getInvPos().clone();//j.parent == null ? absPos.clone() : currentAbsPose[j.parent.index].clone();
				// t.rotate(0.02, 0, 0);
				//t.invert();
				currentPalette[bid].multiply(j.transPos, m);
				
				switch(bid) {
					case 0: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
					case 1: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
					case 2: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
					case 3: res.loadValues( [1, 0, 0, 0, 0, 0.2484, -0.9685, 0, 0, 0.9686, 0.2484, 0, 0, -0.6894, -0.3118, 1] );
					case 4: res.loadValues( [1, 0, 0, 0, 0, 0.3205, -0.9471, 0, 0, 0.9472, 0.3205, 0, 0, -0.6638, -0.3978] );
					case 5: res.loadValues( [0.7416, -0.6672, 0.0692, 0, 0.0211, -0.0798, -0.9965, 0, 0.6706, 0.7405, -0.045, 0, -0.6976, -0.3866, 0.0103, 1] );
					case 6: res.loadValues( [0.7334, 0.6727, 0.0981, 0, 0.0921, 0.0447, -0.9946, 0, -0.6735, 0.7386, -0.0291, 0, 0.699, -0.3853, 0.008, 1] );
					case 7: res.loadValues( [0.7416, -0.6672, 0.0692, 0, 0.0211, -0.0798, -0.9965, 0, 0.6706, 0.7405, -0.045, 0, -0.6976, -0.3866, 0.0103, 1] );
					case 8: res.loadValues( [0.7334, 0.6727, 0.0981, 0, 0.0921, 0.0447, -0.9946, 0, -0.6735, 0.7386, -0.0291, 0, 0.699, -0.3853, 0.008, 1] );
					case 9: res.loadValues( [0.7416, -0.6672, 0.0692, 0, 0.0211, -0.0798, -0.9965, 0, 0.6706, 0.7405, -0.045, 0, -0.6976, -0.3866, 0.0103, 1] );
					case 10: res.loadValues( [0.7334, 0.6727, 0.0981, 0, 0.0921, 0.0447, -0.9946, 0, -0.6735, 0.7 -0.0291, 0, 0.699, -0.3853, 0.008, 1] );
					case 11: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
					case 12: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
					case 13: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
					case 14: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
					case 15: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
					case 16: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
					case 17: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
					case 18: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
					case 19: res.loadValues( [1, 0, 0, 0, 0, 0, -0.9999, 0, 0, 1, 0, 0, 0, -0.7249, -0.0319, 1] );
				}
				//res.rotate(1.57, 0, 0);

				// if (j.name=="Joint_4") {
				// 	res.loadValues([ -0.9999,0,0,0,0,0.9979,0.064,0,0,0.064,-0.9978,0,0,0.0665,0,1 ]);
				// 	currentPalette[bid].load(res);
				// }

			}
			if (j.name=="RootJoint0-N2") {
				trace("SyncJoints:id="+j.name+"("+j.index+") bid="+bid+" p="+(j.parent!=null ? ""+j.parent.index+"\n - pAb:"+OpenFLMain.mtos(currentAbsPose[j.parent.index]) : "-")+"\n - abs:"+OpenFLMain.mtos(currentAbsPose[id])+"\n - tra:"+OpenFLMain.mtos(j.transPos)+"\n - rel:"+OpenFLMain.mtos(currentRelPose[id])+"\n - m  :"+OpenFLMain.mtos(m)+"\n - BID:"+OpenFLMain.mtos(currentPalette[bid]));
				m.loadValues( [ 
					1.0345, 0.0005, 0.006, 0, 
					0, 1.0316, -0.0783, 0, 
					-0.0059, 0.0784, 1.0315, 0.686,
					0, 0, 0, 1 ] );
				// currentPalette[bid].loadValues( [
				// 	1.035, 0.00000584, 0, -0.004, 
				// 	-0.000005839, 1.035, -0.000001131, 1.052, 
				// 	0, 0.000001105, 1.035, 0.684, 
				// 	0, 0, 0, 0.5308] );
				trace("New:\n - m  :"+OpenFLMain.mtos(m)+"\n - BID:"+OpenFLMain.mtos(currentPalette[bid]));
			}
			// trace("syncJoints: id="+j.name+"("+j.index+") bid="+bid+" p="+(j.parent!=null ? ""+j.parent.index+"\n - pAb:"+OpenFLMain.mtos(currentAbsPose[j.parent.index]) : "-")+"\n - abs:"+OpenFLMain.mtos(currentAbsPose[id])+"\n - tra:"+OpenFLMain.mtos(j.transPos)+"\n - rel:"+OpenFLMain.mtos(currentRelPose[id])+"\n - m  :"+OpenFLMain.mtos(m)+"\n - BID:"+OpenFLMain.mtos(currentPalette[bid])+"\n - res:"+OpenFLMain.mtos(res));
			// trace("syncJoints: id="+j.name+"("+j.index+") bid="+bid+" p="+(j.parent!=null ? ""+j.parent.index+"\n - pAb:"+currentAbsPose[j.parent.index] : "-")+"\n - abs:"+currentAbsPose[id]+"\n - tra:"+j.transPos+"\n - rel:"+currentRelPose[id]+"\n - m  :"+m+"\n - BID:"+currentPalette[bid]+"\n - res:"+res);
		}
		// currentPalette[10]._11 *= 3;
		// currentPalette[1]._22 *= 15;
		// currentPalette[1]._22 *= 25;
		// currentPalette[1]._41 = 23.5;
		//trace("SyncJoints:"+currentPalette);
		skinShader.bonesMatrixes = currentPalette;
		if( jointsAbsPosInv != null ) jointsAbsPosInv._44 = 0; // mark as invalid
		jointsUpdated = false;
	}

	override function emit( ctx : RenderContext ) {
		if( splitPalette == null )
			super.emit(ctx);
		else {
			for( i in 0...splitPalette.length ) {
				var m = materials[skinData.splitJoints[i].material];
				if( m != null )
					ctx.emit(m, this, i);
			}
		}
		if( showJoints ) {
			if( jointsGraphics == null ) {
				jointsGraphics = new Graphics(this);
				jointsGraphics.material.mainPass.depth(false, Always);
				jointsGraphics.material.mainPass.setPassName( Std.is(jointsGraphics.material, h3d.mat.PbrMaterial) ? "overlay" : "additive");
			}
			var topParent : Object = this;
			while( topParent.parent != null )
				topParent = topParent.parent;
			jointsGraphics.follow = topParent;

			var g = jointsGraphics;
			g.clear();
			for( j in skinData.allJoints ) {
				var m = currentAbsPose[j.index];
				var mp = j.parent == null ? absPos : currentAbsPose[j.parent.index];
				if (j.parent==null) trace("Line("+j.name+"("+j.index+") Par="+(j.parent == null ? "null" : ""+j.parent.index)+"):"+mp._41+"/"+mp._42+"/"+mp._43+" -> "+m._41+"/"+m._42+"/"+m._43);
				g.lineStyle(3, j.parent == null ? 0xFF0000FF : 0xFFFFFF00, 1.);
				g.moveTo(mp._41, mp._42, mp._43);
				g.lineTo(m._41, m._42, m._43);
			}
		} else if( jointsGraphics != null ) {
			jointsGraphics.remove();
			jointsGraphics = null;
		}
	}

	override function draw( ctx : RenderContext ) {
		if( splitPalette == null ) {
			super.draw(ctx);
		} else {
			var i = ctx.drawPass.index;
			skinShader.bonesMatrixes = splitPalette[i];
			primitive.selectMaterial(i);
			ctx.uploadParams();
			primitive.render(ctx.engine);
		}
	}

	#if (hxbit && !macro && heaps_enable_serialize)
	override function customUnserialize(ctx:hxbit.Serializer) {
		super.customUnserialize(ctx);
		var prim = Std.instance(primitive, h3d.prim.HMDModel);
		if( prim == null ) throw "Cannot load skin primitive " + prim;
		jointsUpdated = true;
		skinShader = material.mainPass.getShader(h3d.shader.Skin);
		@:privateAccess {
			var lib = prim.lib;
			for( m in lib.header.models )
				if( lib.header.geometries[m.geometry] == prim.data ) {
					var skinData = lib.makeSkin(m.skin);
					skinData.primitive = prim;
					setSkinData(skinData, false);
					break;
				}
		}
	}
	#end


}