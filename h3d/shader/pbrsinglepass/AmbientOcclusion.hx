package h3d.shader.pbrsinglepass;

class AmbientOcclusion extends PBRSinglePassLib {

	static var SRC = {

        //@keep var ambientOcclusionColor:Vec3;
        @keep var ambientInfos:Vec4;
        @keep var ambientOcclusionForDirectDiffuse:Vec3;

        fragfunction("ambientOcclusionOutParams",
"struct ambientOcclusionOutParams {
    vec3 ambientOcclusionColor;
};");
                                    
        fragfunction("ambientOcclusionBlock",
"void ambientOcclusionBlock(
out ambientOcclusionOutParams outParams
) {
    vec3 ambientOcclusionColor = vec3(1., 1., 1.);
    outParams.ambientOcclusionColor = ambientOcclusionColor;
}");
 
        function __init__fragment() {
            glslsource("// AmbientOcclusion __init__fragment");

            // ambientOcclusionColor = vec3(1., 1., 1.); //vec3
            vAmbientInfos = uAmbientInfos;
        }

        function fragment() {
            // ambientInfos = vAmbientInfos;
            // ambientOcclusionForDirectDiffuse = ambientOcclusionColor; 

            glslsource("
    // AmbientOcclusion fragment
    ambientOcclusionOutParams aoOut;
    ambientOcclusionBlock(
    aoOut
    );
");
        }
	}
}