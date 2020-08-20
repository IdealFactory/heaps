package h3d.shader.pbrsinglepass;

class Output extends PBRSinglePassLib {

	static var SRC = {

        @param var visibility : Float;
        @param var exposureLinear : Float;
        @param var contrast : Float;
        
        @const var debug : Bool;

        var output : {
			var position : Vec4;
		};

        var positionW:Vec3;
        
        var alpha:Float;
        var finalAmbient:Vec3;
        var finalDiffuse:Vec3;
        var finalIrradiance:Vec3;
        var finalRadianceScaled:Vec3;
        var finalSheenScaled:Vec3;
        var finalSheenRadianceScaled:Vec3;
        var finalSpecularScaled:Vec3;
        var finalClearCoatScaled:Vec3;
        var finalEmissive:Vec3;
        var lightingIntensity:Vec4;

        var ccOutFinalClearCoatRadianceScaled:Vec3;
 
        var pixelColor : Vec4;
           
		function fragment() {
            var finalColor = vec4(
                finalAmbient +
                finalDiffuse + 
                finalIrradiance +
                finalSheenScaled +
                finalClearCoatScaled +
                finalSpecularScaled + 
                finalRadianceScaled +
                finalSheenRadianceScaled +
                ccOutFinalClearCoatRadianceScaled + 
                finalEmissive,
                alpha);
            finalColor = max(finalColor, 0.0);
            finalColor = applyImageProcessing(finalColor);

            if (debug) {
                if (output.position.x>0) {
                    finalColor.rgb = debugVar.rgb;
                }
            }
 
            finalColor.a *= visibility;
            pixelColor = finalColor;
        }
    }
    
    public function new() {
        super();

        this.visibility = 1;
        this.exposureLinear = 1;
        this.contrast = 1;
        this.debug = false;
    }
}