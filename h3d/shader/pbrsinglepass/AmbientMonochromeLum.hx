package h3d.shader.pbrsinglepass;

class AmbientMonochromeLum extends PBRSinglePassLib {

	static var SRC = {

        // @keep var ambientMonochrome:Float;

        function fragment() {
            // ambientMonochrome = ambientOcclusionColor.r; //float

            glslsource("
    // AmbientMonochromeLum fragment
    // float ambientMonochrome = getLuminance(aoOut.ambientOcclusionColor);
    float ambientMonochrome = aoOut.ambientOcclusionColor.r;
");
        }
	}
}