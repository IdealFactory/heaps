package h3d.shader.pbrsinglepass;

class AmbientMonochrome extends PBRSinglePassLib {

	static var SRC = {

        // @keep var ambientMonochrome:Float;
        // @keep var ambientOcclusionColor:Vec3;

        function fragment() {
            // ambientMonochrome = getLuminance(ambientOcclusionColor); //float

            glslsource("
    // AmbientMonochrome fragment
    float ambientMonochrome = getLuminance(ambientOcclusionColor);
");
        }
	}
}