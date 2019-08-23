package h3d.prim;

import hxd.fmt.gltf.Geometry;
import hxd.FloatBuffer;
import hxd.IndexBuffer;

class GltfModel extends MeshPrimitive {
	
	public var geom(default, null):Geometry;
	public var skin : h3d.anim.Skin;
	public var multiMaterial:Bool;

	var bounds : h3d.col.Bounds;
	var tcount : Int = -1;
	var curMaterial : Int = -1;

	public function new( g ) {
		this.geom = g;
	}

	override public function triCount() : Int {
		// if (tcount == -1) {
		// 	tcount = 0;
		// 	for ( prim in geom.root.primitives ) {
		// 		tcount += Std.int(geom.l.root.accessors[prim.indices].count / 3);
		// 	}
		// }
		return tcount;
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
		var verts = geom.getVertices();
		// var gm = geom.getGeomMatrix();
		var tmp = new h3d.col.Point();
		if( verts.length > 0 ) {
			tmp.set(verts[0], verts[1], verts[2]);
			// if( gm != null ) tmp.transform(gm);
			bounds.xMin = bounds.xMax = tmp.x;
			bounds.yMin = bounds.yMax = tmp.y;
			bounds.zMin = bounds.zMax = tmp.z;
		}
		var pos = 3;
		for( i in 1...Std.int(verts.length / 3) ) {
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

		if (idx == null) {
			trace("Setting up sequential IndexBuffer");
			idx = new IndexBuffer();
			var v = 0;
			for (i in 0...Std.int(verts.length / 3)) {
				idx.push( v++ );
			}
			trace(" - IndexBuffer len="+idx.length);
		}
		if (uvs == null) {
			trace("Setting up UV(0,0) uv FloatBuffer");
			uvs = new hxd.FloatBuffer();
			var v = 0;
			for (i in 0...Std.int(verts.length / 3)) {
				uvs.push( 0. );
				uvs.push( 0. );
			}
			trace(" - UV FloatBuffer len="+uvs.length);
		}

		if (norms == null) {
			trace("Calculating Normals(0,1,0) based on verts FloatBuffer");
			norms = new hxd.FloatBuffer();
			var v = 0;
			for (i in 0...Std.int(verts.length / 3)) {
				norms.push( 0. );
				norms.push( 1. );
				norms.push( 0. );
			}
			trace(" - Normals FloatBuffer len="+norms.length);
		}

		if (tangents == null) {
			trace("Setting up Tangents(n, n, n) tangent FloatBuffer");
			tangents = new hxd.FloatBuffer();
			var vi = 0;
			var uvi = 0;

			var v0 = new h3d.Vector();
			var v1 = new h3d.Vector();
			var v2 = new h3d.Vector();
			var uv0 = new h3d.Vector();
			var uv1 = new h3d.Vector();
			var uv2 = new h3d.Vector();
			var dP1 = new h3d.Vector();
			var dP2 = new h3d.Vector();
			var dUV1 = new h3d.Vector();
			var dUV2 = new h3d.Vector();

			while (vi < verts.length) {
				v0.set( verts[ vi ], verts[ vi+1 ], verts[ vi+2 ] );
				v1.set( verts[ vi+3 ], verts[ vi+4 ], verts[ vi+5 ] );
				v2.set( verts[ vi+6 ], verts[ vi+7 ], verts[ vi+8 ] );

				uv0.set( uvs[ uvi ], uvs[ uvi+1 ] );
				uv1.set( uvs[ uvi+2 ], uvs[ uvi+3 ] );
				uv2.set( uvs[ uvi+4 ], uvs[ uvi+4 ] );

				dP1.load( v1 );
				dP1.sub( v0 );

				dP2.load( v2 );
				dP2.sub( v0 );

				dUV1.load( uv1 );
				dUV1.sub( uv0 );

				dUV2.load( uv2 );
				dUV2.sub( uv0 );

				var r = 1 / (dUV1.x * dUV2.y - dUV1.y * dUV2.x);
				
				var t = new Vector( (dP1.x * dUV2.y) + (dP2.x * -dUV1.y), (dP1.y * dUV2.y) + (dP2.y * -dUV1.y), (dP1.z * dUV2.y) + (dP2.z * -dUV1.y));
				tangents.push( t.x );
				tangents.push( t.y );
				tangents.push( t.z );
				tangents.push( t.x );
				tangents.push( t.y );
				tangents.push( t.z );
				tangents.push( t.x );
				tangents.push( t.y );
				tangents.push( t.z );

				vi += 9;
				uvi += 6;
			}
			trace(" - Tangents FloatBuffer len="+tangents.length);
		}

		addBuffer("position", h3d.Buffer.ofFloats(verts, 3));
		if( norms != null ) addBuffer("normal", h3d.Buffer.ofFloats(norms, 3));
		if( tangents != null ) addBuffer("tangent", h3d.Buffer.ofFloats(tangents, 3));
		addBuffer("uv", h3d.Buffer.ofFloats(uvs, 2));
		indexes = h3d.Indexes.alloc(idx);
	}

	public function getFaces():Array<TriFace> {
		var verts = geom.getVertices();
		var norms = geom.getNormals();
		var tangents = geom.getTangents();
		var idx = geom.getIndices();
		var uvs = geom.getUVs();

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
			// faces.push( new TriFace( verts[idx[i]], verts[idx[i+1]], verts[idx[i+2]], norms[idx[i]], norms[idx[i+1]], norms[idx[i+2]], uvs[idx[i]], uvs[idx[i+1]], uvs[idx[i+2]] ) );
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