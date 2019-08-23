package hxd.fmt.gltf;
import haxe.io.Bytes;

class DataURIEntry extends hxd.fs.FileEntry {

	// public var bytes(get, set):Bytes;
	// function get_bytes():Bytes { return _bytes; }
	// function set_bytes( b:Bytes ):Bytes {
	// 	trace("Setting Bytes:"+(b!=null ? ""+b.length : "null"));
	// 	_bytes = b;
	// 	return b;
	// }
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
		this.bytes = bytes;
	}

	override function getSign() : Int {
		#if flash
		var old = bytes == null ? 0 : bytes.position;
		open();
		bytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
		var v = bytes.readUnsignedInt();
		bytes.position = old;
		return v;
		#else
		var old = readPos;
		open();
		readPos = old;
		return bytes.get(0) | (bytes.get(1) << 8) | (bytes.get(2) << 16) | (bytes.get(3) << 24);
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

	// override function close() {
	// 	#if flash
	// 	bytes = null;
	// 	#else
	// 	bytes = null;
	// 	readPos = 0;
	// 	#end
	// }

	// override function loadBitmap( onLoaded : LoadedBitmap -> Void ) : Void {
	// 	#if flash
	// 	var loader = new flash.display.Loader();
	// 	loader.contentLoaderInfo.addEventListener(flash.events.IOErrorEvent.IO_ERROR, function(e:flash.events.IOErrorEvent) {
	// 		throw Std.string(e) + " while loading " + relPath;
	// 	});
	// 	loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_) {
	// 		var content : flash.display.Bitmap = cast loader.content;
	// 		// onLoaded(new LoadedBitmap(content.bitmapData));
	// 		loader.unload();
	// 	});
	// 	loader.loadBytes(bytes);
	// 	close(); // flash will copy bytes content in loadBytes() !
	// 	#elseif lime
	// 	onLoaded( new LoadedBitmap(lime.graphics.Image.fromBytes(bytes)) );
	// 	#elseif js
	// 	// directly get the base64 encoded data from resources
	// 	image.src = data;
	// 	#else
	// 	throw "TODO";
	// 	#end
	// }

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
