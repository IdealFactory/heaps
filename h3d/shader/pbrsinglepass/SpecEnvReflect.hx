package h3d.shader.pbrsinglepass;

class SpecEnvReflect extends PBRSinglePassLib {

	static var SRC = {

        var viewDirectionW:Vec3;
        var ambientMonochrome:Float;
        var normalW:Vec3;
        @keep var geometricNormalW:Vec3;
        var specularEnvironmentReflectance:Vec3;

        var NdotVUnclamped:Float;
        var seo:Float;
        var eho:Float;

        fragfunction("reflectionOutParams",
"struct reflectionOutParams {
        vec4 environmentRadiance;
        vec3 environmentIrradiance;
        vec3 reflectionCoords;
};");

fragfunction("createReflectionCoords",
"void createReflectionCoords(
in vec3 vPositionW, in vec3 normalW, out vec3 reflectionCoords
) {
        vec3 reflectionVector = computeReflectionCoords(vec4(vPositionW, 1.0), normalW);
        reflectionCoords = reflectionVector;
}");
                        
        fragfunction("sampleReflectionTexture",
"void sampleReflectionTexture(
in float alphaG, in vec3 vReflectionMicrosurfaceInfos, in vec2 vReflectionInfos, in vec3 vReflectionColor, in samplerCube reflectionSampler, const vec3 reflectionCoords, out vec4 environmentRadiance
) {
        float reflectionLOD = getLodFromAlphaG(vReflectionMicrosurfaceInfos.x, alphaG);
        reflectionLOD = reflectionLOD*vReflectionMicrosurfaceInfos.y+vReflectionMicrosurfaceInfos.z;
        float requestedReflectionLOD = reflectionLOD;
        environmentRadiance = sampleReflectionLod(reflectionSampler, reflectionCoords, reflectionLOD);
        environmentRadiance.rgb *= vReflectionInfos.x;
        environmentRadiance.rgb *= vReflectionColor.rgb;
}");
                                        
        fragfunction("reflectionBlock",
"void reflectionBlock(
in vec3 vPositionW, in vec3 normalW, in float alphaG, in vec3 vReflectionMicrosurfaceInfos, in vec2 vReflectionInfos, in vec3 vReflectionColor, in samplerCube reflectionSampler, in mat4 reflectionMatrix, out reflectionOutParams outParams
) {
        vec4 environmentRadiance = vec4(0., 0., 0., 0.);
        vec3 reflectionCoords = vec3(0.);
        createReflectionCoords(
        vPositionW, normalW, reflectionCoords
        );
        sampleReflectionTexture(
        alphaG, vReflectionMicrosurfaceInfos, vReflectionInfos, vReflectionColor, reflectionSampler, reflectionCoords, environmentRadiance
        );
        vec3 environmentIrradiance = vec3(0., 0., 0.);
        vec3 irradianceVector = vec3(reflectionMatrix*vec4(normalW, 0)).xyz;
        environmentIrradiance = computeEnvironmentIrradiance(irradianceVector * vec3(-1., 1., 1.));
        environmentIrradiance *= vReflectionColor.rgb;
        outParams.environmentRadiance = environmentRadiance;
        outParams.environmentIrradiance = environmentIrradiance;
        outParams.reflectionCoords = reflectionCoords;
}");
        
        
                
        function fragment() {
            // seo = environmentRadianceOcclusion(ambientMonochrome, NdotVUnclamped); //float
            // eho = environmentHorizonOcclusion(-viewDirectionW, normalW, geometricNormalW); //float
            // specularEnvironmentReflectance *= seo;
            // specularEnvironmentReflectance *= eho;

            glslsource("
    // SpecEnvReflect fragment
    float seo = environmentRadianceOcclusion(ambientMonochrome, NdotVUnclamped);
    float eho = environmentHorizonOcclusion(-viewDirectionW, normalW, geometricNormalW);
    reflectionOutParams reflectionOut;
    reflectionBlock(
    vPositionW, normalW, alphaG, vReflectionMicrosurfaceInfos, vReflectionInfos, vReflectionColor, reflectionSampler, reflectionMatrix, reflectionOut
    );
");
        }
	}
}