package hxd.fmt.gltf;

import haxe.io.Bytes;
import hxd.BytesBuffer;
import hxd.FloatBuffer;
import hxd.IndexBuffer;
import h3d.Matrix;

typedef GltfId = Int;

typedef GltfProperty = {
	@:optional var extensions:Dynamic;
	@:optional var extras:Dynamic;
}

typedef GltfChildOfRootProperty = {
	>GltfProperty,
	@:optional var name:String;
}

abstract GltfAccessor<T>(Dynamic) to Dynamic {
	public inline function keys() return Reflect.fields(this);
	public inline function get(name:String) return Reflect.field(this, name);
}

typedef Accessor = {
	>GltfChildOfRootProperty,
	@:optional var bufferView:GltfId;
	@:optional var byteOffset:Int; // def: 0
	var componentType:ComponentType;
	@:optional var normalized:Bool;
	var count:Int;
	var type:AccessorType;
	@:optional var max:Array<Int>;
	@:optional var min:Array<Int>;
	@:optional var sparce:AccessorSparse;
}

typedef AccessorSparse = {
	>GltfProperty,
	var count:Int;
	var indices:AccessorSparseIndices;
	var values:AccessorSparseValues;
}

typedef AccessorSparseIndices = {
	>GltfProperty,
	var bufferView:GltfId;
	@:optional var byteOffset:Int;
	var componentType:ComponentType;
}

typedef AccessorSparseValues = {
	>GltfProperty,
	var bufferView:GltfId;
	@:optional var byteOffset:Int;
}

enum abstract ComponentType(Int) {
	
	var CTByte = 5120;
	var CTUnsignedByte = 5121;
	var CTShort = 5122;
	var CTUnsignedShort = 5123;
	// var CTInt;
	// var CTUnsignedInt = 5125;
	var CTFloat = 5126;

	public inline function toInt():Int { return this; }

}

enum abstract AccessorType(String) {
	var Scalar = "SCALAR";
	var Vec2 = "VEC2";
	var Vec3 = "VEC3";
	var Vec4 = "VEC4";
	var Mat2 = "MAT2";
	var Mat3 = "MAT3";
	var Mat4 = "MAT4";

	public inline function toString():String { return this; }

}

typedef AnimationChannel = {
	>GltfProperty,
	var sampler:GltfId;
	var target:AnimationChannelTarget;
}

typedef AnimationChannelTarget = {
	>GltfProperty,
	@:optional var node:GltfId;
	var path:AnimationPath;
}

enum abstract AnimationPath(String) {
	var Translation = "translation";
	var Rotation = "rotation";
	var Scale = "scale";
	var Weights = "weights";
	
	public inline function toString():String { return this; }
}

typedef AnimationSampler = {
	>GltfProperty,
	var input:GltfId;
	@:optional var interpolation:AnimationInterpolation;
	var output:GltfId;
}

enum abstract AnimationInterpolation(String) {
	var Linear = "LINEAR";
	var Step = "STEP";
	var CubicSpline = "CUBICSPLINE";

	public inline function toString():String { return this; }
}

typedef Animation = {
	>GltfChildOfRootProperty,
	var channels:Array<AnimationChannel>;
	var samplers:Array<AnimationSampler>;
}

typedef Asset = {
	>GltfProperty,
	@:optional var copyright:String;
	@:optional var generator:String;
	var version:String;
	@:optional var minVersion:String;
}

typedef Buffer = {
	>GltfChildOfRootProperty,
	@:optional var uri:String;
	var byteLength:Int;
}

typedef BufferView = {
	>GltfChildOfRootProperty,
	var buffer:GltfId;
	@:optional var byteOffset:Int;
	var byteLength:Int;
	@:optional var byteStride:Int;
	@:optional var target:BufferTarget;
}

enum abstract BufferTarget(Int) {
	var ArrayBuffer = 34962;
	var ElementArrayBuffer = 34963;

	public inline function toInt():Int { return this; }
}

typedef CameraOrthographic = {
	>GltfProperty,
	var xmag:Float;
	var ymag:Float;
	var zfar:Float;
	var znear:Float;
}

typedef CameraPerspective = {
	>GltfProperty,
	var aspectRatio:Float;
	var yfov:Float;
	var zfar:Float;
	var znear:Float;
}

typedef Camera = {
	>GltfChildOfRootProperty,
	@:optional var orthographic:CameraOrthographic;
	@:optional var perspective:CameraPerspective;
	var type:CameraType;
}

enum abstract CameraType(String) {
	var Perspective = "perspective";
	var Orthographic = "orthographic";

	public inline function toString():String { return this; }
}

// Extension = Dynamic
// Extras = Dynamic
typedef Gltf = {
	>GltfProperty,
	@:optional var extensionsUsed:Array<String>;
	@:optional var extensionsRequired:Array<String>;
	@:optional var accessors:Array<Accessor>;
	@:optional var animations:Array<Animation>;
	var asset:Asset;
	@:optional var buffers:Array<Buffer>;
	@:optional var bufferViews:Array<BufferView>;
	@:optional var cameras:Array<Camera>;
	@:optional var images:Array<Image>;
	@:optional var materials:Array<Material>;
	@:optional var meshes:Array<Mesh>;
	@:optional var nodes:Array<Node>;
	@:optional var samplers:Array<Sampler>;
	@:optional var scene:GltfId;
	@:optional var scenes:Array<Scene>;
	@:optional var skins:Array<Skin>;
	@:optional var textures:Array<Texture>;
}

typedef Image = {
	>GltfChildOfRootProperty,
	@:optional var uri:String;
	@:optional var mimeType:ImageMimeType;
	@:optional var bufferView:GltfId;
}

enum abstract ImageMimeType(String) {
	var ImageJpeg = "image/jpeg";
	var ImagePng = "image/png";

	public inline function toString():String { return this; }
}


typedef TextureInfo = {
	>GltfProperty,
	var index:GltfId;
	@:optional var texCoord:Int;
}

typedef MaterialNormalTextureInfo = {
	>TextureInfo,
	@:optional var scale:Float;
}

typedef MaterialOcclusionTextureInfo = {
	>TextureInfo,
	@:optional var strength:Float;
}

typedef MaterialMetalicRoughness = {
	>GltfProperty,
	@:optional var baseColorFactor:Array<Float>;
	@:optional var baseColorTexture:TextureInfo;
	@:optional var metallicFactor:Float;
	@:optional var roughnessFactor:Float;
	@:optional var metallicRoughnessTexture:TextureInfo;
}

typedef Material = {
	>GltfChildOfRootProperty,
	@:optional var pbrMetallicRoughness:MaterialMetalicRoughness;
	@:optional var normalTexture:MaterialNormalTextureInfo;
	@:optional var occlusionTexture:MaterialOcclusionTextureInfo;
	@:optional var emissiveTexture:TextureInfo;
	@:optional var emissiveFactor:Array<Float>;
	@:optional var alphaMode:MaterialAlphaMode;
	@:optional var alphaCutoff:Float;
	@:optional var doubleSided:Bool;
}

enum abstract MaterialAlphaMode(String) {
	var Opaque = "OPAQUE";
	var Mask = "MASK";
	var Blend = "BLEND";

	public inline function toString():String { return this; }
}

typedef MeshPrimitive = {
	>GltfProperty,
	var attributes:GltfAccessor<GltfId>;
	@:optional var indices:GltfId;
	@:optional var material:GltfId;
	@:optional var mode:MeshPrimitiveMode;
	@:optional var targets:Array<MeshPrimitiveTarget>;
}

enum abstract MeshPrimitiveMode(Int) {
	var Points = 0;
	var Lines;
	var LineLoop;
	var LineStrip;
	var Triangles;
	var TriangleStrip;
	var TriangleFan;

	public inline function toInt():Int { return this; }
}

typedef MeshPrimitiveTarget = {
	var POSITION:GltfId;
	var NORMAL:GltfId;
	var TANGENT:GltfId;
}

typedef Mesh = {
	>GltfChildOfRootProperty,
	var primitives:Array<MeshPrimitive>;
	@:optional var weights:Array<Float>;
}

typedef Node = {
	>GltfChildOfRootProperty,
	@:optional var camera:GltfId;
	@:optional var children:Array<GltfId>;
	@:optional var skin:GltfId;
	@:optional var matrix:Array<Float>;
	@:optional var mesh:GltfId;
	@:optional var rotation:Array<Float>;
	@:optional var scale:Array<Float>;
	@:optional var translation:Array<Float>;
	@:optional var weights:Array<Float>;
}

typedef Sampler = {
	>GltfChildOfRootProperty,
	@:optional var magFilter:SamplerFilterMode;
	@:optional var minFilter:SamplerFilterMode;
	@:optional var wrapS:SamplerWrapMode;
	@:optional var wrapT:SamplerWrapMode;
}

enum abstract SamplerFilterMode(Int) {
	var Nearest = 9728;
	var Linear = 9729;
	var NearestMipmapNearest = 9984;
	var LinearMipmapNearest = 9985;
	var NearestMipmapLinear = 9986;
	var LinearMipmapLinear = 9987;

	public inline function toInt():Int { return this; }
}

enum abstract SamplerWrapMode(Int) {
	var ClampToEdge = 33071;
	var MirroredRepeat = 33648;
	var Repeat = 10497;

	public inline function toInt():Int { return this; }
}

typedef Scene = {
	>GltfChildOfRootProperty,
	@:optional var nodes:Array<GltfId>;
}

typedef Skin = {
	>GltfChildOfRootProperty,
	@:optional var inverseBindMatrices:GltfId;
	@:optional var skeleton:GltfId;
	var joints:Array<GltfId>;
}

typedef Texture = {
	>GltfChildOfRootProperty,
	var sampler:GltfId;
	var source:GltfId;
}

// Extensions

typedef MaterialSpecularGlossinessExt = {
	>GltfProperty,
	@:optional var diffuseFactor:Array<Float>;
	@:optional var diffuseTexture:TextureInfo;
	@:optional var specularFactor:Array<Float>;
	@:optional var glossinessFactor:Array<Float>;
	@:optional var specularGlossinessTexture:TextureInfo;
}

typedef GltfContainer = {
	var header:Gltf;
	var buffers:Array<haxe.io.Bytes>;
}

typedef BytePointer = {
	var pos:Int;
}

class GltfTools {

	public static function getBytesBuffer( attribute, l, accId ) : BytesBuffer {
		var acc = l.root.accessors[ accId ];
		var ct:ComponentType = acc.componentType;
		
		var buffer = new BytesBuffer();
		var bytes = getBufferBytesByAccessor( l, accId );
 		var bytePtr:BytePointer = { pos: 0 };
		var out = "";
		var i:Int;
		var b0:Int, b1:Int, b2:Int, b3:Int;
		var ctr = 0;
		while ( bytePtr.pos < bytes.length ) {
			i = (((b0=getInt(ct, bytes, bytePtr)) & 0xff)) | 
				(((b1=getInt(ct, bytes, bytePtr)) & 0xff) << 8) | 
				(((b2=getInt(ct, bytes, bytePtr)) & 0xff) << 16) | 
				(((b3=getInt(ct, bytes, bytePtr)) & 0xff) << 24);
			out += b0+" "+b1+" "+b2+" "+b3+" ";
			buffer.writeInt32( i );
			ctr++;
		}
		#if debug_gltf
		trace("BytesBuffer("+attribute+":Len="+buffer.length+")="+out+" ...");
		#end

		return buffer;
	}

	public static function getIndexBuffer( attribute, l, accId ) : IndexBuffer {
		var buffer:IndexBuffer = new IndexBuffer();
		var bytes = getBufferBytesByAccessor( l, accId );
		var acc = l.root.accessors[ accId ];
 		var pos = 0;
		var out = "";
		var dat = 0;
		while ( pos < bytes.length ) {
			
			switch (acc.componentType) {
				case CTShort:
					dat = ((bytes.get( pos++ ) << 8) | bytes.get( pos++ ));
					out += dat+" ";		
					buffer.push( dat );
				case CTUnsignedShort : 
					out += bytes.getUInt16( pos )+" ";
					buffer.push( bytes.getUInt16( pos ));
					pos += 2;
				case CTFloat :
				default:
					out += bytes.get( pos )+" ";
					buffer.push( bytes.get( pos++ ));

			}
		}
		#if debug_gltf
		trace("IndexBuffer("+attribute+":Len="+buffer.length+")="+out);
		#end
		
		return buffer;
	}

	public static function getFloatBuffer( attribute, l, accId ) : FloatBuffer {
		var acc = l.root.accessors[ accId ];
		var ct:ComponentType = acc.componentType;
		
		var buffer:FloatBuffer = new FloatBuffer();
		var bytes = getBufferBytesByAccessor( l, accId );
 		var bytePtr:BytePointer = { pos: 0 };
		var out = "";
		var f:Float;
		var ctr = 0;
		while ( bytePtr.pos < bytes.length ) {
			f = getFloat( ct, bytes, bytePtr );
			out += f+" ";
			buffer.push( f );
			ctr++;
		}
		#if debug_gltf
		trace("FloatBuffer("+attribute+":Len="+buffer.length+")="+out+" ...");
		#end
		
		return buffer;
	}

	public static function getNormalisedFloatBuffer( attribute, l, accId ) : FloatBuffer {
		var acc = l.root.accessors[ accId ];
		var ct:ComponentType = acc.componentType;
		var count:Int = acc.count;
		var t:AccessorType = acc.type;

		var buffer:FloatBuffer = new FloatBuffer();
		var bytes = getBufferBytesByAccessor( l, accId );
 		var bytePtr:BytePointer = { pos: 0 };

		var componentCount = 1;
		if (acc != null) {
			switch (acc.type) {
				case Vec2 : componentCount = 2;
				case Vec3 : componentCount = 3;
				case Vec4 | Mat2: componentCount = 4;
				case Mat3 : componentCount = 9;
				case Mat4 : componentCount = 16;
				default: componentCount = 1;
			}
		}

		var out = "";
		var f:Float;
		var ctr = 0;
		while ( ctr++ < count ) {
			for (i in 0...componentCount) { 
				f = getFloat( ct, bytes, bytePtr );
				if (bytePtr.pos < 128) out += f+" ";
				buffer.push( f );
			}
		}
		#if debug_gltf
		trace("NormalisedFloatBuffer("+attribute+":Len="+buffer.length+")="+out+" ...");
		#end
		
		return buffer;
	}

	public static function getAnimationScalarFloatBufferByAccessor( l, accId ):Array<Float> {
		var acc = l.root.accessors[ accId ];
		var ct:ComponentType = acc.componentType;
		var count:Int = acc.count;
		var t:AccessorType = acc.type;
		if (t!=Scalar) throw "getAnimationScalarFloatBufferByAccessor called for '" + t + "' accessor. Not Scalar buffer type.";

		var bytes = getBufferBytesByAccessor( l, accId );
		var buffer = new Array<Float>();
		var bytePtr:BytePointer = { pos: 0 };

		var ctr = 0;
		while ( ctr++ < count ) {
			buffer.push( getFloat( ct, bytes, bytePtr ) );
		}
		return buffer;
	}

	public static function getAnimationFloatArrayBufferByAccessor( l, accId ):Array<Array<Float>> {

		var acc = l.root.accessors[ accId ];
		var ct:ComponentType = acc.componentType;
		var count:Int = acc.count;
		var t:AccessorType = acc.type;
		if (t!=Vec3 && t!=Vec4) throw "getAnimationScalarFloatBufferByAccessor called for '" + t + "' accessor. Not Scalar buffer type.";

		var bytes = getBufferBytesByAccessor( l, accId );
		var buffer = new Array<Array<Float>>();
		var bytePtr:BytePointer = { pos: 0 };

		var ctr = 0;
		var a:Array<Float>;
		while ( ctr++ < count ) {
			switch (t) {
				case Vec3: buffer.push( [ bytes.getFloat( bytePtr.pos ), bytes.getFloat( bytePtr.pos+4 ), bytes.getFloat( bytePtr.pos+8 ) ] ); bytePtr.pos+=12;
				case Vec4: buffer.push( [ getFloat( ct, bytes, bytePtr, true ), getFloat( ct, bytes, bytePtr, true ), getFloat( ct, bytes, bytePtr, true ), getFloat( ct, bytes, bytePtr, true ) ] );
				default:
					throw "Incorrect accessor type for getAnimationFloatArrayBufferByAccessor call (should be Vec3 or Vec4)";
			}
		}
		return buffer;
	}

	// var CTByte = 5120;
	// var CTUnsignedByte = 5121;
	// var CTShort = 5122;
	// var CTUnsignedShort = 5123;
	// var CTInt;
	// var CTUnsignedInt = 5125;
	// var CTFloat = 5126;

	static function getFloat(type, bytes, bytePtr, normalise = false) {
		var f:Float;
		switch (type) {
			case CTByte:
				f = normalise ? Math.max( bytes.get( bytePtr.pos ) / 127.0, -1) : bytes.get( bytePtr.pos );
				bytePtr.pos++;
			case CTUnsignedByte:
				f = normalise ? bytes.get( bytePtr.pos ) / 255.0 : bytes.get( bytePtr.pos );
				bytePtr.pos++;
			case CTShort:
				f = normalise ? Math.max( ((bytes.get( bytePtr.pos ) << 8) | bytes.get( bytePtr.pos+1 )) / 32767.0, -1) : ((bytes.get( bytePtr.pos ) << 8) | bytes.get( bytePtr.pos+1 ));
				bytePtr.pos += 2;
			case CTUnsignedShort : 
				f = normalise ? bytes.getUInt16( bytePtr.pos ) / 65535.0 : bytes.getUInt16( bytePtr.pos );
				bytePtr.pos += 2;
			case CTFloat :
				f = bytes.getFloat( bytePtr.pos );
				bytePtr.pos += 4;
			default:
				f = bytes.get( bytePtr.pos );
				bytePtr.pos++;
		}
		return f;
	}

	static function getInt(type, bytes, bytePtr) {
		var i:Int;
		switch (type) {
			case CTByte:
				i = bytes.get( bytePtr.pos );
				bytePtr.pos++;
			case CTUnsignedByte:
				i = bytes.get( bytePtr.pos );
				bytePtr.pos++;
			case CTShort:
				i = ((bytes.get( bytePtr.pos ) << 8) | bytes.get( bytePtr.pos+1 ));
				bytePtr.pos += 2;
			case CTUnsignedShort : 
				i = bytes.getUInt16( bytePtr.pos );
				bytePtr.pos += 2;
			case CTFloat :
				i = Std.int( bytes.getFloat( bytePtr.pos ) );
				bytePtr.pos += 4;
			default:
				i = bytes.get( bytePtr.pos );
				bytePtr.pos++;
		}
		return i;
	}

	public static function getMatrixArrayBufferByAccessor( l, accId ):Array<Matrix> {
		var acc = l.root.accessors[ accId ];
		var bvId = acc.bufferView;
		var ct:ComponentType = acc.componentType;
		var count:Int = acc.count;
		var t:AccessorType = acc.type;

		var bytes = getBufferBytesByAccessor( l, accId );
		var buffer = new Array<Matrix>();
		var bytePtr:BytePointer = { pos: 0 };

		var out:String = "";
		var ctr = 0;
		var m:Matrix;
		while ( ctr++ < count ) {
			switch (t) {
				case Mat4:
					m = new Matrix();
					m._11 = bytes.getFloat( bytePtr.pos );
					m._12 = bytes.getFloat( bytePtr.pos+4 );
					m._13 = bytes.getFloat( bytePtr.pos+8 );
					m._14 = bytes.getFloat( bytePtr.pos+12 );
					m._21 = bytes.getFloat( bytePtr.pos+16 );
					m._22 = bytes.getFloat( bytePtr.pos+20 );
					m._23 = bytes.getFloat( bytePtr.pos+24 );
					m._24 = bytes.getFloat( bytePtr.pos+28 );
					m._31 = bytes.getFloat( bytePtr.pos+32 );
					m._32 = bytes.getFloat( bytePtr.pos+36 );
					m._33 = bytes.getFloat( bytePtr.pos+40 );
					m._34 = bytes.getFloat( bytePtr.pos+44 );
					m._41 = bytes.getFloat( bytePtr.pos+48 );
					m._42 = bytes.getFloat( bytePtr.pos+52 );
					m._43 = bytes.getFloat( bytePtr.pos+56 );
					m._44 = bytes.getFloat( bytePtr.pos+60 );
					bytePtr.pos+=64;
					buffer.push( m ); 

					out += m;
				default:
					throw "Incorrect accessor type for getMatrixArrayBufferByAccessor call (should be Mat4)";
			}
		}
		#if debug_gltf
		trace("MatrixArray:Len="+buffer.length+"):\n"+out);
		#end

		return buffer;

	}

	public static function getBufferBytesByAccessor( l, accId ):Bytes {
		var acc = l.root.accessors[ accId ];
		var bvId = acc.bufferView;
		var ct:ComponentType = acc.componentType;
		var c:Int = acc.count;
		var t:AccessorType = acc.type;
		#if debug_gltf
		trace(" - getBufferBytesByAccessor:AccID="+accId+" componentType:"+t+" count:"+c+" type:"+t);
		#end
		return getBufferBytes( l, bvId, acc );
	}

	public static function getBufferBytes( l, bvId, acc = null):Bytes {
		var bv = l.root.bufferViews[ bvId ];
		var accOffset = acc==null ? 0 : (!Reflect.hasField( acc, "byteOffset") ? 0 : acc.byteOffset);
		var offset = !Reflect.hasField( bv, "byteOffset") ? 0 : bv.byteOffset;
		var stride = !Reflect.hasField( bv, "byteStride") ? 0 : bv.byteStride;
		var d = " - getBufferBytes:BvID="+bvId+" accOffset:"+accOffset+" byteOffset:"+offset+" byteStride:"+stride;
		
		var bytes:Bytes;
		var pos = 0;
		var srcpos = accOffset + offset;
		var buf = l.buffers[ bv.buffer ];
		var componentSize = 1;
		var componentCount = 1;
		if (acc != null) {
			switch (acc.componentType) {
				case CTShort | CTUnsignedShort : componentSize = 2;
				case CTFloat : componentSize = 4;
				default: componentSize = 1;
			}
			switch (acc.type) {
				case Vec2 : componentCount = 2;
				case Vec3 : componentCount = 3;
				case Vec4	| Mat2: componentCount = 4;
				case Mat3 : componentCount = 9;
				case Mat4 : componentCount = 16;
				default: componentCount = 1;
			}
		}
		d += " componentSize:"+componentSize+" componentCount:"+componentCount;

		if (acc == null || stride == 0) {
			var size = acc == null ? bv.byteLength : acc.count * componentSize * componentCount;
			bytes = Bytes.alloc( size );
			bytes.blit( pos, buf, srcpos, size);
			d += " blitting:"+size;
		} else {
			var stripLength = componentSize * componentCount;
			d += " stripLength:"+stripLength+" size="+(stripLength * acc.count);
			var ctr = 0;
			bytes = Bytes.alloc( stripLength * acc.count );
			while (ctr < acc.count) {
				bytes.blit( pos, buf, srcpos, stripLength);
				pos += stripLength;
				srcpos += stride;
				ctr++;
			}
		}
		#if debug_gltf
		trace(d);
		#end
		
		return bytes;
	}

}