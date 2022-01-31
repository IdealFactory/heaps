package h3d.col;

class PolygonBuffer implements Collider {

	var buffer : haxe.ds.Vector<hxd.impl.Float32>;
	var indexes : haxe.ds.Vector<Int>;
	var uvs : haxe.ds.Vector<hxd.impl.Float32>;
	var startIndex : Int;
	var triCount : Int;
	public var source : { entry : hxd.fs.FileEntry, geometryName : String };

	public function new() {
	}

	public function setData( buffer, indexes, uvs = null, startIndex = 0, triCount = -1 ) {
		this.buffer = buffer;
		this.indexes = indexes;
		this.uvs = uvs;
		this.startIndex = startIndex;
		this.triCount = triCount >= 0 ? triCount : Std.int((indexes.length - startIndex) / 3);
	}

	public function contains( p : Point ) {
		// CONVEX only : TODO : check convex (cache result)
		var i = startIndex;
		var p = new FPoint(p.x, p.y, p.z);
		for( t in 0...triCount ) {
			var i0 = indexes[i++] * 3;
			var p0 = new FPoint(buffer[i0++], buffer[i0++], buffer[i0]);
			var i1 = indexes[i++] * 3;
			var p1 = new FPoint(buffer[i1++], buffer[i1++], buffer[i1]);
			var i2 = indexes[i++] * 3;
			var p2 = new FPoint(buffer[i2++], buffer[i2++], buffer[i2]);

			var d1 = p1.sub(p0);
			var d2 = p2.sub(p0);
			var n = d1.cross(d2);
			var d = n.dot(p0);

			if( n.dot(p) >= d )
				return false;
		}
		return true;
	}

	public function inFrustum( f : Frustum, ?m : h3d.Matrix ) {
		throw "Not implemented";
		return false;
	}

	public function inSphere( s : Sphere ) {
		throw "Not implemented";
		return false;
	}

	// Möller–Trumbore intersection
	public function rayIntersection( r : Ray, bestMatch : Bool ) : HitPoint {
		var i = startIndex;
		var rdir = new FPoint(r.lx, r.ly, r.lz);
		var r0 = new FPoint(r.px, r.py, r.pz);
		var best = new HitPoint(-1.);
		// var txt = "PolygonBuffer:rayIntersection call:");
		var hasHit = false;
		for( t in 0...triCount ) {
			var i0 = indexes[i] * 3;
			var uvi0 = indexes[i++] * 2;
			var p0 = new FPoint(buffer[i0++], buffer[i0++], buffer[i0]);
			var i1 = indexes[i] * 3;
			var uvi1 = indexes[i++] * 2;
			var p1 = new FPoint(buffer[i1++], buffer[i1++], buffer[i1]);
			var i2 = indexes[i] * 3;
			var uvi2 = indexes[i++] * 2;
			var p2 = new FPoint(buffer[i2++], buffer[i2++], buffer[i2]);
			// p0.z = p0.z;
			// p1.z = p1.z;
			// p2.z = p2.z;
			
			var uv0 = new FPoint(uvs[uvi0++], uvs[uvi0]);
			var uv1 = new FPoint(uvs[uvi1++], uvs[uvi1]);
			var uv2 = new FPoint(uvs[uvi2++], uvs[uvi2]);

			var e1 = p1.sub(p0);
			var e2 = p2.sub(p0);
			var p = rdir.cross(e2);
			var det = e1.dot(p);
			if( det < hxd.Math.EPSILON ) continue; // backface culling (negative) and near parallel (epsilon)

			var invDet = 1 / det;
			var T = r0.sub(p0);
			var u = T.dot(p) * invDet;

			if( u < 0 || u > 1 ) continue;

			var q = T.cross(e1);
			var v = rdir.dot(q) * invDet;

			if( v < 0 || u + v > 1 ) continue;

			var t = new HitPoint(e2.dot(q) * invDet);

			if( t < hxd.Math.EPSILON ) continue;

			var s0x = p1.x - p0.x; // s0 = p1 - p0
			var s0y = p1.y - p0.y;
			var s0z = p1.z - p0.z;
			var s1x = p2.x - p0.x; // s1 = p2 - p0
			var s1y = p2.y - p0.y;
			var s1z = p2.z - p0.z;
			var nx = s0y*s1z - s0z*s1y; // n = s0 x s1
			var ny = s0z*s1x - s0x*s1z;
			var nz = s0x*s1y - s0y*s1x;
			var nl = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
			nx *= nl;
			ny *= nl;
			nz *= nl;
			
			var rayDirection = new FPoint(rdir.x, rdir.y, rdir.z);
			var rayPosition = new FPoint(r.px, r.py, r.pz);
			// -- plane intersection test --
			var nDotV = nx*rayDirection.x + ny*rayDirection.y + nz*rayDirection.z; // rayDirection . normal
			// find collision t
			var D = -( nx*p0.x + ny*p0.y + nz*p0.z );
			var disToPlane = -( nx*rayPosition.x + ny*rayPosition.y + nz*rayPosition.z + D );
			t = new HitPoint(disToPlane/nDotV);

			var cx = r.px + t.hit*rdir.x;
			var cy = r.py + t.hit*rdir.y;
			var cz = r.pz + t.hit*rdir.z;
			// collision point inside triangle? ( using barycentric coordinates )
			var Q1Q2 = e1.x*e2.x + e1.y*e2.y + e1.z*e2.z;
			var Q1Q1 = e1.x*e1.x + e1.y*e1.y + e1.z*e1.z;
			var Q2Q2 = e2.x*e2.x + e2.y*e2.y + e2.z*e2.z;
			var rx = cx - p0.x;
			var ry = cy - p0.y;
			var rz = cz - p0.z;
			var RQ1 = rx*e1.x + ry*e1.y + rz*e1.z;
			var RQ2 = rx*e2.x + ry*e2.y + rz*e2.z;
			var coeff = 1/( Q1Q1*Q2Q2 - Q1Q2*Q1Q2 );
		
			var tv = coeff*( Q2Q2*RQ1 - Q1Q2*RQ2 );
			var tw = coeff*( -Q1Q2*RQ1 + Q1Q1*RQ2 );
			var tu = 1 - tv - tw;
			var w = 1 - v + u;

			if( !bestMatch ) {
				t.i0 = i0;
				t.i1 = i1;
				t.i2 = i2;
				t.p0 = p0;
				t.p1 = p1;
				t.p2 = p2;
				var tx = tu*uv0.x + tv*uv1.x + tw*uv2.x;
				var ty = tu*uv0.y + tv*uv1.y + tw*uv2.y;
				t.u = tx;
				t.v = ty;
				// trace(" - NOT bestMatch="+hitInfo);
				return t;
			}
			if( best < 0 || t < best ) {
				hasHit = true;
				best.hit = t.hit;
				best.i0 = i0;
				best.i1 = i1;
				best.i2 = i2;
				best.p0 = p0;
				best.p1 = p1;
				best.p2 = p2;
				best.s0 = new FPoint(p0.x + s0x*0.5, p0.y + s0y*0.5, p0.z + s0z*0.5);
				best.s1 = new FPoint(p0.x + s1x*0.5, p0.y + s1y*0.5, p0.z + s1z*0.5);
				best.n = new FPoint(nx, ny, nz);
				best.p = rayPosition;
				best.c = new FPoint(cx, cy, cz);
				var tx = tu*uv0.x + tv*uv1.x + tw*uv2.x;
				var ty = tu*uv0.y + tv*uv1.y + tw*uv2.y;
				best.u = tx;
				best.v = 1 + ty;
				// trace("CALC-1: uvw:"+u+"/"+v+"/"+w+" uv0:"+uv0+" uv1:"+uv1+" uv2:"+uv2+" p:"+p+" q:"+q+" ");
				// var g = com.idealfactory.editor.view.product3D.component.HeapsMain.draw.graphics;
				// // var g = PbrWebGL1.draw.graphics;
				// g.clear();
				// g.beginFill(0xffffff);
				// g.drawRect( 0, 0, 1800, 200);
				// g.endFill();

				// draw( g, u, v, 0, 0xff0000);
				
				// com.idealfactory.editor.view.product3D.component.HeapsMain.debug.text="uvw:"+u+"/"+v+"/"+w+"\ntuvw:"+tu+"/"+tv+"/"+tw;
				// com.idealfactory.editor.view.product3D.component.HeapsMain.debug.text+="\nuv:"+u+"/"+v+"\ntxy:"+tx+"/"+ty;
				// com.idealfactory.editor.view.product3D.component.HeapsMain.debug.text="Q1Q1:"+Q1Q1+" Q1Q2:"+Q1Q2+" Q2Q2:"+Q2Q2;
				// com.idealfactory.editor.view.product3D.component.HeapsMain.debug.text="\nRED P0:"+p0+"\nGRN P1:"+p1+"\nBLU P2:"+p2;
				// com.idealfactory.editor.view.product3D.component.HeapsMain.debug.text+="\ncoeff:"+coeff+"\np:"+r.px+"/"+r.py+"/"+r.pz+"\nc:"+cx+"/"+cy+"/"+cz+"\ndir:"+rdir.x+"/"+rdir.y+"/"+rdir.z;
				// com.idealfactory.editor.view.product3D.component.HeapsMain.debug.text+="\ndet:"+det+" invDet:"+invDet;
				// com.idealfactory.editor.view.product3D.component.HeapsMain.debug.text+="\nuvw:"+u+"/"+v+"/"+w+"\ntuvw:"+tu+"/"+tv+"/"+tw;
				// com.idealfactory.editor.view.product3D.component.HeapsMain.debug.text+="\nuv:"+u+"/"+v+"\ntxy:"+best.u+"/"+best.v;
				
			}
		}
		// trace(" - BestMatch="+hitInfo);
		return best;
	}
	var sz = 50;

	function draw( g:openfl.display.Graphics, u:Float, v:Float, off:Float, col:UInt ) {
		g.lineStyle( 2, col );
		g.moveTo( sz + (off * sz * 2), 50 );
		g.lineTo( sz + (off * sz * 2) + (u * 50), 50 + (v * 50) );
}

	#if !macro
	public function makeDebugObj() : h3d.scene.Object {
		var points = new Array<Point>();
		var idx = new hxd.IndexBuffer();
		var i = startIndex;
		for( t in 0...triCount ) {
			idx.push(indexes[i++]);
			idx.push(indexes[i++]);
			idx.push(indexes[i++]);
		}
		i = 0;
		while( i < buffer.length ) {
			points.push(new Point(buffer[i++], buffer[i++], buffer[i++]));
		}
		var prim = new h3d.prim.Polygon(points, idx);
		prim.addNormals();
		return new h3d.scene.Mesh(prim);
	}
	#end

}
