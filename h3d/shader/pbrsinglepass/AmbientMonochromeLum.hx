package h3d.shader.pbrsinglepass;

class AmbientMonochromeLum extends PBRSinglePassLib {

	static var SRC = {

        var ambientMonochrome:Float;
        var ambientOcclusionColor:Vec3;

        function fragment() {
            ambientMonochrome = ambientOcclusionColor.r; //float
        }
	}
}