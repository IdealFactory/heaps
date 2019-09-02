package hxd.fmt.gltf;

import hxd.fmt.gltf.Data;
import hxd.FloatBuffer;
import hxd.IndexBuffer;
import haxe.io.Bytes;

class Geometry {
	
	public var l (default, null) : BaseLibrary;
	public var root (default, null) : MeshPrimitive;

	var intCache:Map<String, IndexBuffer>;
	var floatCache:Map<String, FloatBuffer>;

	public function new ( l : BaseLibrary, root : MeshPrimitive ) {
		this.l = l;
		this.root = root;

		intCache = new Map<String, IndexBuffer>();
		floatCache = new Map<String, FloatBuffer>();
	}

	public function getIndices() {
		trace("getIndices-------------------");
		var accId = root.indices;
		if (accId == null) { trace(" - getIndices returning null"); return null; }

		if (intCache.exists( "INDEX" )) return intCache[ "INDEX" ];

		return GltfTools.getIndexBuffer( "INDEX", l, accId );
	}

	public function getVertices() {
		trace("getVertices------------------");
		var accId:Null<Int> = root.attributes.get( "POSITION" );
		if (accId == null) { trace(" - getVertices returning null"); return null; }

		if (floatCache.exists( "POSITION" )) return floatCache[ "POSITION" ];

		return GltfTools.getFloatBuffer( "POSITION", l, accId );
	}

	public function getNormals() {
		trace("getNormals------------------");
		var accId:Null<Int> = root.attributes.get( "NORMAL" );
		if (accId == null) { trace(" - getNormals returning null"); return null; }

		if (floatCache.exists( "NORMAL" )) return floatCache[ "NORMAL" ];

		return GltfTools.getFloatBuffer( "NORMAL", l, accId );
	}

	public function getTangents() {
		trace("getTangents------------------");
		var accId:Null<Int> = root.attributes.get( "TANGENT" );
		if (accId == null) { trace(" - getTangets returning null"); return null; }

		if (floatCache.exists( "TANGENT" )) return floatCache[ "TANGENT" ];

		return GltfTools.getFloatBuffer( "TANGENT", l, accId );
	}

	public function getUVs() {
		trace("GetUVs-----------------------");
		var accId:Null<Int> = root.attributes.get( "TEXCOORD_0" );
		if (accId == null) { trace(" - getUVs returning null"); return null; }

		if (floatCache.exists( "TEXCOORD_0" )) return floatCache[ "TEXCOORD_0" ];

		return GltfTools.getFloatBuffer( "TEXCOORD_0", l, accId );
	}

	public function getUV2s() {
		trace("GetUV2s-----------------------");
		var accId:Null<Int> = root.attributes.get( "TEXCOORD_1" );
		if (accId == null) { trace(" - getUV2s returning null"); return null; }

		if (floatCache.exists( "TEXCOORD_1" )) return floatCache[ "TEXCOORD_1" ];

		return GltfTools.getFloatBuffer( "TEXCOORD_1", l, accId );
	}

}