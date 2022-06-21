package h3d.shader;

class ColorTransform extends hxsl.Shader {

	static var SRC = {
		var pixelColor : Vec4;

		@param var colorOffset : Vec4;
		@param var colorMultiplier : Vec4;

		var output : {
			var color : Vec4;
		};

		function fragment() {
			// old = (old value * Multiplier) + Offset
			// output.color = (pixelColor * colorMultiplier) + (colorOffset / 255.0);
		}

	};

	public function new() {
		super();
		this.colorOffset.set( 0, 0, 0, 0 );
		this.colorMultiplier.set( 1, 1, 1, 1 );
	}
}