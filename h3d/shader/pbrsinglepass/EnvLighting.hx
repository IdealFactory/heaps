package h3d.shader.pbrsinglepass;

class EnvLighting extends PBRSinglePassLib {

	static var SRC = {

        @param var uAmbientColor : Vec3;
		@param var uLightingIntensity : Vec4;

		@param var uLightData0 : Vec4;
		@param var uLightDiffuse0 : Vec4;
		@param var uLightGround0 : Vec3;
		@param var uglossiness : Float;

		@keep var AARoughnessFactors:Vec2;

		@keep var normalW:Vec3;
		@keep var viewDirectionW:Vec3;

        @keep var ambientColor:Vec3;
        @keep var lightingIntensity:Vec4;

		@keep var NdotV:Float;

		@keep var roughness:Float;
		@keep var surfaceReflectivityColor:Vec3;
		@keep var energyConservationFactor:Vec3;
		@keep var specularEnvironmentReflectance:Vec3;
		@keep var diffuseBase:Vec3;
		@keep var specularBase:Vec3;
		@keep var clearCoatBase:Vec3;

		@keep // LightingInfo
		@keep var lIDiffuse:Vec3;
		@keep var lISpecular:Vec3;

		@keep // PreLightingInfo
        @keep var pLILightOffset:Vec3;
        @keep var pLILightDistanceSquared:Float;
        @keep var pLILightDistance:Float;
        @keep var pLIAttenuation:Float;
        @keep var pLIL:Vec3;
        @keep var pLIH:Vec3;
        @keep var pLINdotV:Float;
        @keep var pLINdotLUnclamped:Float;
        @keep var pLINdotL:Float;
        @keep var pLIVdotH:Float;
		@keep var pLIRoughness:Float;
		@keep 
		@keep var environmentBrdf:Vec3;
		@keep var specularEnvironmentR0:Vec3;
		@keep var specularEnvironmentR90:Vec3;
		@keep var metallicReflectanceFactors:Vec4;

		@keep var reflectance:Float;

		@keep var vAmbientColor : Vec3;
		@keep var vLightingIntensity : Vec4;
		@keep var vLightData0 : Vec4;
		@keep var vLightDiffuse0 : Vec4;
		@keep var vLightGround0 : Vec3;
		@keep var glossiness : Float;


		function __init__fragment() {
			glslsource("// EnvLighting-InitFragment");

			vAmbientColor = uAmbientColor;
            vLightingIntensity = uLightingIntensity;
            vLightData0 = uLightData0;
            vLightDiffuse0 = uLightDiffuse0;
            vLightGround0 = uLightGround0;
            glossiness = uglossiness;
		}

		function fragment() {
			// ambientColor = vAmbientColor;
            // lightingIntensity = vLightingIntensity;

            // var reflectance = max(max(surfaceReflectivityColor.r, surfaceReflectivityColor.g), surfaceReflectivityColor.b); //float
            // specularEnvironmentR0 = surfaceReflectivityColor.rgb; //vec3
			// specularEnvironmentR90 = vec3(metallicReflectanceFactors.a); //vec3
			// environmentBrdf = getBRDFLookup(NdotV, roughness, environmentBrdfSampler); //vec3
            // energyConservationFactor = getEnergyConservationFactor(specularEnvironmentR90, environmentBrdf); //vec3
			
			// diffuseBase = vec3(0., 0., 0.); //vec3
			// specularBase = vec3(0., 0., 0.); //vec3
			// clearCoatBase = vec3(0., 0., 0.);
			
			// pLINdotL = dot(normalW, vLightData0.xyz) * 0.5 + 0.5;
			// pLINdotL = saturateEps(pLINdotL);
			// pLINdotLUnclamped = pLINdotL;
			// pLIL = normalize(vLightData0.xyz);
			// pLIH = normalize(viewDirectionW + pLIL);
			// pLIVdotH = saturate(dot(viewDirectionW, pLIH));

			// pLINdotV = NdotV; // preInfo.NdotV = NdotV;
			// pLIAttenuation = 1.0; // preInfo.attenuation = 1.0;
			// pLIRoughness = roughness; // preInfo.roughness = roughness;

			// diffuseBase = computeHemisphericDiffuseLighting(pLINdotL, vLightDiffuse0.rgb, vLightGround0);
			// specularBase = computeSpecularLighting(pLIH, pLIRoughness, pLIVdotH, pLINdotL, pLINdotV, pLIAttenuation, normalW, specularEnvironmentR0, specularEnvironmentR90, AARoughnessFactors.x, vLightDiffuse0.rgb);
			
			// // shadow = 1.; //float

			// specularEnvironmentReflectance = getReflectanceFromBRDFLookup(specularEnvironmentR0, specularEnvironmentR90, environmentBrdf); //vec3

			glslsource("
	// EnvLighting-Fragment
	float reflectance = max(max(reflectivityOut.surfaceReflectivityColor.r, reflectivityOut.surfaceReflectivityColor.g), reflectivityOut.surfaceReflectivityColor.b);
	vec3 specularEnvironmentR0 = reflectivityOut.surfaceReflectivityColor.rgb;
	vec3 specularEnvironmentR90 = vec3(metallicReflectanceFactors.a);
");
      	}
	}

	public function new() {
		super();

        this.uAmbientColor.set( 0, 0, 0 );
        this.uLightingIntensity.set( 1, 1, 1, 1 );

		this.uLightData0.set(0, 1, 0, 0);
		this.uLightDiffuse0.set(1, 1, 1, 1);
		this.uLightGround0.set(0, 0, 0);
		this.uglossiness = 1;
	}
}