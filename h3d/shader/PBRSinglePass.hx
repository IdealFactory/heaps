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
		};

		var relativePosition : Vec3;
		var transformedPosition : Vec3;
		var pixelTransformedPosition : Vec3;
		var relativeNormal : Vec3;
		var transformedNormal : Vec3;
		var projectedPosition : Vec4;
		var pixelColor : Vec4;
		var depth : Float;
		var screenUV : Vec2;
		var specPower : Float;
		var specColor : Vec3;
		var worldDist : Float;

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

        var positionW:Vec3;
        var viewDirectionW:Vec3;
        var rawVNormalW:Vec3;
        var normalW:Vec3;
        var geometricNormalW:Vec3;
        var uvOffset:Vec2;

        var finalWorld:Mat4;
        var normalUpdated:Vec3;

        var ccOutConservationFactor:Float;
        var ccOutFinalClearCoatRadianceScaled:Vec3;
        var ccOutEnergyConsFCC:Vec3;
        var finalSheenRadianceScaled:Vec3;
        var finalClearCoatScaled:Vec3;

        var surfaceAlbedo:Vec3;
        var alpha:Float;
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
        var gmv:Mat4;
        var flip:Mat4;
 
		function __init__() {
            flip = mat4( vec4(-1, 0, 0, 0), vec4(0, 1, 0, 0), vec4(0, 0, 1, 0), vec4(0, 0, 0, 1));
            gmv = global.modelView * flip;
            relativePosition = input.position;// * flip.mat3x4();
            transformedPosition = relativePosition;//* global.modelView.mat3x4() * flip.mat3x4();
            projectedPosition = vec4(transformedPosition, 1) * camera.viewProj;
			relativeNormal = input.normal; //input.normal;// * flip.mat3x4();
			transformedNormal = (relativeNormal.xyz * gmv.mat3x4()).normalize();

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
            finalSheenRadianceScaled = vec3(0.);
            finalClearCoatScaled = vec3(0.);
		}

        function __init__vertex() {
            transformedPosition *= gmv.mat3x4();
        }

		function __init__fragment() {
			transformedNormal = transformedNormal.normalize();
			// same as __init__, but will force calculus inside fragment shader, which limits varyings
			screenUV = screenToUv(projectedPosition.xy / projectedPosition.w);
			depth = projectedPosition.z / projectedPosition.w; // in case it's used in vertex : we don't want to interpolate in screen space
			specPower = specularPower;
			specColor = specularColor * specularAmount;
		}

        function vertex() {
            output.position = projectedPosition * vec4(1, camera.projFlip, 1, 1);
            // rgbdMaxRange = 255.0;
            pixelTransformedPosition = transformedPosition;
    
            var positionUpdated = input.position; //vec3
            normalUpdated = vec3(input.normal.x, input.normal.y, input.normal.z); //vec3
            // normalUpdated.r = -normalUpdated.r;
            finalWorld = gmv;//world; //mat4
            var worldPos = positionUpdated * finalWorld.mat3x4(); //vec4 // finalWorld * vec4(positionUpdated, 1.0)
            vPositionW = vec3(worldPos.r, worldPos.b, worldPos.g);//vec3(worldPos.rgb);
            var normalWorld = mat3(finalWorld); //mat3
            var tmpNormal = vec3(normalUpdated.r, normalUpdated.g, normalUpdated.b);
            vNormalW = normalize(tmpNormal * finalWorld.mat3())#if !flash .rbg#end; // normalize(normalWorld * normalUpdated);
            var uv2 = vec2(0., 0.); //vec2
            vEyePosition = vec3(camera.position.r, camera.position.b, camera.position.g); //camera.position;//
            reflectionMatrix = vReflectionMatrix;
        }

        function fragment() {
            output.depth = depth;

            // debugVar = vec4(0.3, 0.3, 0.3, 1);
            positionW = vPositionW;
            rawVNormalW = vNormalW;

            reflectionMatrix = vReflectionMatrix;

            normalW = normalize(vNormalW);
            geometricNormalW = normalW;

            PI = 3.1415926535897932384626433832795;
            MINIMUMVARIANCE = 0.0005;
            
            viewDirectionW = normalize(vEyePosition.xyz - positionW); //vec3 // 
            uvOffset = vec2(0.0, 0.0); //vec2

            NdotVUnclamped = dot(normalW, viewDirectionW);
            NdotV = absEps(NdotVUnclamped);
            AARoughnessFactors = getAARoughnessFactors(normalW.xyz);
        }
	};
}
