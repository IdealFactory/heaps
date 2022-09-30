package hxd.fmt.gltf;

import hxd.fmt.gltf.Data;
import hxd.BytesBuffer;
import hxd.FloatBuffer;
import hxd.IndexBuffer;
import haxe.io.Bytes;

class Geometry {
	
	public var l (default, null) : BaseLibrary;
	public var root (default, null) : MeshPrimitive;
	public var hasTangentBuffer:Bool = false;

	var bytesCache:Map<String, BytesBuffer>;
	var intCache:Map<String, IndexBuffer>;
	var floatCache:Map<String, FloatBuffer>;
	var hasDraco:Bool = false;
	var needsDraco:Bool = false;
	var dracoLoaded:Bool = false;

	var idx:IndexBuffer;
	var norms:FloatBuffer;
	var tangents:FloatBuffer;
	var uvs:FloatBuffer;
	var uv2s:FloatBuffer;

	public function new ( l : BaseLibrary, root : MeshPrimitive, hasDraco:Bool = false, needsDraco:Bool = false ) {
		bytesCache = new Map<String, BytesBuffer>();
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
		if (accId == null) return buildIndexBuffer();
		if (intCache.exists( "INDEX" )) return intCache[ "INDEX" ];
		return intCache[ "INDEX" ] = GltfTools.getIndexBuffer( "INDEX", l, accId );
	}

	public function getVertices( accNode = -1 ) {
		var accId:Null<Int> = accNode==-1 ? root.attributes.get( "POSITION" ) : accNode;
		if (accId == null) return null;
		if (floatCache.exists( "POSITION"+accNode )) return floatCache[ "POSITION"+accNode ];
		return floatCache[ "POSITION"+accNode ] = GltfTools.getFloatBuffer( "POSITION", l, accId );
	}

	public function getNormals( accNode = -1 ) {
		var accId:Null<Int> = accNode==-1 ? root.attributes.get( "NORMAL" ) : accNode;
		if (accId == null) return buildNormalBuffer();
		if (floatCache.exists( "NORMAL"+accNode )) return floatCache[ "NORMAL"+accNode ];
		return floatCache[ "NORMAL"+accNode ] = GltfTools.getFloatBuffer( "NORMAL", l, accId );
	}

	public function getTangents( accNode = -1 ) {
		var accId:Null<Int> = accNode==-1 ? root.attributes.get( "TANGENT" ) : accNode;
		if (accId == null) return null;
		if (floatCache.exists( "TANGENT"+accNode )) return floatCache[ "TANGENT"+accNode ];
		return floatCache[ "TANGENT"+accNode ] = GltfTools.getFloatBuffer( "TANGENT", l, accId );
	}

	public function getUVs() {
		var accId:Null<Int> = root.attributes.get( "TEXCOORD_0" );
		if (accId == null) return buildUVBuffer();
		if (floatCache.exists( "TEXCOORD_0" )) return floatCache[ "TEXCOORD_0" ];
		return floatCache[ "TEXCOORD_0" ] = GltfTools.getFloatBuffer( "TEXCOORD_0", l, accId );
	}

	public function getUV2s() {
		var accId:Null<Int> = root.attributes.get( "TEXCOORD_1" );
		if (accId == null) return buildUV2Buffer();
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

	public function buildIndexBuffer() {
		if (idx != null) return idx;
		var len = Std.int(getVertices().length / 3);
		idx = new IndexBuffer();
		var v = 0;
		for (i in 0...len) {
			idx.push( v++ );
		}
		#if debug_gltf
		trace("Setting up sequential IndexBuffer\n - IndexBuffer len="+idx.length);
		#end
		return idx;
	}

	public function buildNormalBuffer() {
		if (norms != null) return norms;
		var len = Std.int(getVertices().length / 3);
		norms = new hxd.FloatBuffer();
		var v = 0;
		for (i in 0...len) {
			norms.push( 0. );
			norms.push( 1. );
			norms.push( 0. );
		}
		#if debug_gltf
		trace("Calculating Normals(0,1,0) based on verts FloatBuffer\n - Normals FloatBuffer len="+norms.length);
		#end
		return norms;
	}

	public function buildTangentBuffer() {
		return tangents;
		var verts = getVertices();
		var len = Std.int(verts.length / 3);
		tangents = new hxd.FloatBuffer( verts.length );
		var bitangents = new hxd.FloatBuffer( verts.length );
		var vi = 0;
		var uvi = 0;
		var i0, i1, i2;
		var uvi0, uvi1, uvi2;
		var v0 = new h3d.Vector();
		var v1 = new h3d.Vector();
		var v2 = new h3d.Vector();
		var uv0 = new h3d.Vector();
		var uv1 = new h3d.Vector();
		var uv2 = new h3d.Vector();
		var tangent = new h3d.Vector();
		var bitangent = new h3d.Vector();

		var i = 0;
		while (i < idx.length) {
			i0 = idx[ i ] * 3;
			i1 = idx[ i+1 ] * 3;
			i2 = idx[ i+2 ] * 3;
			v0.set( verts[ i0 ], verts[ i0+1 ], verts[ i0+2 ] );
			v1.set( verts[ i1 ], verts[ i1+1 ], verts[ i1+2 ] );
			v2.set( verts[ i2 ], verts[ i2+1 ], verts[ i2+2 ] );

			uvi0 = idx[ i ] * 2;
			uvi1 = idx[ i+1 ] * 2;
			uvi2 = idx[ i+2 ] * 2;
			uv0.set( uvs[ uvi0 ], uvs[ uvi0+1 ] );
			uv1.set( uvs[ uvi1 ], uvs[ uvi1+1 ] );
			uv2.set( uvs[ uvi2 ], uvs[ uvi2+1 ] );

			var x1 = v1.x - v0.x;
			var x2 = v2.x - v0.x;

			var y1 = v1.y - v0.y;
			var y2 = v2.y - v0.y;

			var z1 = v1.z - v0.z;
			var z2 = v2.z - v0.z;

			var s1 = uv1.x - uv0.x;
			var s2 = uv2.x - uv0.x;

			var t1 = uv1.y - uv0.y;
			var t2 = uv2.y - uv0.y;

			var r = 1.0 / ( s1 * t2 - s2 * t1 );

			tangent.set(
				( t2 * x1 - t1 * x2 ) * r,
				( t2 * y1 - t1 * y2 ) * r,
				( t2 * z1 - t1 * z2 ) * r
			);

			bitangent.set(
				( s1 * x2 - s2 * x1 ) * r,
				( s1 * y2 - s2 * y1 ) * r,
				( s1 * z2 - s2 * z1 ) * r
			);

			tangents[i0] = tangent.x;
			tangents[i0+1] = tangent.y;
			tangents[i0+2] = tangent.z;
			tangents[i1] = tangent.x;
			tangents[i1+1] = tangent.y;
			tangents[i1+2] = tangent.z;
			tangents[i2] = tangent.x;
			tangents[i2+1] = tangent.y;
			tangents[i2+2] = tangent.z;

			bitangents[i0] = bitangent.x;
			bitangents[i0+1] = bitangent.y;
			bitangents[i0+2] = bitangent.z;
			bitangents[i1] = bitangent.x;
			bitangents[i1+1] = bitangent.y;
			bitangents[i1+2] = bitangent.z;
			bitangents[i2] = bitangent.x;
			bitangents[i2+1] = bitangent.y;
			bitangents[i2+2] = bitangent.z;

			i+=3;
		}

		vi = 0;
		var n = new h3d.Vector();
		var t = new h3d.Vector();
		var t2 = new h3d.Vector();
		while (vi < verts.length) {
			n.set( norms[ vi ], norms[ vi+1 ], norms[ vi+2 ] );
			tangent.set( tangents[ vi ], tangents[ vi+1 ], tangents[ vi+2 ] );
			bitangent.set( bitangents[ vi ], bitangents[ vi+1 ], bitangents[ vi+2 ] );

			t.load( tangent );
			n.scale3( n.dot3( tangent ));
			t = t.sub( n );
			t.normalize();
			
			t2.set( norms[ vi ], norms[ vi+1 ], norms[ vi+2 ] );
			t2 = t2.cross( t );
			var test = t2.dot3( bitangent );
			var w = (test < 0.0) ? -1. : 1.;

			tangents[vi] = -t.x;
			tangents[vi+1] = -t.y;
			tangents[vi+2] = t.z;

			vi += 3;
		}
		#if debug_gltf
		trace("Setting up Tangents(n, n, n) tangent FloatBuffer\n - Tangents FloatBuffer len="+tangents.length);
		#end
		return tangents;
	}

	public function buildUVBuffer() {
		if (uvs != null) return uvs;
		var len = Std.int(getVertices().length / 3);
		uvs = new hxd.FloatBuffer();
		var v = 0;
		for (i in 0...len) {
			uvs.push( 0. );
			uvs.push( 0. );
		}
		#if debug_gltf
		trace("Setting up UV(0,0) uv FloatBuffer\n - UV FloatBuffer len="+uvs.length);
		#end
		return uvs;
	}

	public function buildUV2Buffer() {
		if (uv2s != null) return uv2s;
		var uvs = getUVs();
		var len = Std.int(getVertices().length / 3);
		uv2s = new hxd.FloatBuffer();
		for (i in 0...uvs.length) {
			uv2s.push( uvs[i] );
		}
		#if debug_gltf
		trace("Duplicating UV2s from UVs\n - UV2 FloatBuffer len="+uv2s.length);
		#end
		return uv2s;
	}

}