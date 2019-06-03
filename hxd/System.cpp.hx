package hxd;

enum Platform {
	IOS;
	Android;
	WebGL;
	PC;
	Console;
	FlashPlayer;
}

enum SystemValue {
	IsTouch;
	IsWindowed;
	IsMobile;
}

class System {

	public static var width(get,never) : Int;
	public static var height(get, never) : Int;
	public static var lang(get, never) : String;
	public static var platform(get, never) : Platform;
	public static var screenDPI(get,never) : Float;
	public static var setCursor = setNativeCursor;

	/**
		Can be used to temporarly disable infinite loop check
	**/
	public static var allowTimeout(get, set) : Bool;

	/**
		If you have a time consuming calculus that might trigger a timeout, you can either disable timeouts with [allowTimeout] or call timeoutTick() frequently.
	**/
	public static function timeoutTick() : Void {
	}

	static var loopFunc : Void -> Void;

	public static function getCurrentLoop() : Void -> Void {
		return loopFunc;
	}

	public static function setLoop( f : Void -> Void ) : Void {
		loopFunc = f;
	}

	static function mainLoop() : Bool {
		// loop
		timeoutTick();
		if( loopFunc != null ) loopFunc();

		// present
		var cur = h3d.Engine.getCurrent();
		if( cur != null && cur.ready ) cur.driver.present();
		return true;
	}


	public static function start( init : Void -> Void ) : Void {
		trace('start');
		var width = 800;
		var height = 600;
		var size = haxe.macro.Compiler.getDefine("windowSize");
		var title = haxe.macro.Compiler.getDefine("windowTitle");
		if( title == null )
			title = "";
		if( size != null ) {
			var p = size.split("x");
			width = Std.parseInt(p[0]);
			height = Std.parseInt(p[1]);
		}

		@:privateAccess Stage.inst = new Stage(title, width, height);
		trace('about to call init()');
		init();

		#if lime
		runMainLoop();
		#else
		haxe.Timer.delay(runMainLoop, 0);
		#end
	}

	static function runMainLoop() {
		trace('runMainLoop');
		@:privateAccess Stage.inst.execLimeApp();
		Sys.exit(0);
	}


	public static function setNativeCursor( c : Cursor ) : Void {
	}

	public static function getDeviceName() : String {
		return "Unknown";
	}

	public static function getDefaultFrameRate() : Float {
		return 60.;
	}

	public static function getValue( s : SystemValue ) : Bool {
		return false;
	}

	public static function exit() : Void {
	}

	// getters

	static function get_width() : Int return Stage.getInstance().limeApp.window.width;
	static function get_height() : Int return Stage.getInstance().limeApp.window.height;
	static function get_lang() : String return "en";
	static function get_platform() : Platform return PC;
	static function get_screenDPI() : Int return 72;
	static function get_allowTimeout() return false;
	static function set_allowTimeout(b) return false;

}

