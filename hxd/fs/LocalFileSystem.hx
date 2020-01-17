package hxd.fs;

#if (sys || nodejs)

@:allow(hxd.fs.LocalFileSystem)
@:allow(hxd.fs.FileConverter)
@:access(hxd.fs.LocalFileSystem)
class LocalEntry extends FileEntry {

	var fs : LocalFileSystem;
	var relPath : String;
	var file : String;
	var originalFile : String;
	var fread : sys.io.FileInput;

	function new(fs, name, relPath, file) {
		this.fs = fs;
		this.name = name;
		this.relPath = relPath;
		this.file = file;
	}

	override function getSign() : Int {
		var old = if( fread == null ) -1 else fread.tell();
		open();
		var i = fread.readInt32();
		if( old < 0 ) close() else fread.seek(old, SeekBegin);
		return i;
	}

	override function getBytes() : haxe.io.Bytes {
		return sys.io.File.getBytes(file);
	}

	override function open() {
		if( fread != null )
			fread.seek(0, SeekBegin);
		else
			fread = sys.io.File.read(file);
	}

	override function skip(nbytes:Int) {
		fread.seek(nbytes, SeekCur);
	}

	override function readByte() {
		return fread.readByte();
	}

	override function read( out : haxe.io.Bytes, pos : Int, size : Int ) : Void {
		fread.readFullBytes(out, pos, size);
	}

	override function close() {
		if( fread != null ) {
			fread.close();
			fread = null;
		}
	}

	var isDirCached : Null<Bool>;
	override function get_isDirectory() : Bool {
		if( isDirCached != null ) return isDirCached;
		return isDirCached = sys.FileSystem.isDirectory(file);
	}

	override function load( ?onReady : Void -> Void ) : Void {
		#if macro
		onReady();
		#else
		if( onReady != null ) haxe.Timer.delay(onReady, 1);
		#end
	}

	override function loadBitmap( onLoaded : hxd.fs.LoadedBitmap -> Void ) : Void {
		#if js
		var image = new js.html.Image();
		image.onload = function(_) {
			onLoaded(new LoadedBitmap(image));
		};
		image.src = "file://"+file;
		#elseif (macro || dataOnly)
		throw "Not implemented";
		#elseif lime
		lime.graphics.Image.loadFromFile(file).onComplete(function(image) {
    		onLoaded(new LoadedBitmap(image));
		});
		#else
		var bmp = new hxd.res.Image(this).toBitmap();
		onLoaded(new hxd.fs.LoadedBitmap(bmp));
		#end
	}

	override function get_path() {
		return relPath == null ? "<root>" : relPath;
	}

	override function exists( name : String ) {
		return fs.exists(relPath == null ? name : relPath + "/" + name);
	}

	override function get( name : String ) {
		return fs.get(relPath == null ? name : relPath + "/" + name);
	}

	override function get_size() {
		return sys.FileSystem.stat(file).size;
	}

	override function iterator() {
		var arr = new Array<FileEntry>();
		for( f in sys.FileSystem.readDirectory(file) ) {
			switch( f ) {
			case ".svn", ".git" if( sys.FileSystem.isDirectory(file+"/"+f) ):
				continue;
			case ".tmp" if( this == fs.root ):
				continue;
			default:
				arr.push(fs.open(relPath == null ? f : relPath + "/" + f,false));
			}
		}
		return new hxd.impl.ArrayIterator(arr);
	}

	var watchCallback : Void -> Void;
	var watchTime : Float;

	static var WATCH_INDEX = 0;
	static var WATCH_LIST : Array<LocalEntry> = null;
	static var tmpDir : String = null;

	inline function getModifTime(){
		return sys.FileSystem.stat(originalFile != null ? originalFile : file).mtime.getTime();
	}

	static function checkFiles() {
		var w = WATCH_LIST[WATCH_INDEX++];
		if( w == null ) {
			WATCH_INDEX = 0;
			return;
		}
		var t = try w.getModifTime() catch( e : Dynamic ) -1.;
		if( t == w.watchTime ) return;

		#if sys
		if( tmpDir == null ) {
			tmpDir = Sys.getEnv("TEMP");
			if( tmpDir == null ) tmpDir = Sys.getEnv("TMPDIR");
			if( tmpDir == null ) tmpDir = Sys.getEnv("TMP");
		}
		var lockFile = tmpDir+"/"+w.file.split("/").pop()+".lock";
		if( sys.FileSystem.exists(lockFile) ) return;
		if( !w.isDirectory )
		try {
			var fp = sys.io.File.append(w.file);
			fp.close();
		}catch( e : Dynamic ) return;
		#end

		w.watchTime = t;
		w.watchCallback();
	}

	override function watch( onChanged : Null < Void -> Void > ) {
		if( onChanged == null ) {
			if( watchCallback != null ) {
				WATCH_LIST.remove(this);
				watchCallback = null;
			}
			return;
		}
		if( watchCallback == null ) {
			if( WATCH_LIST == null ) {
				WATCH_LIST = [];
				#if !macro
				haxe.MainLoop.add(checkFiles);
				#end
			}
			var path = path;
			for( w in WATCH_LIST )
				if( w.path == path ) {
					w.watchCallback = null;
					WATCH_LIST.remove(w);
				}
			WATCH_LIST.push(this);
		}
		watchTime = getModifTime();
		watchCallback = function() { fs.convert.run(this); onChanged(); }
	}

}

class LocalFileSystem implements FileSystem {

	var root : FileEntry;
	var fileCache = new Map<String,{r:LocalEntry}>();
	public var baseDir(default,null) : String;
	public var convert(default,null) : FileConverter;
	static var isWindows = Sys.systemName() == "Windows";

	public function new( dir : String, configuration : String ) {
		baseDir = dir;
		if( configuration == null )
			configuration = "default";

		#if (macro && haxe_ver >= 4.0)
		var exePath = null;
		#elseif (haxe_ver >= 3.3)
		var pr = Sys.programPath();
		var exePath = pr == null ? null : pr.split("\\").join("/").split("/");
		#else
		var exePath = Sys.executablePath().split("\\").join("/").split("/");
		#end

		if( exePath != null ) exePath.pop();
		var froot = exePath == null ? baseDir : sys.FileSystem.fullPath(exePath.join("/") + "/" + baseDir);
		if( froot == null || !sys.FileSystem.exists(froot) || !sys.FileSystem.isDirectory(froot) ) {
			froot = sys.FileSystem.fullPath(baseDir);
			if( froot == null || !sys.FileSystem.exists(froot) || !sys.FileSystem.isDirectory(froot) )
				throw "Could not find dir " + dir;
		}
		baseDir = froot.split("\\").join("/");
		if( !StringTools.endsWith(baseDir, "/") ) baseDir += "/";
		convert = new FileConverter(baseDir, configuration);
		root = new LocalEntry(this, "root", null, baseDir);
	}

	public function getAbsolutePath( f : FileEntry ) : String {
		var f = cast(f, LocalEntry);
		return f.file;
	}

	public function getRoot() : FileEntry {
		return root;
	}

	var directoryCache : Map<String,Map<String,Bool>> = new Map();

	function checkPath( path : String ) {
		// make sure the file is loaded with correct case !
		var baseDir = new haxe.io.Path(path).dir;
		var c = directoryCache.get(baseDir);
		var isNew = false;
		if( c == null ) {
			isNew = true;
			c = new Map();
			for( f in try sys.FileSystem.readDirectory(baseDir) catch( e : Dynamic ) [] )
				c.set(f, true);
			directoryCache.set(baseDir, c);
		}
		if( !c.exists(path.substr(baseDir.length+1)) ) {
			// added since then?
			if( !isNew ) {
				directoryCache.remove(baseDir);
				return checkPath(path);
			}
			return false;
		}
		return true;
	}

	function open( path : String, check = true ) {
		var r = fileCache.get(path);
		if( r != null )
			return r.r;
		var e = null;
		var f = sys.FileSystem.fullPath(baseDir + path);
		if( f == null )
			return null;
		f = f.split("\\").join("/");
		if( !check || ((!isWindows || (isWindows && f == baseDir + path)) && sys.FileSystem.exists(f) && checkPath(f)) ) {
			e = new LocalEntry(this, path.split("/").pop(), path, f);
			convert.run(e);
			if( e.file == null ) e = null;
		}
		fileCache.set(path, {r:e});
		return e;
	}

	public function clearCache() {
		for( path in fileCache.keys() ) {
			var r = fileCache.get(path);
			if( r.r == null ) fileCache.remove(path);
		}
	}

	public function exists( path : String ) {
		var f = open(path);
		return f != null;
	}

	public function get( path : String ) {
		var f = open(path);
		if( f == null )
			throw new NotFound(path);
		return f;
	}

	public function dispose() {
		fileCache = new Map();
	}

	public function dir( path : String ) : Array<FileEntry> {
		if( !sys.FileSystem.exists(baseDir + path) || !sys.FileSystem.isDirectory(baseDir + path) )
			throw new NotFound(baseDir + path);
		var files = sys.FileSystem.readDirectory(baseDir + path);
		var r : Array<FileEntry> = [];
		for(f in files)
			r.push(open(path + "/" + f, false));
		return r;
	}

}

#else

class LocalFileSystem implements FileSystem {

	public var baseDir(default,null) : String;

	public function new( dir : String ) {
		#if flash
		if( flash.system.Capabilities.playerType == "Desktop" )
			throw "Please compile with -lib air3";
		#end
		throw "Local file system is not supported for this platform";
	}

	public function exists(path:String) {
		return false;
	}

	public function get(path:String) : FileEntry {
		return null;
	}

	public function getRoot() : FileEntry {
		return null;
	}

	public function dispose() {
	}

	public function dir( path : String ) : Array<FileEntry> {
		return null;
	}
}

#end
