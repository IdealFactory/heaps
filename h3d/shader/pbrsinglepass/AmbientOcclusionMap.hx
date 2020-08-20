package h3d.shader.pbrsinglepass;

class AmbientOcclusionMap extends PBRSinglePassLib {

	static var SRC = {

        @param var ambientSampler : Sampler2D;
        
        var uvOffset:Vec2;

        var ambientOcclusionColor:Vec3;
        var ambientOcclusionForDirectDiffuse:Vec3;

        function fragment() {
            ambientOcclusionColor = vec3(1., 1., 1.); //vec3
 
            var ambientOcclusionColorMap = ambientSampler.get(vMainUV1 + uvOffset).rgb * vec3(vAmbientInfos.y); //vec3 // vAmbientUV -> vMainUV1
            ambientOcclusionColorMap = vec3(ambientOcclusionColorMap.r, ambientOcclusionColorMap.r, ambientOcclusionColorMap.r);
            ambientOcclusionColor = mix(ambientOcclusionColor, ambientOcclusionColorMap, vAmbientInfos.z);
            ambientOcclusionForDirectDiffuse = mix(vec3(1.), ambientOcclusionColor, vAmbientInfos.w); //vec3
         }
    }
}