package h3d.shader.pbrsinglepass;

class AmbientOcclusionMap extends PBRSinglePassLib {

	static var SRC = {

        @keep @param var ambientSampler : Sampler2D;
                
        @keep var ambientOcclusionColor:Vec3;
        @keep var ambientOcclusionForDirectDiffuse:Vec3;

        fragfunction("ambientOcclusionOutParamsDefine",
"#define vAmbientUV vMainUV1");

        fragfunction("ambientOcclusionOutParams",
"struct ambientOcclusionOutParams {
    vec3 ambientOcclusionColor;
    vec3 ambientOcclusionColorMap;
};");
                                    
        fragfunction("ambientOcclusionBlock",
"void ambientOcclusionBlock(
in vec3 ambientOcclusionColorMap_, in vec4 vAmbientInfos, out ambientOcclusionOutParams outParams
) {
    vec3 ambientOcclusionColor = vec3(1., 1., 1.);
    vec3 ambientOcclusionColorMap = ambientOcclusionColorMap_*vAmbientInfos.y;
    ambientOcclusionColorMap = vec3(ambientOcclusionColorMap.r, ambientOcclusionColorMap.r, ambientOcclusionColorMap.r);
    ambientOcclusionColor = mix(ambientOcclusionColor, ambientOcclusionColorMap, vAmbientInfos.z);
    outParams.ambientOcclusionColor = ambientOcclusionColor;
}
");
    
        function fragment() {
            // ambientOcclusionColor = vec3(1., 1., 1.); //vec3
 
            // var ambientOcclusionColorMap = ambientSampler.get(vMainUV1 + uvOffset).rgb * vec3(vAmbientInfos.y); //vec3 // vAmbientUV -> vMainUV1
            // ambientOcclusionColorMap = vec3(ambientOcclusionColorMap.r, ambientOcclusionColorMap.r, ambientOcclusionColorMap.r);
            // ambientOcclusionColor = mix(ambientOcclusionColor, ambientOcclusionColorMap, vAmbientInfos.z);
            // ambientOcclusionForDirectDiffuse = mix(vec3(1.), ambientOcclusionColor, vAmbientInfos.w); //vec3

            glslsource("
    // AmbientOcclusionMap fragment
    vec3 ambientOcclusionColorMap = texture(ambientSampler, vAmbientUV+uvOffset).rgb;
    ambientOcclusionOutParams aoOut;
    ambientOcclusionBlock(
    ambientOcclusionColorMap, vAmbientInfos, aoOut
    );
");
         }
    }
}