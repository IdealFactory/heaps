package hxd;

import hxd.impl.MouseMode;

enum DisplayMode {
	Windowed;
	Borderless;
	Fullscreen;
	FullscreenResize;
}

class Window {

	var resizeEvents : List<Void -> Void>;
	var eventTargets : List<Event -> Void>;

	public var width(get, never) : Int;
	public var height(get, never) : Int;
	public var mouseX(get, never) : Int;
	public var mouseY(get, never) : Int;
	@:deprecated("Use mouseMode = AbsoluteUnbound(true)")
	public var mouseLock(get, set) : Bool;
	public var mouseClip(get, set) : Bool;
	public var mouseMode(default, set) : MouseMode = Absolute;
	public var vsync(get, set) : Bool;
	public var isFocused(get, never) : Bool;

	public var title(get, set) : String;
	public var displayMode(get, set) : DisplayMode;

	#if lime
	public static var CURRENT:lime.app.Application;
	#end

	#if openfl
	var openFLMouseX : Float = 0.;
	var openFLMouseY : Float = 0.;
	#end


	public var limeApp: lime.app.Application;
	var windowWidth = 800;
	var windowHeight = 600;

	function new(title:String, width:Int, height:Int) : Void {
		eventTargets = new List();
		resizeEvents = new List();
		this.windowWidth = width;
		this.windowHeight = height;
		
		if (CURRENT == null) {
			limeApp = new LimeApp(this, width, height);
		} else {
			limeApp = CURRENT;
			this.windowWidth = CURRENT.window.width;
			this.windowHeight = CURRENT.window.height;
		}
		
	}

	public function execLimeApp() {
		limeApp.exec();
	}

	public dynamic function onClose() : Bool {
		return true;
	}

	public function event( e : hxd.Event ) : Void {
		for( et in eventTargets )
			et(e);
	}

	public function addEventTarget( et : Event->Void ) : Void {
		eventTargets.add(et);
	}

	public function removeEventTarget( et : Event->Void ) : Void {
		for( e in eventTargets )
			if( Reflect.compareMethods(e,et) ) {
				eventTargets.remove(e);
				break;
			}
	}

	public function addResizeEvent( f : Void -> Void ) : Void {
		resizeEvents.push(f);
	}

	public function removeResizeEvent( f : Void -> Void ) : Void {
		for( e in resizeEvents )
			if( Reflect.compareMethods(e,f) ) {
				resizeEvents.remove(f);
				break;
			}
	}

	function onResize(e:Dynamic) : Void {
		for( r in resizeEvents )
			r();
	}

	public function resize( width : Int, height : Int ) : Void {
	}

	public function setFullScreen( v : Bool ) : Void {
	}

	static var inst : Window = null;
	public static function getInstance() : Window {
		return inst;
	}

	function get_mouseX() : Int {
		return 0;
	}

	function get_mouseY() : Int {
		return 0;
	}

	function get_width() : Int {
		return windowWidth;
	}

	function get_height() : Int {
		return windowHeight;
	}

	public dynamic function onMouseModeChange( from : MouseMode, to : MouseMode ) : Null<MouseMode> {
		return null;
	}

	public function setCursorPos( x : Int, y : Int, emitEvent : Bool = false ) : Void {
		if( mouseMode == Absolute && limeApp.window != null ) limeApp.window.warpMouse(x, y);
		if( emitEvent ) event(new hxd.Event(EMove, x, y));
	}

	function get_mouseLock() : Bool {
		return switch( mouseMode ) { case AbsoluteUnbound(_): true; default: false; };
	}

	function set_mouseLock( v : Bool ) : Bool {
		return set_mouseMode(v ? AbsoluteUnbound(true) : Absolute).equals(AbsoluteUnbound(true));
	}

	function get_mouseClip() : Bool {
		return false;
	}

	function set_mouseClip( v : Bool ) : Bool {
		if( v ) throw "Can't clip cursor on this platform.";
		return false;
	}

	function set_mouseMode( v : MouseMode ) : MouseMode {
		if( v.equals(mouseMode) ) return v;

		var forced = onMouseModeChange(mouseMode, v);
		if( forced != null ) v = forced;

		if( limeApp.window != null ) limeApp.window.mouseLock = v != Absolute;
		return mouseMode = v;
	}

	function get_vsync() : Bool return true;

	function set_vsync( b : Bool ) : Bool {
		if( !b ) throw "Can't disable vsync on this platform";
		return true;
	}

	function get_isFocused() : Bool return true;

	function get_displayMode() : DisplayMode {
		return Windowed;
	}
	function set_displayMode( m : DisplayMode ) : DisplayMode {
		return m;
	}

	function get_title() : String {
		return "";
	}
	function set_title( t : String ) : String {
		return t;
	}

}

class LimeApp extends lime.app.Application {
	private var parentWindow: Window;

	public function new(window: Window, width: Int, height: Int) {
		super();
		this.parentWindow = window;
		createWindow ({ width: width, height: height });
	}

	public override function update (deltaTime:Int) {
		@:privateAccess System.mainLoop();
	}
	public override function render (context:lime.graphics.RenderContext):Void {
    }
}
