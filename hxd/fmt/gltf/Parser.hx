package hxd.fmt.gltf;

import haxe.Json;
import haxe.io.Bytes;
import hxd.fmt.gltf.Data;

class Parser {
	
	public static function parse( data : Bytes, loadBuffer ) : GltfContainer {
		var gltf : Gltf = null;
		var bin:Array<Bytes> = new Array();
		if ( bin == null ) new Array();
		if ( data.getInt32(0) == 0x46546C67 ) {
			// binary glb
			if ( data.getInt32(4) != 2 ) throw "Invalid GLB version!";
			if ( data.getInt32(8) != data.length ) throw "GLB file size mismatch!";

			var pos = 12;
			while ( pos < data.length ) {
				var length = data.getInt32(pos);
				var type = data.getInt32(pos+4);
				pos += 8;
				switch ( type ) {
					case 0x4E4F534A: gltf = Json.parse(data.getString(pos, length, UTF8));
					case 0x004E4942: bin.push(data.sub(pos, length));
					default: // extension
				}
				var align = 4 - (length % 4);

				pos += length + (align == 4 ? 0 : align); // 4-byte alignment
			}
		} else {
			gltf = Json.parse(data.toString());
		}
		
		if ( bin.length == 0 && gltf != null && gltf.buffers != null ) {
			for ( buf in gltf.buffers ) {
				if ( StringTools.startsWith(buf.uri, "data:") ) {
					bin.push( haxe.crypto.Base64.decode( buf.uri.substr( buf.uri.indexOf(",")+1)) );
					#if debug_gltf
					trace("Buffer URI:"+buf.uri.substr(0, 100)+"...");
					debugBuffer( bin[bin.length-1] );
					#end
				} else {
					#if debug_gltf
					trace("Buffer URI:"+buf.uri);
					#end
					loadBuffer(buf.uri, bytesLoaded, bin, bin.length);
				}
			}
		}

		return { header: gltf, buffers: bin };

	}

	static function bytesLoaded( bytes:Bytes, bin:Array<Bytes>, idx:Int ) {
		bin[idx] = bytes;
		#if debug_gltf debugBuffer( bytes ); #end
	}

	#if debug_gltf
	static function debugBuffer( bytes:Bytes ) {
		var out = "";
		for (i in 0...64) out += StringTools.hex(bytes.get(i), 2)+" ";
		trace(" - data len="+bytes.length+"\nData="+out);
	}
	#end
}