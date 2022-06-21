package h3d.shader;        

class PBRSinglePass extends h3d.shader.pbrsinglepass.PBRSinglePassLib {

	static var SRC = {

        @global var camera : {
			var view : Mat4;
			var proj : Mat4;
			var position : Vec3;
			var projFlip : Float;
			var projDiag : Vec3;
			var viewProj : Mat4;
			var inverseViewProj : Mat4;
			var zNear : Float;
			var zFar : Float;
			@var var dir : Vec3;
		};

		@global var global : {
			var time : Float;
			var pixelSize : Vec2;
			@perObject var modelView : Mat4;
			@perObject var modelViewInverse : Mat4;
		};

        // VERTEX 
		@input var input : {
			var position : Vec3;                                        // attribute vec3 position;    
			var normal : Vec3;                                          // attribute vec3 normal;
			var uv : Vec2;                                              // attribute vec2 uv;
		};

        // @keep @param var albedoSampler : Sampler2D; 

        @param var world : Mat4;                                        // uniform mat4 world;
        
        // @var var vPositionW : Vec3;                                     // varying vec3 vPositionW;
        // @var var vNormalW : Vec3;                                       // varying vec3 vNormalW;
        // @var var vEyePosition : Vec3;

        // FRAGMENT
        // @param var vCameraInfos : Vec4;                                 // uniform vec4 vCameraInfos;

        var output : {
			var position : Vec4;
			var depth : Float;
			var normal : Vec3;
			var worldDist : Float;
			var color : Vec4;
		};

		@keepv var relativePosition : Vec3;
		@keepv var transformedPosition : Vec3;
		@keepv var pixelTransformedPosition : Vec3;
		@keepv var transformedNormal : Vec3;
		@keepv var projectedPosition : Vec4;
		@keepv var pixelColor : Vec4;
		@keepv var depth : Float;
		@keep @keepv var screenUV : Vec2;
		@keepv var specPower : Float;
		@keepv var specColor : Vec3;
		@keepv var worldDist : Float;

        @param var color : Vec4;
        // @param var vReflectionMatrix : Mat4;
		@range(0,100) @param var specularPower : Float;
		@range(0,10) @param var specularAmount : Float;
        @param var specularColor : Vec3;

        // var PI : Float;// = 3.1415926535897932384626433832795;
        // var MINIMUMVARIANCE : Float;
        // var LinearEncodePowerApprox : Float;// = 2.2;
        // var GammaEncodePowerApprox : Float;// = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
        // var LuminanceEncodeApprox : Vec3;// = vec3(0.2126,0.7152,0.0722);
        // var LuminanceEncodeApproxX : Float;// = 0.2126;
        // var LuminanceEncodeApproxY: Float;// = 0.7152;
        // var LuminanceEncodeApproxZ : Float;// = 0.0722;
        // var Epsilon : Float;// = 0.0000001;

        // var rgbdMaxRange : Float;// = 255.0;

        @keep var positionW:Vec3;
        @keep var viewDirectionW:Vec3;
        @keep var rawVNormalW:Vec3;
        @keep var normalW:Vec3;
        var geometricNormalW:Vec3;
        @keep var uvOffset:Vec2;

        var finalWorld:Mat4;
        var normalUpdated:Vec3;

        var ccOutConservationFactor:Float;
        var ccOutFinalClearCoatRadianceScaled:Vec3;
        var ccOutEnergyConsFCC:Vec3;
        var finalSheenRadianceScaled:Vec3;
        var finalClearCoatScaled:Vec3;

        var surfaceAlbedo:Vec3;
        @keep var alpha:Float;
        var ambientOcclusionColor:Vec3;
        var microSurface:Float;
        var surfaceReflectivityColor:Vec3;
        var metallicRoughness:Vec2;
        var roughness:Float;
        var NdotVUnclamped:Float;
        var NdotV:Float;
        var AARoughnessFactors:Vec2;
        var environmentRadiance:Vec4;
        var environmentIrradiance:Vec3;
        // var debugVar:Vec4;
        @keepv var gmv:Mat4;
        @keepv var flip:Mat4;
        // var reflectionMatrix:Mat4;
        // var reflectionVector:Vec3;
        @keepv var worldPos:Vec3;
        @keepv var positionUpdated:Vec3; 
        @keepv var tmpNormal:Vec3; 

        // @keep var finalColor : Vec4;
 
		function __init__() {
            glslsource("// PBRShader __init__");
            flip = mat4( vec4(1, 0, 0, 0), vec4(0, -1, 0, 0), vec4(0, 0, 1, 0), vec4(0, 0, 0, 1));
            gmv = global.modelView * flip;
            relativePosition = input.position;
            transformedPosition = relativePosition * gmv.mat3x4();
            projectedPosition = vec4(transformedPosition, 1) * camera.viewProj;
            transformedNormal = (vec3(input.normal.x, input.normal.y, input.normal.z) * gmv.mat3x4()).normalize();

            camera.dir = (camera.position - transformedPosition).normalize();
			pixelColor = color;
			specPower = specularPower;
			specColor = specularColor * specularAmount;
			screenUV = screenToUv(projectedPosition.xy / projectedPosition.w);
			depth = projectedPosition.z / projectedPosition.w;
			worldDist = length(transformedPosition - camera.position) / camera.zFar;
            ccOutConservationFactor = 1.0;
            ccOutFinalClearCoatRadianceScaled = vec3(0.);
            ccOutEnergyConsFCC = vec3(0.);
            // finalSheenRadianceScaled = vec3(0.);
            finalClearCoatScaled = vec3(0.);


		}

		function __init__fragment() {
            glslsource("
    // PBRShader __init__fragment

    viewDirectionW = normalize(vEyePosition.xyz - vPositionW); //vec3 //  
    normalW = normalize(vNormalW);
    geometricNormalW = normalW;
    geometricNormalW = gl_FrontFacing ? -geometricNormalW : geometricNormalW;
    uvOffset = vec2(0.0, 0.0); //vec2
    ");

			transformedNormal = transformedNormal.normalize();
			// same as __init__, but will force calculus inside fragment shader, which limits varyings
			screenUV = screenToUv(projectedPosition.xy / projectedPosition.w);
			depth = projectedPosition.z / projectedPosition.w; // in case it's used in vertex : we don't want to interpolate in screen space
			specPower = specularPower;
			specColor = specularColor * specularAmount;
		}

        function vertex() {
            glslsource("// PBRShader vertex");
            output.position = projectedPosition * vec4(1, camera.projFlip, 1, 1);
            // rgbdMaxRange = 255.0;
            pixelTransformedPosition = transformedPosition;
    
            positionUpdated = input.position * vec3(-1.0, 1., 1.); //vec3
            normalUpdated = vec3(input.normal.x * -1.0, input.normal.y, input.normal.z); //vec3
            // normalUpdated.r = -normalUpdated.r;
            finalWorld = gmv;//world; //mat4
            worldPos = positionUpdated * finalWorld.mat3x4(); //vec4 // finalWorld * vec4(positionUpdated, 1.0)
            vPositionW = vec3(worldPos.r, worldPos.b, worldPos.g);//vec3(worldPos.rgb);
            var normalWorld = mat3(finalWorld); //mat3
            tmpNormal = vec3(normalUpdated.r, normalUpdated.g, normalUpdated.b);
            vNormalW = normalize(tmpNormal * finalWorld.mat3())#if !flash .rbg#end; // normalize(normalWorld * normalUpdated);
            var uv2 = vec2(0., 0.); //vec2
            vEyePosition = vec3(camera.position.r, camera.position.b, camera.position.g); //camera.position;//
            vReflectionMatrix = uReflectionMatrix;
            reflectionMatrix = uReflectionMatrix;

            vSphericalL00 = vSphL00;
            vSphericalL10 = vSphL10;
            vSphericalL11 = vSphL11;
            vSphericalL20 = vSphL20;
            vSphericalL21 = vSphL21;
            vSphericalL22 = vSphL22;
            vSphericalL1_1 = vSphL1_1;
            vSphericalL2_1 = vSphL2_1;
            vSphericalL2_2 = vSphL2_2;

            // var reflectionVector = (reflectionMatrix * vec4(vNormalW, 0)).xyz;
            // vEnvironmentIrradiance = computeEnvironmentIrradiance(reflectionVector);

            // var uvUpdated : Vec2 = input.uv;
            // vMainUV1 = uvUpdated;

        }

        function fragment() {
            glslsource("// PBRShader fragment");

            output.depth = depth;

            // debugVar = vec4(0.3, 0.3, 0.3, 1);
            positionW = vPositionW;
            rawVNormalW = vNormalW;

            reflectionMatrix = vReflectionMatrix;

            // viewDirectionW = normalize(vEyePosition.xyz - positionW); //vec3 //  
            // normalW = normalize(vNormalW);
            // geometricNormalW = normalW;
            // uvOffset = vec2(0.0, 0.0); //vec2

            // PI = 3.1415926535897932384626433832795;
            
            vSphericalL00 = vSphL00;
            vSphericalL10 = vSphL10;
            vSphericalL11 = vSphL11;
            vSphericalL20 = vSphL20;
            vSphericalL21 = vSphL21;
            vSphericalL22 = vSphL22;
            vSphericalL1_1 = vSphL1_1;
            vSphericalL2_1 = vSphL2_1;
            vSphericalL2_2 = vSphL2_2;

            vAlbedoColor = uAlbedoColor;
            vAlbedoInfos = uAlbedoInfos;
            vAmbientInfos = uAmbientInfos;
    
            vReflectionColor = uReflectionColor;
            vReflectionMicrosurfaceInfos = uReflectionMicrosurfaceInfos;
            vReflectionInfos = uReflectionInfos;
            vReflectionMatrix = uReflectionMatrix;    
    
            // environmentBrdfSampler = environmentBrdfUniform;
            // reflectionSampler = reflectionUniform;
            // clearCoatSampler = clearCoatUniform;

            // MINIMUMVARIANCE = 0.0005;

           // LinearEncodePowerApprox  = 2.2;
            // GammaEncodePowerApprox  = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
            // LuminanceEncodeApprox  = vec3(0.2126,0.7152,0.0722);
            // LuminanceEncodeApproxX  = 0.2126;
            // LuminanceEncodeApproxY = 0.7152;
            // LuminanceEncodeApproxZ  = 0.0722;
            // Epsilon = 0.0000001;
    
            // rgbdMaxRange = 255.0;


            // NdotVUnclamped = dot(normalW, viewDirectionW);
            // NdotV = absEps(NdotVUnclamped);
            // AARoughnessFactors = getAARoughnessFactors(normalW.xyz);


            // if (screenUV.x > 0.) {
            //     finalColor.rgb = normalize(debugVar.rgb)*0.5+0.5;
            //     finalColor.a = 1.0;
            // }

            // output.color = finalColor;
        }
	};

	public function new() {
        super();

        this.uReflectionMatrix.loadValues([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
	}

}
