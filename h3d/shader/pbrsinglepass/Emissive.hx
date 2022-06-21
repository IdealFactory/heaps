package h3d.shader.pbrsinglepass;

class Emissive extends PBRSinglePassLib {

	static var SRC = {

        @param var uEmissiveColor : Vec3; 
        
        @keep var finalEmissive:Vec3;
        var lightingIntensity:Vec4;

        @keep var vEmissiveColor : Vec3; 

        function __init__fragment() {
            glslsource("// Emmissive-InitFragment");

            vEmissiveColor = uEmissiveColor;
        }

        function fragment() {
            glslsource("// Emmissive-Fragment");

            finalEmissive = vEmissiveColor;
            finalEmissive *= lightingIntensity.y;
          }
    }
    
    public function new() {
        super(); 

        this.uEmissiveColor.set( 0, 0, 0 );
    }
}