package h3d.shader.pbrsinglepass;

class AmbientOcclusionMap extends hxsl.Shader {

	static var SRC = {

        @param var ambientSampler : Sampler2D;
        
        @var var vMainUV1 : Vec2;

        var uvOffset:Vec2;

        var ambientOcclusionColor:Vec3;
        var ambientInfos:Vec4;
        var ambientOcclusionForDirectDiffuse:Vec3;

        function fragment() {
            var ambientOcclusionColorMap = ambientSampler.get(vMainUV1 + uvOffset).rgb * ambientInfos.y; //vec3 // vAmbientUV -> vMainUV1
            ambientOcclusionColorMap = vec3(ambientOcclusionColorMap.r, ambientOcclusionColorMap.r, ambientOcclusionColorMap.r);
            ambientOcclusionColor = mix(ambientOcclusionColor, ambientOcclusionColorMap, ambientInfos.z);
            ambientOcclusionForDirectDiffuse = mix(vec3(1.), ambientOcclusionColor, ambientInfos.w); //vec3
         }
    }
}