package hxd.fmt.gltf;

import haxe.Json;
import haxe.io.Bytes;
import hxd.fmt.gltf.Data;

class Parser {
	
	public static function parse( data : Bytes, loadBuffer:String->Bytes ) : GltfContainer {
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
				} else {
					bin.push( loadBuffer(buf.uri) );
				}
				var bI = bin.length - 1;
				var out = "";
				for (i in 0...255) out += StringTools.hex(bin[bI].get(i), 2)+" ";
				trace("Buffer URI:"+(StringTools.startsWith(buf.uri, "data:") ? buf.uri.substr(0, 100)+"..." : buf.uri)+" len="+bin[bI].length+"\nData="+out);
			}
		}

		return { header: gltf, buffers: bin };

	}

}