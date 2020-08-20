package h3d.shader.pbrsinglepass;

class Emissive extends PBRSinglePassLib {

	static var SRC = {

        @param var vEmissiveColor : Vec3; 
        
        var finalEmissive:Vec3;
        var lightingIntensity:Vec4;

        function fragment() {
            finalEmissive = vEmissiveColor;
            finalEmissive *= lightingIntensity.y;
          }
    }
    
    public function new() {
        super(); 

        this.vEmissiveColor.set( 0, 0, 0 );
    }
}