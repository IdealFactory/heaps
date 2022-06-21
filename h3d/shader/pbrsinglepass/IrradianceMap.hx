package h3d.shader.pbrsinglepass;        

class IrradianceMap extends PBRSinglePassLib {

	static var SRC = {

        var AARoughnessFactors:Vec2;

        var roughness:Float;
        var microSurface:Float;
        var NdotVUnclamped:Float;
        var NdotV:Float;
        var environmentRadiance:Vec4;
        var environmentIrradiance:Vec3;
        
        var viewDirectionW:Vec3;
        var normalW:Vec3;
        var reflectionVector:Vec3;
        var reflectionCoords:Vec3;

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
in vec3 vPositionW, in vec3 normalW, in float alphaG, in vec3 vReflectionMicrosurfaceInfos, in vec2 vReflectionInfos, in vec3 vReflectionColor, in samplerCube reflectionSampler, in vec3 vEnvironmentIrradiance, out reflectionOutParams outParams
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
    environmentIrradiance = vEnvironmentIrradiance;
    environmentIrradiance *= vReflectionColor.rgb;
    outParams.environmentRadiance = environmentRadiance;
    outParams.environmentIrradiance = environmentIrradiance;
    outParams.reflectionCoords = reflectionCoords;
}");
            
        function fragment() {
            // var alphaG = convertRoughnessToAverageSlope(roughness); //float
            // alphaG += AARoughnessFactors.y;
            // environmentRadiance = vec4(0., 0., 0., 0.); //vec4
            // environmentIrradiance = vec3(0., 0., 0.); //vec3
            // reflectionVector = computeReflectionCoords(vec4(vPositionW, 1.0), normalW); //vec3
            // reflectionVector.y = -reflectionVector.y;
            // reflectionVector.x = -reflectionVector.x;
            
            // reflectionCoords = reflectionVector; //vec3
            
            // // Expanded sampleReflectionTexture
            // var reflectionLOD = getLodFromAlphaG(vReflectionMicrosurfaceInfos.x, alphaG); //float
            // reflectionLOD = reflectionLOD * vReflectionMicrosurfaceInfos.y + vReflectionMicrosurfaceInfos.z;
            // environmentRadiance = #if !flash textureLod(reflectionSampler, reflectionCoords, reflectionLOD); #else texture(reflectionSampler, reflectionCoords); #end// sampleReflectionLod
            // if (rgbdDecodeEnv) {
            //     environmentRadiance.rgb = fromRGBD(environmentRadiance);
            // }
            // environmentRadiance.rgb *= vec3(vReflectionInfos.x);
            // environmentRadiance.rgb *= vReflectionColor.rgb;
            
            // var irradianceVector = vec3((reflectionMatrix * vec4(normalW, 0)).rgb).xyz; //vec3 //vec3(reflectionMatrix * vec4(normalW, 0)).xyz
            // irradianceVector.z *= -1.0;
            // environmentIrradiance = computeEnvironmentIrradiance(irradianceVector);
            // environmentIrradiance *= vReflectionColor.rgb;

            glslsource("
    // IrradianceMap fragment
    float microSurface = reflectivityOut.microSurface;
    float roughness = reflectivityOut.roughness;
    surfaceAlbedo = reflectivityOut.surfaceAlbedo;
    float NdotVUnclamped = dot(normalW, viewDirectionW);
    float NdotV = absEps(NdotVUnclamped);
    float alphaG = convertRoughnessToAverageSlope(roughness);
    vec2 AARoughnessFactors = getAARoughnessFactors(normalW.xyz);
    alphaG += AARoughnessFactors.y;
    vec3 environmentBrdf = getBRDFLookup(NdotV, roughness);
");
        }
    }
}
        