package hxd.impl;

private typedef InnerData = #if lime lime.utils.UInt8Array #elseif hl hl.Bytes #elseif js TypedArray.Uint8Array #else haxe.io.BytesData #end

abstract UncheckedBytes(InnerData) {

	inline function new(v) {
		this = v;
	}

	@:arrayAccess inline function get( i : Int ) : Int {
		return this[i];
	}

	@:arrayAccess inline function set( i : Int, v : Int ) : Int {
		this[i] = v;
		return v;
	}

	@:from public static inline function fromBytes( b : haxe.io.Bytes ) : UncheckedBytes {
		#if lime
		return new UncheckedBytes(lime.utils.UInt8Array.fromBytes( b ));
		#elseif hl
		return new UncheckedBytes(b);
		#elseif js
		return new UncheckedBytes(@:privateAccess b.b);
		#else
		return new UncheckedBytes(b.getData());
		#end
	}

}