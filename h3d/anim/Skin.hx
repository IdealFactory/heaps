package h3d.anim;

class Joint {

	public var index : Int;
	public var name : String;
	public var bindIndex : Int;
	public var splitIndex : Int;
	public var defMat : h3d.Matrix; // the default bone matrix
	public var transPos : h3d.Matrix; // inverse pose matrix
	public var parent : Joint;
	public var subs : Array<Joint>;
	/**
		When animated, we will use the default bind pose translation instead of the animated translation,
		enabling retargeting on a skeleton with different proportions
	**/
	public var retargetAnim : Bool;

	public function new() {
		bindIndex = -1;
		splitIndex = -1;
		subs = [];
	}

}

private class Permut {
	public var joints : Array<Joint>;
	public var triangles : Array<Int>;
	public var material : Int;
	public var indexedJoints : Array<Joint>;
	public function new() {
	}
}

private class Influence {
	public var j : Joint;
	public var w : Float;
	public function new(j, w) {
		this.j = j;
		this.w = w;
	}
}

class Skin {

	public var name : String;
	public var vertexCount(default, null) : Int;
	public var bonesPerVertex(default,null) : Int;
	public var vertexJoints : haxe.ds.Vector<Int>;
	public var vertexWeights : haxe.ds.Vector<Float>;
	public var rootJoints(default,null) : Array<Joint>;
	public var namedJoints(default,null) : Map<String,Joint>;
	public var allJoints(default,null) : Array<Joint>;
	public var boundJoints(default, null) : Array<Joint>;
	#if !(dataOnly || macro)
	public var primitive : h3d.prim.Primitive;
	#end

	// spliting
	public var splitJoints(default, null) : Array<{ material : Int, joints : Array<Joint> }>;
	public var triangleGroups : haxe.ds.Vector<Int>;

	var envelop : Array<Array<Influence>>;

	public function new( name, vertexCount, bonesPerVertex ) {
		this.name = name;
		this.vertexCount = vertexCount;
		this.bonesPerVertex = bonesPerVertex;
		if( vertexCount > 0 ) {
			vertexJoints = new haxe.ds.Vector(vertexCount * bonesPerVertex);
			vertexWeights = new haxe.ds.Vector(vertexCount * bonesPerVertex);
			envelop = [];
		}
		trace("Skin(new):"+name+" vC="+vertexCount+" bpv="+bonesPerVertex);
	}

	public function setJoints( joints : Array<Joint>, roots : Array<Joint> ) {
		trace("Skin.setJoints: joints:"+joints.length+" roots="+roots.length);
		rootJoints = roots;
		allJoints = joints;
		namedJoints = new Map();
		for( j in joints )
			if( j.name != null )
				namedJoints.set(j.name, j);
	}

	public inline function addInfluence( vid : Int, j : Joint, w : Float ) {
		trace("Skin.addInfluence: vid:"+vid+" j="+j.name+"("+j.index+") w="+w);
		var il = envelop[vid];
		if( il == null )
			il = envelop[vid] = [];
		il.push(new Influence(j,w));
	}

	function sortInfluences( i1 : Influence, i2 : Influence ) {
		return i2.w > i1.w ? 1 : -1;
	}

	public inline function isSplit() {
		return splitJoints != null;
	}

	public function initWeights() {
		boundJoints = [];
		var pos = 0;
		for( i in 0...vertexCount ) {
			var il = envelop[i];
			if( il == null ) il = [];
			haxe.ds.ArraySort.sort(il,sortInfluences);
			if( il.length > bonesPerVertex )
				il = il.slice(0, bonesPerVertex);
			var tw = 0.;
			for( i in il )
				tw += i.w;
			tw = 1 / tw;
			for( i in 0...bonesPerVertex ) {
				var i = il[i];
				if( i == null ) {
					vertexJoints[pos] = 0;
					vertexWeights[pos] = 0;
				} else {
					if( i.j.bindIndex == -1 ) {
						i.j.bindIndex = boundJoints.length;
						boundJoints.push(i.j);
						trace("JointBind:"+i.j.name+"("+i.j.index+") bInd="+i.j.bindIndex);
					}
					vertexJoints[pos] = i.j.bindIndex;
					vertexWeights[pos] = i.w * tw;
				}
				pos++;
			}
		}
		var oldBJ = boundJoints.copy();
		//Joint10-N12(12) Joint11-N13(13) Joint17-N19(21) Joint14-N16(17) Joint18-N20(22) Joint5-N7(6) RootJoint0-N2(0) Joint9-N11(11) Joint1-N3(1) Joint15-N17(18) Joint16-N18(19) Joint12-N14(14) Joint13-N15(15) Joint6-N8(7) Joint2-N4(2) Joint7-N9(8) Joint8-N10(9) Joint3-N5(3) Joint4-N6(4) 
		// boundJoints = [ allJoints[2], allJoints[6], allJoints[3], allJoints[5], allJoints[4], allJoints[11], allJoints[0], allJoints[1], allJoints[12], allJoints[7], allJoints[9], allJoints[8], allJoints[10], allJoints[13], allJoints[14], allJoints[15], allJoints[17], allJoints[16], allJoints[18] ];
		// boundJoints = [12, 13, 21, 17, 22, 6, 0, 11, 1, 18, 19, 14, 15, 7, 2, 8, 9, 3, 4];
		trace("initWeights:");
		var out = " - Joints:";
		for (i in 0...vertexJoints.length) out+=vertexJoints[i]+" ";
		trace(out);
		out = " - Weights:";
		for (i in 0...vertexWeights.length) out+=vertexWeights[i]+" ";
		trace(out);
		out = " - OLD-Bound:";
		for (i in 0...oldBJ.length) out+=oldBJ[i].index+" ";
		trace(out);
		out = " - Bound:";
		for (i in 0...boundJoints.length) out+=boundJoints[i].name+"("+boundJoints[i].index+") ";
		trace(out);
		envelop = null;
	}

	function sortByBindIndex(j1:Joint, j2:Joint) {
		return j1.bindIndex - j2.bindIndex;
	}

	function isSub( a : Array<Joint>, b : Array<Joint> ) {
		var j = 0;
		var max = b.length;
		for( e in a ) {
			while( e != b[j++] ) {
				if( j >= max ) return false;
				continue;
			}
		}
		return true;
	}

	function merge( permuts : Array<Permut> ) {
		for( p1 in permuts )
			for( p2 in permuts )
				if( p1 != p2 && p1.material == p2.material && isSub(p1.joints, p2.joints) ) {
					for( t in p1.triangles )
						p2.triangles.push(t);
					permuts.remove(p1);
					return true;
				}
		return false;
	}

	function jointsDiff( p1 : Permut, p2 : Permut ) {
		var diff = 0;
		var i = 0, j = 0;
		var imax = p1.joints.length, jmax = p2.joints.length;
		while( i < imax && j < jmax ) {
			var j1 = p1.joints[i];
			var j2 = p2.joints[j];
			if( j1 == j2 ) {
				i++;
				j++;
			} else {
				diff++;
				if( j1.bindIndex < j2.bindIndex )
					i++;
				else
					j++;
			}
		}
		return diff + (imax - i) + (jmax - j);
	}

	public function split( maxBones : Int, index : Array<Int>, triangleMaterials : Null<Array<Int>> ) {
		if( isSplit() )
			return true;
		if( boundJoints.length <= maxBones )
			return false;

		splitJoints = [];
		triangleGroups = new haxe.ds.Vector(Std.int(index.length/3));

		var permuts = new Array<Permut>();

		// build unique permutations

		for( tri in 0...Std.int(index.length / 3) ) {
			var iid = tri * 3;
			var mid = triangleMaterials == null ? 0 : triangleMaterials[tri];
			var jl = [];
			// get all joints for this triangle
			for( i in 0...3 ) {
				var vid = index[iid + i];
				for( b in 0...bonesPerVertex ) {
					var bidx = vid * bonesPerVertex + b;
					if( vertexWeights[bidx] == 0 ) continue;
					var j = boundJoints[vertexJoints[bidx]];
					if( j.splitIndex != iid ) {
						j.splitIndex = iid;
						jl.push(j);
					}
				}
			}
			jl.sort(sortByBindIndex);
			// look for another permutation
			for( p2 in permuts )
				if( p2.material == mid && isSub(jl, p2.joints) ) {
					p2.triangles.push(tri);
					jl = null;
					break;
				}
			if( jl == null ) continue;

			for( p2 in permuts )
				if( p2.material == mid && isSub(p2.joints, jl) ) {
					p2.joints = jl;
					p2.triangles.push(tri);
					jl = null;
					break;
				}

			if( jl == null ) continue;

			var pr = new Permut();
			pr.joints = jl;
			pr.triangles = [tri];
			pr.material = mid;
			permuts.push(pr);
		}


		// merge permutations when they share almost the same bones

		while( true ) {

			while( merge(permuts) ) {
			}

			// heuristic : look for a good match to merge permutations
			var minDif = 100000, minTot = 100000, minP1 : Permut = null, minP2 : Permut = null;
			for( i in 0...permuts.length ) {
				var p1 = permuts[i];
				if( p1.joints.length == maxBones ) continue;
				for( j in i + 1...permuts.length ) {
					var p2 = permuts[j];
					if( p2.joints.length == maxBones || p1.material != p2.material ) continue;
					var count = jointsDiff(p1, p2);
					var tot = count + ((p1.joints.length + p2.joints.length - count) >> 1);
					if( tot > maxBones || tot > minTot || (tot == minTot && count > minDif) ) continue;
					minDif = count;
					minTot = tot;
					minP1 = p1;
					minP2 = p2;
				}
			}

			if( minP1 == null ) break;

			// merge p1 & p2
			var p1 = minP1, p2 = minP2;
			for( j in p1.joints ) {
				p2.joints.remove(j);
				p2.joints.push(j);
			}
			p2.joints.sort(sortByBindIndex);
			for( t in p1.triangles )
				p2.triangles.push(t);
			permuts.remove(p1);

		}

		// store our vertex permutations
		for( i in 0...permuts.length )
			for( tri in permuts[i].triangles )
				triangleGroups[tri] = i;

		// assign split indexes to joints
		var jointsPermuts = [];
		for( j in boundJoints ) {
			var pl = [];
			for( p in permuts )
				if( p.joints.indexOf(j) >= 0 )
					pl.push(p);
			jointsPermuts.push( { j : j, pl : pl } );
		}
		jointsPermuts.sort(function(j1, j2) return j2.pl.length - j1.pl.length);

		for( p in permuts )
			p.indexedJoints = [];

		for( j in jointsPermuts ) {
			j.j.splitIndex = -1;
			for( id in 0...maxBones ) {
				var ok = true;
				for( p in j.pl )
					if( p.indexedJoints[id] != null ) {
						ok = false;
						break;
					}
				if( ok ) {
					j.j.splitIndex = id;
					for( p in j.pl )
						p.indexedJoints[id] = j.j;
					break;
				}
			}
			// this means we have to track the number of free joints
			// in our heuristic to prevent them from reaching such case
			if( j.j.splitIndex < 0 )
				throw "Failed to assign index while spliting skin";
		}

		// rebuild joints list (and fill holes)
		splitJoints = [];
		for( p in permuts ) {
			var jl = [];
			for( i in 0...p.indexedJoints.length ) {
				var j = p.indexedJoints[i];
				if( j == null ) j = boundJoints[0];
				jl.push(j);
			}
			splitJoints.push( { material : p.material, joints : jl } );
		}

		// rebind
		for( i in 0...vertexJoints.length )
			vertexJoints[i] = boundJoints[vertexJoints[i]].splitIndex;

		return true;
	}


}