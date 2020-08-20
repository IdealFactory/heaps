package h3d.shader.pbrsinglepass;

class AmbientMonochrome extends PBRSinglePassLib {

	static var SRC = {

        var ambientMonochrome:Float;
        var ambientOcclusionColor:Vec3;

        function fragment() {
            ambientMonochrome = getLuminance(ambientOcclusionColor); //float
        }
	}
}