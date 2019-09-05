package h3d.shader;

class Emissive extends hxsl.Shader {

	static var SRC = {
		var pixelColor : Vec4;
		@param var emissive : Vec3;

		function fragment() {
			pixelColor.rgb += pixelColor.rgb * emissive.rgb;
		}

	};
}