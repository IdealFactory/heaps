package hxd.fmt.gltf;

import hxd.fmt.gltf.Data;
import hxd.BytesBuffer;
import hxd.FloatBuffer;
import hxd.IndexBuffer;
import haxe.io.Bytes;

class Geometry {
	
	public var l (default, null) : BaseLibrary;
	public var root (default, null) : MeshPrimitive;

	var bytesCache:Map<String, BytesBuffer>;
	var intCache:Map<String, IndexBuffer>;
	var floatCache:Map<String, FloatBuffer>;

	public function new ( l : BaseLibrary, root : MeshPrimitive ) {
		this.l = l;
		this.root = root;

		bytesCache = new Map<String, BytesBuffer>();
		intCache = new Map<String, IndexBuffer>();
		floatCache = new Map<String, FloatBuffer>();
	}

	public function getIndices() {
		var accId = root.indices;
		if (accId == null) return null;
		if (intCache.exists( "INDEX" )) return intCache[ "INDEX" ];
		return intCache[ "INDEX" ] = GltfTools.getIndexBuffer( "INDEX", l, accId );
	}

	public function getVertices( accNode = -1 ) {
		var accId:Null<Int> = accNode==-1 ? root.attributes.get( "POSITION" ) : accNode;
		if (accId == null) return null;
		if (floatCache.exists( "POSITION" )) return floatCache[ "POSITION" ];
		return floatCache[ "POSITION" ] = GltfTools.getFloatBuffer( "POSITION", l, accId );
	}

	public function getNormals( accNode = -1 ) {
		var accId:Null<Int> = accNode==-1 ? root.attributes.get( "NORMAL" ) : accNode;
		if (accId == null) return null;
		if (floatCache.exists( "NORMAL" )) return floatCache[ "NORMAL" ];
		return floatCache[ "NORMAL" ] = GltfTools.getFloatBuffer( "NORMAL", l, accId );
	}

	public function getTangents( accNode = -1 ) {
		var accId:Null<Int> = accNode==-1 ? root.attributes.get( "TANGENT" ) : accNode;
		if (accId == null) return null;
		if (floatCache.exists( "TANGENT" )) return floatCache[ "TANGENT" ];
		return floatCache[ "TANGENT" ] = GltfTools.getFloatBuffer( "TANGENT", l, accId );
	}

	public function getUVs() {
		var accId:Null<Int> = root.attributes.get( "TEXCOORD_0" );
		if (accId == null) return null;
		if (floatCache.exists( "TEXCOORD_0" )) return floatCache[ "TEXCOORD_0" ];
		return floatCache[ "TEXCOORD_0" ] = GltfTools.getFloatBuffer( "TEXCOORD_0", l, accId );
	}

	public function getUV2s() {
		var accId:Null<Int> = root.attributes.get( "TEXCOORD_1" );
		if (accId == null) return null;
		if (floatCache.exists( "TEXCOORD_1" )) return floatCache[ "TEXCOORD_1" ];
		return floatCache[ "TEXCOORD_1" ] = GltfTools.getFloatBuffer( "TEXCOORD_1", l, accId );
	}

	public function getJoints() {
		var accId:Null<Int> = root.attributes.get( "JOINTS_0" );
		if (accId == null) return null;
		if (bytesCache.exists( "JOINTS_0" )) return bytesCache[ "JOINTS_0" ];
		return bytesCache["JOINTS_0"] = GltfTools.getBytesBuffer( "JOINTS_0", l, accId );
	}

	public function getJointsFloat() {
		var accId:Null<Int> = root.attributes.get( "JOINTS_0" );
		if (accId == null) return null;
		if (floatCache.exists( "JOINTS_0" )) return floatCache[ "JOINTS_0" ];
		return floatCache["JOINTS_0"] = GltfTools.getFloatBuffer( "JOINTS_0", l, accId );
	}

	public function getWeights() {
		var accId:Null<Int> = root.attributes.get( "WEIGHTS_0" );
		if (accId == null) return null;
		if (floatCache.exists( "WEIGHTS_0" )) return floatCache[ "WEIGHTS_0" ];
		return floatCache[ "WEIGHTS_0" ] = GltfTools.getFloatBuffer( "WEIGHTS_0", l, accId );
	}

	public function getTargetData() {
		if (root.targets==null) return [];

		trace("Getting Targets: count="+root.targets.length);
		var targets = [];
		for (t in root.targets) {
			var p = getVertices( t.POSITION );
			var n = getNormals( t.NORMAL );
			var t = getTangents( t.TANGENT );
			targets.push( [ p, n, t ]);
		}
		return targets;
	}

}