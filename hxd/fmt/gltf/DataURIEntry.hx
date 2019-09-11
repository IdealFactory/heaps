package hxd.fmt.gltf;

import haxe.io.Bytes;

class DataURIEntry extends hxd.fs.FileEntry {

    var data : String;
	#if flash
	var bytes : flash.utils.ByteArray;
	#else
	var bytes : haxe.io.Bytes;
	var readPos : Int = 0;
	#end

	public function new(name, data, bytes) {
		this.name = name;
        this.data = data;
		var dataString = data.substr( data.indexOf(",")+1 );
		this.bytes = #if !flash bytes #else bytes.getData() #end;
		#if flash
		this.bytes.position = 0;
		#end
	}

	override function getBytes() : haxe.io.Bytes {
		#if flash
		return haxe.io.Bytes.ofData(bytes);
		#else
		return bytes;
		#end
	}

	override function skip( nbytes : Int ) {
		#if flash
		bytes.position += nbytes;
		#else
		readPos += nbytes;
		#end
	}

	override function readByte() : Int {
		#if flash
		return bytes.readUnsignedByte();
		#else
		return bytes.get(readPos++);
		#end
	}

	override function read( out : haxe.io.Bytes, pos : Int, size : Int ) : Void {
		#if flash
		bytes.readBytes(out.getData(), pos, size);
		#else
		out.blit(pos, bytes, readPos, size);
		readPos += size;
		#end
	}

	override function get_path() : String { return "path-"+name; };

	override function get_size() {
		#if flash
		return bytes.length;
		#else
		return bytes.length;
		#end
	}

	public function getBitmapData() {

	}
}
