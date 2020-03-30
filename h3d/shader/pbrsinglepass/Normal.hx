package h3d.shader.pbrsinglepass;

class Normal extends hxsl.Shader {

	static var SRC = {
        
        @var var vNormalW : Vec3;
        
        var normalW:Vec3;
        
		function fragment() {
            normalW = normalize(vNormalW);
        }
    };

	public function new() {
        super();
    }
}