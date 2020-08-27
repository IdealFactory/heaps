package hxd.fmt.gltf;

import hxd.fmt.gltf.Data;
import hxd.FloatBuffer;
import hxd.IndexBuffer;
import haxe.io.Bytes;

class Geometry {
	
	public var l (default, null) : BaseLibrary;
	public var root (default, null) : MeshPrimitive;
	public var hasTangentBuffer:Bool = false;

	var intCache:Map<String, IndexBuffer>;
	var floatCache:Map<String, FloatBuffer>;
	var hasDraco:Bool = false;
	var needsDraco:Bool = false;
	var dracoLoaded:Bool = false;

	public function new ( l : BaseLibrary, root : MeshPrimitive, hasDraco:Bool = false, needsDraco:Bool = false ) {
		intCache = new Map<String, IndexBuffer>();
		floatCache = new Map<String, FloatBuffer>();

		this.l = l;
		this.root = root;
		this.hasDraco = hasDraco;
		this.needsDraco = needsDraco;

		checkDraco();

		var accId:Null<Int> = root.attributes.get( "TANGENT" );
		if (accId != null) hasTangentBuffer = true;
	}


	public function checkDraco() {
		if (dracoLoaded) return;
		if (needsDraco) {
			GltfTools.decodeDracoBuffer( l, root, intCache, floatCache );
			dracoLoaded = true;
		}
	}

	public function getIndices() {
		var accId = root.indices;
		if (accId == null) return null;
		if (intCache.exists( "INDEX" )) return intCache[ "INDEX" ];
		return GltfTools.getIndexBuffer( "INDEX", l, accId );
	}

	public function getVertices() {
		var accId:Null<Int> = root.attributes.get( "POSITION" );
		if (accId == null) return null;
		if (floatCache.exists( "POSITION" )) return floatCache[ "POSITION" ];
		return GltfTools.getFloatBuffer( "POSITION", l, accId );
	}

	public function getNormals() {
		var accId:Null<Int> = root.attributes.get( "NORMAL" );
		if (accId == null) return null;
		if (floatCache.exists( "NORMAL" )) return floatCache[ "NORMAL" ];
		return GltfTools.getFloatBuffer( "NORMAL", l, accId );
	}

	public function getTangents() {
		var accId:Null<Int> = root.attributes.get( "TANGENT" );
		if (accId == null) return null;
		if (floatCache.exists( "TANGENT" )) return floatCache[ "TANGENT" ];
		return GltfTools.getFloatBuffer( "TANGENT", l, accId );
	}

	public function getUVs() {
		var accId:Null<Int> = root.attributes.get( "TEXCOORD_0" );
		if (accId == null) return null;
		if (floatCache.exists( "TEXCOORD_0" )) return floatCache[ "TEXCOORD_0" ];
		return GltfTools.getFloatBuffer( "TEXCOORD_0", l, accId );
	}

	public function getUV2s() {
		var accId:Null<Int> = root.attributes.get( "TEXCOORD_1" );
		if (accId == null) return null;
		if (floatCache.exists( "TEXCOORD_1" )) return floatCache[ "TEXCOORD_1" ];
		return GltfTools.getFloatBuffer( "TEXCOORD_1", l, accId );
	}

}