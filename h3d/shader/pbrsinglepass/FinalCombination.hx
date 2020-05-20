package h3d.shader.pbrsinglepass;

class FinalCombination extends hxsl.Shader {

	static var SRC = {

        @param var vLightingIntensity : Vec4;
        @param var vAmbientColor : Vec3;

        var surfaceAlbedo:Vec3;
        var ambientOcclusionColor:Vec3;
        var environmentRadiance:Vec4;
        var environmentIrradiance:Vec3;

        var energyConservationFactor:Vec3;
        var diffuseBase:Vec3;
        var specularBase:Vec3;
        var specularEnvironmentReflectance:Vec3;

        var finalAmbient:Vec3;
        var finalDiffuse:Vec3;
        var finalSpecular:Vec3;
        var finalIrradiance:Vec3;
        var finalSpecularScaled:Vec3;
        var finalRadiance:Vec3;
        var finalRadianceScaled:Vec3;

        var lightingIntensity:Vec4;

        function fragment() {

            lightingIntensity = vLightingIntensity;

            finalIrradiance = environmentIrradiance; //vec3
            finalIrradiance *= surfaceAlbedo.rgb;
            finalIrradiance *= ambientOcclusionColor;
            finalSpecular = specularBase;
            finalSpecular = max(finalSpecular, 0.0);
            finalSpecularScaled = finalSpecular * vLightingIntensity.x * vLightingIntensity.w;
            finalSpecularScaled *= energyConservationFactor;
            finalRadiance = environmentRadiance.rgb; //vec3
            finalRadiance *= specularEnvironmentReflectance;
            finalRadianceScaled = finalRadiance * lightingIntensity.z; //vec3
            finalRadianceScaled *= energyConservationFactor;
            finalDiffuse = diffuseBase; //vec3
            finalDiffuse *= surfaceAlbedo.rgb;
            finalDiffuse = max(finalDiffuse, 0.0);
            finalAmbient = vAmbientColor; //vec3
            finalAmbient *= surfaceAlbedo.rgb;
        }
    }
    
    public function new() {
        super();

        this.vAmbientColor.set( 0, 0, 0 );
        this.vLightingIntensity.set( 1, 1, 1, 1 );
    }
}