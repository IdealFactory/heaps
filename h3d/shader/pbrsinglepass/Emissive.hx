package h3d.shader.pbrsinglepass;

class Emissive extends hxsl.Shader {

	static var SRC = {

        @param var vEmissiveColor : Vec3; 
        
        var finalEmissive:Vec3;

        function fragment() {
            finalEmissive = vEmissiveColor;
          }
    }
    
    public function new() {
        super(); 

        this.vEmissiveColor.set( 1, 1, 1 );
    }
}