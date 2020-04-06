package h3d.shader.pbrsinglepass;        

class Irradiance extends hxsl.Shader {

	static var SRC = {

        @param var vReflectionColor : Vec3;
        @param var reflectionMatrix : Mat4;
        @param var reflectionSampler : SamplerCube;
        @param var vReflectionMicrosurfaceInfos : Vec3;
        @param var vReflectionInfos : Vec2;

        @param var vSphericalL00 : Vec3;                                // uniform vec3 vSphericalL00;
        @param var vSphericalL1_1 : Vec3;                               // uniform vec3 vSphericalL1_1;
        @param var vSphericalL10 : Vec3;                                // uniform vec3 vSphericalL10;
        @param var vSphericalL11 : Vec3;                                // uniform vec3 vSphericalL11;
        @param var vSphericalL2_2 : Vec3;                               // uniform vec3 vSphericalL2_2;
        @param var vSphericalL2_1 : Vec3;                               // uniform vec3 vSphericalL2_1;
        @param var vSphericalL20 : Vec3;                                // uniform vec3 vSphericalL20;
        @param var vSphericalL21 : Vec3;                                // uniform vec3 vSphericalL21;
        @param var vSphericalL22 : Vec3;                                // uniform vec3 vSphericalL22;

        @var var vEyePosition : Vec3;
        @var var vPositionW : Vec3; 
        // @var var vNormalW : Vec3;
        @var var vEnvironmentIrradiance:Vec3;

        var MINIMUMVARIANCE : Float;
        var LinearEncodePowerApprox : Float;// = 2.2;
        var AARoughnessFactors:Vec2;

        var roughness:Float;
        var microSurface:Float;
        var NdotVUnclamped:Float;
        var NdotV:Float;
        var environmentRadiance:Vec4;
        var environmentIrradiance:Vec3;
        var Epsilon : Float;
        
        var viewDirectionW:Vec3;
        var normalW:Vec3;

        var testvar:Vec4;

        function absEps(x:Float):Float {
            return abs(x)+Epsilon;
        }

        function square(value:Float):Float {
            return value*value;
        }

        function convertRoughnessToAverageSlope(roughness:Float):Float {
            return square(roughness) + MINIMUMVARIANCE;
        }
        
        function getAARoughnessFactors(normalVector:Vec3):Vec2 {
            var nDfdx = dFdx(normalVector.xyz); //vec3
            var nDfdy = dFdy(normalVector.xyz); //vec3
            var slopeSquare = max(dot(nDfdx, nDfdx), dot(nDfdy, nDfdy)); //float
            var geometricRoughnessFactor = pow(saturate(slopeSquare), 0.333); //float
            var geometricAlphaGFactor = sqrt(slopeSquare); //float
            geometricAlphaGFactor *= 0.75;
            return vec2(geometricRoughnessFactor, geometricAlphaGFactor);
        }

        function computeReflectionCoords(worldPos:Vec4, worldNormal:Vec3):Vec3 {
            return computeCubicCoords(worldPos, worldNormal, vEyePosition.xyz, reflectionMatrix);
        }
        
        function computeCubicCoords(worldPos:Vec4, worldNormal:Vec3, eyePosition:Vec3, reflectionMatrix:Mat4):Vec3 {
            var viewDir = normalize(worldPos.xyz - eyePosition); //vec3
            var coords = reflect(viewDir, worldNormal); //vec3
            coords = (reflectionMatrix * vec4(coords, 0)).xyz; //coords = vec3(reflectionMatrix * vec4(coords, 0));
            return coords;
        }

        function getLodFromAlphaG(cubeMapDimensionPixels:Float, microsurfaceAverageSlope:Float):Float {
            var microsurfaceAverageSlopeTexels = cubeMapDimensionPixels * microsurfaceAverageSlope; //float
            var lod = log2(microsurfaceAverageSlopeTexels); //float
            return lod;
        }
        
        function fromRGBD(rgbd:Vec4):Vec3 {
            rgbd.rgb=toLinearSpace(rgbd.rgb); //(rgbd.rgb);
            return rgbd.rgb/rgbd.a;
        }

        function toLinearSpace(color:Vec3):Vec3 {
            return pow(color,vec3(LinearEncodePowerApprox));
        }

        function fragment() {
            roughness = 1. - microSurface; //float
            NdotVUnclamped = dot(normalW, viewDirectionW); //float
            NdotV = absEps(NdotVUnclamped); //float
            var alphaG = convertRoughnessToAverageSlope(roughness); //float
            AARoughnessFactors = getAARoughnessFactors(normalW.xyz); //vec2
            alphaG += AARoughnessFactors.y;
            environmentRadiance = vec4(0., 0., 0., 0.); //vec4
            environmentIrradiance = vec3(0., 0., 0.); //vec3
            var reflectionVector = computeReflectionCoords(vec4(vPositionW, 1.0), normalW); //vec3
            reflectionVector.z *= -1.0;
            var reflectionCoords = reflectionVector; //vec3
            var reflectionLOD = getLodFromAlphaG(vReflectionMicrosurfaceInfos.x, alphaG); //float
            reflectionLOD = reflectionLOD * vReflectionMicrosurfaceInfos.y + vReflectionMicrosurfaceInfos.z;
            var requestedReflectionLOD = reflectionLOD; //float
            environmentRadiance = textureLod(reflectionSampler, reflectionCoords, requestedReflectionLOD); // sampleReflectionLod
            // environmentRadiance.rgb = fromRGBD(environmentRadiance);
            environmentIrradiance = vEnvironmentIrradiance;
            environmentRadiance.rgb *= vReflectionInfos.x;
            environmentRadiance.rgb *= vReflectionColor.rgb;
            environmentIrradiance *= vReflectionColor.rgb;
 
            // testvar = vec4(vec3(reflectionVector.rgb), 1);
       }
    }

	public function new() {
		super();
        
        this.vSphericalL10.set( 0.0979, 0.0495, 0.0295 );
        this.vSphericalL22.set( 0.0093, -0.0337, -0.1483 );
        this.vSphericalL11.set( 0.0867, 0.1087, 0.1688 );
        this.vSphericalL00.set( 0.5444, 0.4836, 0.6262 );
        this.vSphericalL20.set( 0.0062, -0.0018, -0.0101 );
        this.vSphericalL21.set( 0.0408, 0.0495, 0.0935 );
        this.vSphericalL2_2.set( 0.0154, 0.0403, 0.1151 );
        this.vSphericalL2_1.set( 0.0442, 0.0330, 0.0402 );

        this.vReflectionInfos.set( 1, 0 );

        this.reflectionMatrix.loadValues([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

        this.vReflectionColor.set( 1, 1, 1 );
        this.vReflectionMicrosurfaceInfos.set( 128, 0.8000, 0 );
        
    }

}
        