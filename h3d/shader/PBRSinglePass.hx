package h3d.shader;        

class PBRSinglePass extends hxsl.Shader {

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
        
        @var var vPositionW : Vec3;                                     // varying vec3 vPositionW;
        @var var vNormalW : Vec3;                                       // varying vec3 vNormalW;
        @var var vEyePosition : Vec3;

        // FRAGMENT
        @param var vReflectionMicrosurfaceInfos : Vec3;                 // uniform vec3 vReflectionMicrosurfaceInfos;
        @param var vAmbientColor : Vec3;                                // uniform vec3 vAmbientColor;
        @param var vCameraInfos : Vec4;                                 // uniform vec4 vCameraInfos;

        var output : {
			var position : Vec4;
			var depth : Float;
			var normal : Vec3;
			var worldDist : Float;
		};

		var relativePosition : Vec3;
		var transformedPosition : Vec3;
		var pixelTransformedPosition : Vec3;
		var transformedNormal : Vec3;
		var projectedPosition : Vec4;
		var pixelColor : Vec4;
		var depth : Float;
		var screenUV : Vec2;
		var specPower : Float;
		var specColor : Vec3;
		var worldDist : Float;

		@param var color : Vec4;
		@range(0,100) @param var specularPower : Float;
		@range(0,10) @param var specularAmount : Float;
        @param var specularColor : Vec3;

        var PI : Float;// = 3.1415926535897932384626433832795;
        var MINIMUMVARIANCE : Float;
        var LinearEncodePowerApprox : Float;// = 2.2;
        var GammaEncodePowerApprox : Float;// = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
        var LuminanceEncodeApprox : Vec3;// = vec3(0.2126,0.7152,0.0722);
        var LuminanceEncodeApproxX : Float;// = 0.2126;
        var LuminanceEncodeApproxY: Float;// = 0.7152;
        var LuminanceEncodeApproxZ : Float;// = 0.0722;
        var Epsilon : Float;// = 0.0000001;

        var rgbdMaxRange : Float;// = 255.0;

        var positionW:Vec3;
        var viewDirectionW:Vec3;
        var rawVNormalW:Vec3;
        var normalW:Vec3;
        var uvOffset:Vec2;

        var surfaceAlbedo:Vec3;
        var alpha:Float;
        var ambientOcclusionColor:Vec3;
        var microSurface:Float;
        var surfaceReflectivityColor:Vec3;
        var metallicRoughness:Vec2;
        var roughness:Float;
        var NdotVUnclamped:Float;
        var NdotV:Float;
        var environmentRadiance:Vec4;
        var environmentIrradiance:Vec3;
        var debugVar:Vec4;

		function __init__() {
			relativePosition = input.position;
			transformedPosition = relativePosition * global.modelView.mat3x4();
			projectedPosition = vec4(transformedPosition, 1) * camera.viewProj;
			transformedNormal = (input.normal * global.modelView.mat3()).normalize();
			camera.dir = (camera.position - transformedPosition).normalize();
			pixelColor = color;
			specPower = specularPower;
			specColor = specularColor * specularAmount;
			screenUV = screenToUv(projectedPosition.xy / projectedPosition.w);
			depth = projectedPosition.z / projectedPosition.w;
			worldDist = length(transformedPosition - camera.position) / camera.zFar;
		}

        function vertex() {
			output.position = projectedPosition * vec4(1, camera.projFlip, 1, 1);


            // PI = 3.1415926535897932384626433832795;
            // LinearEncodePowerApprox  = 2.2;
            // GammaEncodePowerApprox  = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
            // LuminanceEncodeApprox  = vec3(0.2126,0.7152,0.0722);
            // LuminanceEncodeApproxX  = 0.2126;
            // LuminanceEncodeApproxY = 0.7152;
            // LuminanceEncodeApproxZ  = 0.0722;
            // Epsilon = 0.0000001;
    
            rgbdMaxRange = 255.0;
    
            var positionUpdated = input.position; //vec3
            var normalUpdated = input.normal; //vec3
            var finalWorld = global.modelView;//world; //mat4
            var worldPos = vec4(positionUpdated, 1.0) * finalWorld; //vec4 // finalWorld * vec4(positionUpdated, 1.0)
            vPositionW = vec3(transformedPosition.r, transformedPosition.b, transformedPosition.g);//vec3(worldPos.rgb);
            var normalWorld = mat3(finalWorld); //mat3
            var tmpNormal = normalUpdated * normalWorld;
            vNormalW = normalize(vec3(tmpNormal.r, tmpNormal.b, tmpNormal.g)); // normalize(normalWorld * normalUpdated);
            var uv2 = vec2(0., 0.); //vec2
            vEyePosition = vec3(camera.position.r, camera.position.b, camera.position.g); //camera.position;//
        }

        function fragment() {
            debugVar = vec4(0, 0, 0, 1);
            positionW = vPositionW;
            rawVNormalW = vNormalW;

            PI = 3.1415926535897932384626433832795;
            MINIMUMVARIANCE = 0.0005;
            
            LinearEncodePowerApprox  = 2.2;
            GammaEncodePowerApprox  = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
            LuminanceEncodeApprox  = vec3(0.2126,0.7152,0.0722);
            LuminanceEncodeApproxX  = 0.2126;
            LuminanceEncodeApproxY = 0.7152;
            LuminanceEncodeApproxZ  = 0.0722;
            Epsilon = 0.0000001;
    
            rgbdMaxRange = 255.0;
    
            viewDirectionW = normalize(vEyePosition.xyz - positionW); //vec3 // 
            uvOffset = vec2(0.0, 0.0); //vec2
        
			// output.depth = depth;
			// output.normal = transformedNormal;
			// output.worldDist = worldDist;

        }
	};

	public function new() {
        super();
        setPriority( -1 );
	}

}
