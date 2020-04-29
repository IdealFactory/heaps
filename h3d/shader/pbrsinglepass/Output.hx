package h3d.shader.pbrsinglepass;

class Output extends hxsl.Shader {

	static var SRC = {

        @param var vLightingIntensity : Vec4;
        @param var visibility : Float;
        @param var exposureLinear : Float;
        @param var contrast : Float;

        var GammaEncodePowerApprox : Float;

        var ambientOcclusionColor:Vec3;
        var ambientOcclusionForDirectDiffuse:Vec3;
        
        var alpha:Float;
        var finalAmbient:Vec3;
        var finalDiffuse:Vec3;
        var finalIrradiance:Vec3;
        var finalRadianceScaled:Vec3;
        var finalSpecularScaled:Vec3;
        var finalEmissive:Vec3;

        // var output : {
		// 	color : Vec4
        // };
        
        var pixelColor : Vec4;

        function saturateVec3(x:Vec3):Vec3 { 
            return clamp(x,0.0,1.0);
        }

        function toGammaSpaceVec3(color:Vec3):Vec3 {
            return pow(color,vec3(GammaEncodePowerApprox));
        }

        function applyImageProcessing(result:Vec4):Vec4 {
            result.rgb *= exposureLinear;
            result.rgb = toGammaSpaceVec3(result.rgb);
            result.rgb = saturateVec3(result.rgb);
            var resultHighContrast = result.rgb*result.rgb*(3.0-2.0*result.rgb);
            if (contrast<1.0) {
                result.rgb = mix(vec3(0.5, 0.5, 0.5), result.rgb, contrast);
            } else {
                result.rgb = mix(result.rgb, resultHighContrast, contrast-1.0);
            }
    
            return result;
        }
           
		function fragment() {
            var finalColor = vec4(
                finalAmbient * ambientOcclusionColor +
                finalDiffuse * ambientOcclusionForDirectDiffuse * vLightingIntensity.x +
                finalIrradiance * ambientOcclusionColor * vLightingIntensity.z +
                finalSpecularScaled + 
                finalRadianceScaled +
                finalEmissive * vLightingIntensity.y,
                alpha);
            finalColor = max(finalColor, 0.0);
            finalColor = applyImageProcessing(finalColor);
            finalColor.a *= visibility;
            pixelColor = finalColor;
        }
    }
    
    public function new() {
        super();

        this.vLightingIntensity.set( 1, 1, 1, 1 );
        this.visibility = 1;
        this.exposureLinear = 0.8;
        this.contrast = 1.2;
    }
}