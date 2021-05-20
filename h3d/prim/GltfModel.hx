package h3d.prim;

import hxd.fmt.gltf.Geometry;
import hxd.FloatBuffer;
import hxd.IndexBuffer;

class GltfModel extends MeshPrimitive {
	
	public var geom(default, null):Geometry;
	public var skin : h3d.anim.Skin;
	public var multiMaterial:Bool;
	public var name:String;

	var bounds : h3d.col.Bounds;
	var tcount : Int = -1;
	var curMaterial : Int = -1;
	var collider : h3d.col.Collider;
	var lib : hxd.fmt.gltf.BaseLibrary;

	public function new( g, lib ) {
		this.geom = g;
		this.lib = lib;
	}

	override public function triCount() : Int {
		return Std.int( geom.getIndices().length / 3 );
	}

	override public function vertexCount():Int
	{
		return triCount() * 3;
	}

	public function setSkin( skin : h3d.anim.Skin ) {
		skin.primitive = this;
		this.skin = skin;
	}

	override public function selectMaterial(material:Int)
	{
		curMaterial = material;
	}

	override function getBounds() {
		if( bounds != null )
			return bounds;
		bounds = new h3d.col.Bounds();
		bounds.empty();
		var verts = geom.getVertices();
		// var gm = geom.getGeomMatrix();
		var tmp = new h3d.col.Point();
		bounds.xMin = bounds.yMin = bounds.zMin = Math.POSITIVE_INFINITY;
		bounds.xMax = bounds.yMax = bounds.zMax = Math.NEGATIVE_INFINITY;
		var pos = 0;
		while( pos < verts.length ) {
			var x = verts[pos++];
			var y = verts[pos++];
			var z = verts[pos++];
			// if( gm != null ) {
			// 	tmp.set(x, y, z);
			// 	tmp.transform(gm);
			// 	x = tmp.x;
			// 	y = tmp.y;
			// 	z = tmp.z;
			// }
			if( x > bounds.xMax ) bounds.xMax = x;
			if( x < bounds.xMin ) bounds.xMin = x;
			if( y > bounds.yMax ) bounds.yMax = y;
			if( y < bounds.yMin ) bounds.yMin = y;
			if( z > bounds.zMax ) bounds.zMax = z;
			if( z < bounds.zMin ) bounds.zMin = z;
		}
		return bounds;
	}

	override public function alloc(engine:Engine)
	{
		dispose();
		
		var verts = geom.getVertices();
		var norms = geom.getNormals();
		var tangents = geom.getTangents();
		var idx = geom.getIndices();
		var uvs = geom.getUVs();
		var uv2s = geom.getUV2s(); //TODO: Implement 2nd UV coords

		if (idx == null) {
			idx = new IndexBuffer();
			var v = 0;
			for (i in 0...Std.int(verts.length / 3)) {
				idx.push( v++ );
			}
			#if debug_gltf
			trace("Setting up sequential IndexBuffer\n - IndexBuffer len="+idx.length);
			#end
		}
		if (uvs == null) {
			uvs = new hxd.FloatBuffer();
			var v = 0;
			for (i in 0...Std.int(verts.length / 3)) {
				uvs.push( 0. );
				uvs.push( 0. );
			}
			#if debug_gltf
			trace("Setting up UV(0,0) uv FloatBuffer\n - UV FloatBuffer len="+uvs.length);
			#end
		}

		if (uv2s == null) {
			uv2s = new hxd.FloatBuffer();
			for (i in 0...uvs.length) {
				uv2s.push( uvs[i] );
			}
			#if debug_gltf
			trace("Duplicating UV2s from UVs\n - UV2 FloatBuffer len="+uvs.length);
			#end
		}

		if (norms == null) {
			norms = new hxd.FloatBuffer();
			var v = 0;
			for (i in 0...Std.int(verts.length / 3)) {
				norms.push( 0. );
				norms.push( 1. );
				norms.push( 0. );
			}
			#if debug_gltf
			trace("Calculating Normals(0,1,0) based on verts FloatBuffer\n - Normals FloatBuffer len="+norms.length);
			#end
		}

		if (false) { //tangents == null) {
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
		}

		addBuffer("position", h3d.Buffer.ofFloats(verts, 3));
		if( norms != null ) addBuffer("normal", h3d.Buffer.ofFloats(norms, 3));
		if( tangents != null ) addBuffer("tangent", h3d.Buffer.ofFloats(tangents, 4));
		addBuffer("uv", h3d.Buffer.ofFloats(uvs, 2));
		var moreThan64KVertices = verts.length>65535;
		indexes = h3d.Indexes.alloc(idx, 0, -1, moreThan64KVertices);
	}

	public function getFaces():Array<TriFace> {
		var verts = geom.getVertices();
		var norms = geom.getNormals();
		var tangents = geom.getTangents();
		var idx = geom.getIndices();
		var uvs = geom.getUVs();
		var uv2s = geom.getUV2s();

		var faces:Array<TriFace> = [];
		var i = 0;
		var v0 = new h3d.Vector();
		var v1 = new h3d.Vector();
		var v2 = new h3d.Vector();
		var n0 = new h3d.Vector();
		var n1 = new h3d.Vector();
		var n2 = new h3d.Vector();
		var uv0 = new h3d.Vector();
		var uv1 = new h3d.Vector();
		var uv2 = new h3d.Vector();

		while (i < idx.length) {
			var bI = idx[i] * 9;
			var cI = idx[i++] * 6;
			v0 = new Vector( verts[bI], verts[bI+1], verts[bI+2] );
			n0 = new Vector( norms[bI], norms[bI+1], norms[bI+2] );
			uv0 = new Vector( uvs[cI], uvs[cI+1] );
			
			bI = idx[i] * 9;
			cI = idx[i++] * 6;
			v1 = new Vector( verts[bI], verts[bI+1], verts[bI+2] );
			n1 = new Vector( norms[bI], norms[bI+1], norms[bI+2] );
			uv1 = new Vector( uvs[cI], uvs[cI+1] );

			bI = idx[i] * 9;
			cI = idx[i++] * 6;
			v2 = new Vector( verts[bI], verts[bI+1], verts[bI+2] );
			n2 = new Vector( norms[bI], norms[bI+1], norms[bI+2] );
			uv2 = new Vector( uvs[cI], uvs[cI+1] );

			faces.push( new TriFace( v0, v1, v2, n0 ,n1, n2, uv0, uv1, uv2 ) );
		}

		return faces;
	}

	override function render( engine : h3d.Engine ) {
		if( curMaterial < 0 ) {
			super.render(engine);
			return;
		}
		if( indexes == null || indexes.isDisposed() )
			alloc(engine);
		var idx = indexes;
		
		if( indexes != null ) super.render(engine);
		indexes = idx;
		curMaterial = -1;
	}

	function initCollider( poly : h3d.col.PolygonBuffer ) {
		#if neko
		var verts = haxe.ds.Vector.fromArrayCopy(geom.getVertices().getNative());
		var inds = haxe.ds.Vector.fromArrayCopy(geom.getIndices().getNative());
		#elseif flash
		var verts = haxe.ds.Vector.fromData(geom.getVertices().getNative());
		var i = geom.getIndices();
		var inds:haxe.ds.Vector<hxd.impl.UInt16> = new haxe.ds.Vector<hxd.impl.UInt16>(i.length);
		for (pos in 0...i.length)
			inds[pos] = i[pos];
		#else
		var verts = haxe.ds.Vector.fromData(geom.getVertices().getNative());
		var inds = haxe.ds.Vector.fromData(geom.getIndices().getNative());
		var uvs = haxe.ds.Vector.fromData(geom.getUVs().getNative());
		#end

		poly.setData(verts, inds, uvs);
		if( collider == null ) {
			collider = new h3d.col.Collider.OptimizedCollider(getBounds(), poly);
		}
	}

	override function getCollider() {
		if( collider != null )
			return collider;
		var poly = new h3d.col.PolygonBuffer();
		poly.source = {
			entry : null,
			geometryName : name,
		};
		initCollider(poly);
		return collider;
	}

}

class TriFace {
	public var v0:h3d.Vector;
	public var v1:h3d.Vector;
	public var v2:h3d.Vector;
	public var n0:h3d.Vector;
	public var n1:h3d.Vector;
	public var n2:h3d.Vector;
	public var uv0:h3d.Vector;
	public var uv1:h3d.Vector;
	public var uv2:h3d.Vector;

	public function new(v0, v1, v2, n0, n1, n2, uv0, uv1, uv2) { 
		this.v0 = v0;
		this.v1 = v1;
		this.v2 = v2;
		this.n0 = n0;
		this.n1 = n1;
		this.n2 = n2;
		this.uv0 = uv0;
		this.uv1 = uv1;
		this.uv2 = uv2;
	}
}