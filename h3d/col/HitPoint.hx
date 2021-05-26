package h3d.col;

typedef HitInfo = {
	var hit:Float;
    var i0:Int;
	var p0:FPoint;
	var i1:Int;
	var p1:FPoint;
	var i2:Int;
	var p2:FPoint;
	var s0:FPoint;
    var s1:FPoint;
    var n:FPoint;
    var p:FPoint;
    var c:FPoint;
	var u:Float;
	var v:Float;
}

abstract HitPoint(HitInfo) from HitInfo to HitInfo {

	public var hit(get,set):Float;
    public var i0(get,set):Int;
	public var p0(get,set):FPoint;
	public var i1(get,set):Int;
	public var p1(get,set):FPoint;
	public var i2(get,set):Int;
	public var p2(get,set):FPoint;
	public var s0(get,set):FPoint;
	public var s1(get,set):FPoint;
	public var n(get,set):FPoint;
	public var p(get,set):FPoint;
	public var c(get,set):FPoint;
	public var u(get,set):Float;
	public var v(get,set):Float;

    public function new( ?hitValue:Null<Float> ) {
        this = {
            hit : hitValue==null ? Math.NEGATIVE_INFINITY : hitValue,
            i0 : -1,
            i1 : -1,
            i2 : -1,
            p0 : null,
            p1 : null,
            p2 : null,
            s0 : null,
            s1 : null,
            n : null,
            p : null,
            c : null,
            u : 0,
            v : 0,
        };
    }

    public function clone( dest:HitPoint = null) : HitPoint {
        if (this==null) return null;
        var h = (dest == null ? new HitPoint(hit) : dest);
        h.i0 = i0;
        h.i1 = i1;
        h.i2 = i2;
        h.p0 = p0;
        h.p1 = p1;
        h.p2 = p2;
        h.s0 = s0;
        h.s1 = s1;
        h.n = n;
        h.p = p;
        h.c = c;
        h.u = u;
        h.v = v;
        return h;
    }

    public function updateHit( v:Float ) : HitPoint {
        this.hit = v;
        return this;
    }

    inline function get_hit():Float { return this.hit; }
    inline function set_hit(v:Float):Float { this.hit = v; return v; }
    inline function get_i0():Int { return this.i0; }
    inline function set_i0(v:Int):Int { this.i0 = v; return v; }
	inline function get_p0():FPoint { return this.p0; }
	inline function set_p0(v:FPoint):FPoint { this.p0 = v; return v; }
	inline function get_i1():Int { return this.i1; }
	inline function set_i1(v:Int):Int { this.i2 = v; return v; }
	inline function get_p1():FPoint { return this.p1; }
	inline function set_p1(v:FPoint):FPoint { this.p1 = v; return v; }
	inline function get_i2():Int { return this.i2; }
	inline function set_i2(v:Int):Int { this.i2 = v; return v; }
	inline function get_p2():FPoint { return this.p2; }
	inline function set_p2(v:FPoint):FPoint { this.p2 = v; return v; }
	inline function get_s0():FPoint { return this.s0; }
	inline function set_s0(v:FPoint):FPoint { this.s0 = v; return v; }
	inline function get_s1():FPoint { return this.s1; }
	inline function set_s1(v:FPoint):FPoint { this.s1 = v; return v; }
	inline function get_n():FPoint { return this.n; }
	inline function set_n(v:FPoint):FPoint { this.n = v; return v; }
	inline function get_p():FPoint { return this.p; }
	inline function set_p(v:FPoint):FPoint { this.p = v; return v; }
	inline function get_c():FPoint { return this.c; }
	inline function set_c(v:FPoint):FPoint { this.c = v; return v; }
	inline function get_u():Float { return this.u; }
	inline function set_u(v:Float):Float { this.u = v; return v; }
	inline function get_v():Float { return this.v; }
	inline function set_v(v:Float):Float { this.v = v; return v; }

    @:op(A == B) public function equals(other:HitPoint) { return this.hit == other.hit; }
    @:op(A < B) public function lessThan(other:HitPoint) { return this.hit < other.hit; }
    @:op(A > B) public function greaterThan(other:HitPoint) { return this.hit > other.hit; }
    @:op(A <= B) public function lessThanEqual(other:HitPoint) { return this.hit <= other.hit; }
    @:op(A >= B) public function greaterThanEqual(other:HitPoint) { return this.hit >= other.hit; }

    @:op(A == B) public function equalsI(other:Int) { return this.hit == other; }
    @:op(A < B) public function lessThanI(other:Int) { return this.hit < other; }
    @:op(A > B) public function greaterThanI(other:Int) { return this.hit > other; }
    @:op(A <= B) public function lessThanEqualI(other:Int) { return this.hit <= other; }
    @:op(A >= B) public function greaterThanEqualI(other:Int) { return this.hit >= other; }

    @:op(A == B) public function equalsF(other:Float) { return this.hit == other; }
    @:op(A < B) public function lessThanF(other:Float) { return this.hit < other; }
    @:op(A > B) public function greaterThanF(other:Float) { return this.hit > other; }
    @:op(A <= B) public function lessThanEqualF(other:Float) { return this.hit <= other; }
    @:op(A >= B) public function greaterThanEqualF(other:Float) { return this.hit >= other; }

    public function toString() : String {
        if ( this == null) return "HitPoint(null)";
		return "HitPoint(hit=" + hit + " i0:" + i0 + " i1:" + i1 + " i2:" + i2 + " uv:" + u + "/" + v + ")";
	}
}