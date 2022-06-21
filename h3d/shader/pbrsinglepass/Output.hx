package h3d.shader.pbrsinglepass;

class Output extends PBRSinglePassLib {

	static var SRC = {

        // @param var uvisibility : Float;
        // @param var uexposureLinear : Float;
        // @param var ucontrast : Float;
        
        // @const var debug : Bool;

		var output : {
			// var position : Vec4;
			var color : Vec4;
		};

        // function applyImageProcessing(result:Vec4):Vec4 {
        //     result.rgb *= exposureLinear;
        //     result.rgb = toGammaSpace(result.rgb);
        //     result.rgb = saturate(result.rgb);   
        //     var resultHighContrast:Vec3 = result.rgb * result.rgb * (3.0 - 2.0 * result.rgb);
        //     if (contrast<1.0) {
        //         result.rgb=mix(vec3(0.5,0.5,0.5),result.rgb,contrast);
        //     } else {
        //         result.rgb=mix(result.rgb,resultHighContrast,contrast-1.0);
        //     }
        //     return result;
        // }

        // @keep @keepv var screenUV : Vec2;
        
        // var positionW:Vec3;
        
        // @keep var alpha:Float;
        // var finalAmbient:Vec3;
        // var finalDiffuse:Vec3;
        // var finalIrradiance:Vec3;
        // var finalRadianceScaled:Vec3;
        // // var finalSheenScaled:Vec3;
        // // var finalSheenRadianceScaled:Vec3;
        // var finalSpecularScaled:Vec3;
        // var finalClearCoatScaled:Vec3;
        // @keep var finalEmissive:Vec3;
        // var lightingIntensity:Vec4;

        // var ccOutFinalClearCoatRadianceScaled:Vec3;
 
        @keep var finalColor : Vec4;
        // @keep var visibility : Float;
        // @keep var exposureLinear : Float;
        // @keep var contrast : Float;

        // function __init__fragment() {
        //     glslsource("// Output __init__fragment");

        //     visibility = uvisibility;
        //     exposureLinear = uexposureLinear;
        //     contrast = ucontrast;
        // }


		function fragment() {
            // var finalColor = vec4(
            //     finalAmbient +
            //     finalDiffuse + 
            //     finalIrradiance +
            //     // finalSheenScaled +
            //     finalClearCoatScaled +
            //     finalSpecularScaled + 
            //     finalRadianceScaled +
            //     // finalSheenRadianceScaled +
            //     ccOutFinalClearCoatRadianceScaled + 
            //     finalEmissive,
            //     alpha);
            // finalColor = max(finalColor, 0.0);
            // finalColor = applyImageProcessing(finalColor);

            // if (debug) {
            //     if (output.position.x>0) {
            //         finalColor.rgb = debugVar.rgb;
            //     }
            // }
 
            // finalColor.a *= visibility;
            // pixelColor = finalColor;

            // if (debug) {
                // if (output.position.x > 0.0) {
                //     finalColor.rgb = debugVar.rgb;
                //     finalColor.a = 0.5;
                // }
            // }


//             glslsource("
//     // Output fragment
//     finalColor = vec4(
//     finalAmbient +
//     finalDiffuse +
//     finalIrradiance +
//     finalRadianceScaled +
//     finalEmissive, alpha);

//     finalColor = max(finalColor, 0.0);
//     finalColor = applyImageProcessing(finalColor);
//     finalColor.a *= visibility;
//     // debugVar.rgb = aoOut.ambientOcclusionColorMap.rgb;
//     // debugVar.rgb = reflectionOut.environmentIrradiance.rgb;
//     // debugVar.rgb = texture(ambientSampler, vAmbientUV+uvOffset).rgb;

//     // if (screenUV.x > 0.5) {
//     //     finalColor.rgb = toGammaSpace(debugVar.rgb);
//     //     finalColor.a = 1.0;
//     // }
// ");

            // output.color = vec4(finalColor.rgb, finalColor.a);
            output.color = finalColor;

       }
    }
    
    public function new() {
        super();

        // this.uvisibility = 1;
        // this.uexposureLinear = 1;
        // this.ucontrast = 1;
        // this.debug = true;
    }
}