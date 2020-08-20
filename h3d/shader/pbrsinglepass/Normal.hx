package h3d.shader.pbrsinglepass;

class Normal extends PBRSinglePassLib {

	static var SRC = {
        
        var normalW:Vec3;
        
		function fragment() {
            normalW = normalize(vNormalW);
        }
    };

	public function new() {
        super();
    }
}