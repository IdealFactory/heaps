package h3d.shader.pbrsinglepass;        

class Irradiance extends PBRSinglePassLib {

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

        function vertex() {
            var reflectionVector = (reflectionMatrix * vec4(vNormalW, 0)).xyz;
            vEnvironmentIrradiance = computeEnvironmentIrradiance(reflectionVector);
        }

        function fragment() {
            var alphaG = convertRoughnessToAverageSlope(roughness); //float
            alphaG += AARoughnessFactors.y;
            environmentRadiance = vec4(0., 0., 0., 0.); //vec4
            environmentIrradiance = vec3(0., 0., 0.); //vec3
            reflectionVector = computeReflectionCoords(vec4(vPositionW, 1.0), normalW); //vec3
            reflectionVector.y = -reflectionVector.y;
            reflectionVector.x = -reflectionVector.x;

            reflectionCoords = reflectionVector; //vec3
            
            // Expanded sampleReflectionTexture
            var reflectionLOD = getLodFromAlphaG(vReflectionMicrosurfaceInfos.x, alphaG); //float
            reflectionLOD = reflectionLOD * vReflectionMicrosurfaceInfos.y + vReflectionMicrosurfaceInfos.z;
            environmentRadiance = #if !flash textureLod(reflectionSampler, reflectionCoords, reflectionLOD); #else texture(reflectionSampler, reflectionCoords); #end// sampleReflectionLod
            if (rgbdDecodeEnv) {
                environmentRadiance.rgb = fromRGBD(environmentRadiance);
            }
            environmentRadiance.rgb *= vec3(vReflectionInfos.x);
            environmentRadiance.rgb *= vReflectionColor.rgb;
            
            var irradianceVector = vec3((reflectionMatrix * vec4(normalW, 0)).rgb).xyz; //vec3 //vec3(reflectionMatrix * vec4(normalW, 0)).xyz
            irradianceVector.x *= -1.0;
            environmentIrradiance = computeEnvironmentIrradiance(irradianceVector);
            environmentIrradiance *= vReflectionColor.rgb;
        }
    }
}
        