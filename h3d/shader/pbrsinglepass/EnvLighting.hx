package h3d.shader.pbrsinglepass;

class EnvLighting extends PBRSinglePassLib {

	static var SRC = {

        @param var vAmbientColor : Vec3;
		@param var vLightingIntensity : Vec4;

		@param var vLightData0 : Vec4;
		@param var vLightDiffuse0 : Vec4;
		@param var vLightGround0 : Vec3;
		@param var glossiness : Float;

		var AARoughnessFactors:Vec2;
		
		var normalW:Vec3;
		var viewDirectionW:Vec3;

        var ambientColor:Vec3;
        var lightingIntensity:Vec4;

		var NdotV:Float;

		var roughness:Float;
		var surfaceReflectivityColor:Vec3;
		var energyConservationFactor:Vec3;
		var specularEnvironmentReflectance:Vec3;
		var diffuseBase:Vec3;
		var specularBase:Vec3;
		var clearCoatBase:Vec3;

		// LightingInfo
		var lIDiffuse:Vec3;
		var lISpecular:Vec3;

		// PreLightingInfo
        var pLILightOffset:Vec3;
        var pLILightDistanceSquared:Float;
        var pLILightDistance:Float;
        var pLIAttenuation:Float;
        var pLIL:Vec3;
        var pLIH:Vec3;
        var pLINdotV:Float;
        var pLINdotLUnclamped:Float;
        var pLINdotL:Float;
        var pLIVdotH:Float;
		var pLIRoughness:Float;
		
		var environmentBrdf:Vec3;
		var specularEnvironmentR0:Vec3;
		var specularEnvironmentR90:Vec3;
		var metallicReflectanceFactors:Vec4;

		function fragment() {
			ambientColor = vAmbientColor;
            lightingIntensity = vLightingIntensity;

            var reflectance = max(max(surfaceReflectivityColor.r, surfaceReflectivityColor.g), surfaceReflectivityColor.b); //float
            specularEnvironmentR0 = surfaceReflectivityColor.rgb; //vec3
			specularEnvironmentR90 = vec3(metallicReflectanceFactors.a); //vec3
			environmentBrdf = getBRDFLookup(NdotV, roughness); //vec3
            energyConservationFactor = getEnergyConservationFactor(specularEnvironmentR90, environmentBrdf); //vec3
			
			diffuseBase = vec3(0., 0., 0.); //vec3
			specularBase = vec3(0., 0., 0.); //vec3
			clearCoatBase = vec3(0., 0., 0.);
			
			pLINdotL = dot(normalW, vLightData0.xyz) * 0.5 + 0.5;
			pLINdotL = saturateEps(pLINdotL);
			pLINdotLUnclamped = pLINdotL;
			pLIL = normalize(vLightData0.xyz);
			pLIH = normalize(viewDirectionW + pLIL);
			pLIVdotH = saturate(dot(viewDirectionW, pLIH));

			pLINdotV = NdotV; // preInfo.NdotV = NdotV;
			pLIAttenuation = 1.0; // preInfo.attenuation = 1.0;
			pLIRoughness = roughness; // preInfo.roughness = roughness;

			diffuseBase = computeHemisphericDiffuseLighting(pLINdotL, vLightDiffuse0.rgb, vLightGround0);
			specularBase = computeSpecularLighting(pLIH, pLIRoughness, pLIVdotH, pLINdotL, pLINdotV, pLIAttenuation, normalW, specularEnvironmentR0, specularEnvironmentR90, AARoughnessFactors.x, vLightDiffuse0.rgb);
			
			// shadow = 1.; //float

			specularEnvironmentReflectance = getReflectanceFromBRDFLookup(specularEnvironmentR0, specularEnvironmentR90, environmentBrdf); //vec3
      	}
	}

	public function new() {
		super();

        this.vAmbientColor.set( 0, 0, 0 );
        this.vLightingIntensity.set( 1, 1, 1, 1 );

		this.vLightData0.set(0, 1, 0, 0);
		this.vLightDiffuse0.set(1, 1, 1, 1);
		this.vLightGround0.set(0, 0, 0);
		this.glossiness = 1;
	}
}