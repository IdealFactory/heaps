package h3d.shader.pbrsinglepass;

class FinalCombination extends PBRSinglePassLib {

	static var SRC = {

        @param var uvisibility : Float;
        @param var uexposureLinear : Float;
        @param var ucontrast : Float;

        @keep var surfaceAlbedo:Vec3;
        @keep var ambientOcclusionColor:Vec3;
        @keep var ambientOcclusionForDirectDiffuse:Vec3;
        @keep var environmentRadiance:Vec4;
        @keep var environmentIrradiance:Vec3;

        @keep var energyConservationFactor:Vec3;
        @keep var diffuseBase:Vec3;
        @keep var specularBase:Vec3;
        @keep var specularEnvironmentReflectance:Vec3;

        // Sheen extension
        @keep var sheenBase:Vec3;
        @keep var sheenOutSheenColor:Vec3;
        @keep var sheenOutSheenAlbedoScaling:Float;

        // Clearcoat extension
        @keep var clearCoatBase:Vec3;
        @keep var ccOutConservationFactor:Float;
        @keep var ccOutEnergyConsFCC:Vec3;

        @keep var finalAmbient:Vec3;
        @keep var finalDiffuse:Vec3;
        @keep var finalSpecular:Vec3;
        @keep var finalIrradiance:Vec3;
        @keep var finalSpecularScaled:Vec3;
        @keep var finalRadiance:Vec3;
        @keep var finalRadianceScaled:Vec3;
        @keep var finalSheen:Vec3;
        @keep var finalSheenScaled:Vec3;
        @keep var finalSheenRadianceScaled:Vec3;
        @keep var finalClearCoat:Vec3;
        @keep var finalClearCoatScaled:Vec3;

        var ambientColor:Vec3;
        var lightingIntensity:Vec4;
        @keep var alpha:Float;

        @keep var finalColor : Vec4;
        @keep var visibility : Float;
        @keep var exposureLinear : Float;
        @keep var contrast : Float;

        function __init__fragment() {
            glslsource("// Output __init__fragment");

            visibility = uvisibility;
            exposureLinear = uexposureLinear;
            contrast = ucontrast;
        }

        function fragment() {
            // var sA:Vec3 = vec3(sheenOutSheenAlbedoScaling) * surfaceAlbedo.rgb;
            // finalIrradiance = environmentIrradiance; //vec3
            // finalIrradiance *= vec3(ccOutConservationFactor);
            // finalIrradiance *= sA;
            // finalIrradiance *= vec3(lightingIntensity.z);
            // finalIrradiance *= ambientOcclusionColor;
            // finalSpecular = specularBase;
            // finalSpecular = max(finalSpecular, 0.0);
            // finalSpecularScaled = finalSpecular * vec3(lightingIntensity.x) * vec3(lightingIntensity.w);
            // finalSpecularScaled *= energyConservationFactor;
            // finalRadiance = environmentRadiance.rgb; //vec3
            // finalRadiance *= specularEnvironmentReflectance;
            // finalRadianceScaled = finalRadiance * vec3(lightingIntensity.z); //vec3
            // finalRadianceScaled *= energyConservationFactor;
            // finalRadianceScaled *= vec3(sheenOutSheenAlbedoScaling);
            // var luminanceOverAlpha:Float = 0.0;
            // luminanceOverAlpha += getLuminance(finalRadianceScaled);
            // alpha = saturate(alpha+luminanceOverAlpha*luminanceOverAlpha);
            // finalSheen = sheenBase * sheenOutSheenColor;
            // finalSheen = max(finalSheen, 0.0);
            // finalSheenScaled = finalSheen * vec3(lightingIntensity.x) * vec3(lightingIntensity.w);
            // finalSheenRadianceScaled *= vec3(ccOutConservationFactor);
            // finalClearCoat = clearCoatBase;
            // finalClearCoat = max(finalClearCoat, 0.0);
            // finalClearCoatScaled = finalClearCoat * vec3(lightingIntensity.x) * vec3(lightingIntensity.w);
            // finalClearCoatScaled *= ccOutEnergyConsFCC;
            // finalDiffuse = diffuseBase; //vec3
            // finalDiffuse *= sA;
            // finalDiffuse = max(finalDiffuse, 0.0);
            // finalDiffuse *= vec3(lightingIntensity.x);
            // finalAmbient = ambientColor; //vec3
            // finalAmbient *= sA;
            // finalAmbient *= ambientOcclusionColor;
            // finalDiffuse *= ambientOcclusionForDirectDiffuse;

            glslsource("
    // FinalCombination fragment
    vec3 finalIrradiance = reflectionOut.environmentIrradiance;
    finalIrradiance *= surfaceAlbedo.rgb;
    finalIrradiance *= vLightingIntensity.z;
    finalIrradiance *= aoOut.ambientOcclusionColor;
    vec3 finalRadiance = reflectionOut.environmentRadiance.rgb;
    finalRadiance *= subSurfaceOut.specularEnvironmentReflectance;
    vec3 finalRadianceScaled = finalRadiance*vLightingIntensity.z;
    finalRadianceScaled *= energyConservationFactor;
    vec3 finalDiffuse = diffuseBase;
    finalDiffuse *= surfaceAlbedo.rgb;
    finalDiffuse = max(finalDiffuse, 0.0);
    finalDiffuse *= vLightingIntensity.x;
    vec3 finalAmbient = vAmbientColor;
    finalAmbient *= surfaceAlbedo.rgb;
    // vec3 finalEmissive = vEmissiveColor;
    finalEmissive *= vLightingIntensity.y;
    vec3 ambientOcclusionForDirectDiffuse = mix(vec3(1.), aoOut.ambientOcclusionColor, vAmbientInfos.w);
    finalAmbient *= aoOut.ambientOcclusionColor;
    finalDiffuse *= ambientOcclusionForDirectDiffuse;

    finalColor = vec4(
    finalAmbient +
    finalDiffuse +
    finalIrradiance +
    finalRadianceScaled +
    finalEmissive, alpha);

    finalColor = max(finalColor, 0.0);
    finalColor = applyImageProcessing(finalColor);
    finalColor.a *= visibility;
");
        }
    }

    public function new() {
        super();

        this.uvisibility = 1;
        this.uexposureLinear = 1;
        this.ucontrast = 1;
        // this.debug = true;
    }
}