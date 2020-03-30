package h3d.shader.pbrsinglepass;

class AmbientOcclusion extends hxsl.Shader {

	static var SRC = {

        var ambientOcclusionColor:Vec3;
        var ambientOcclusionForDirectDiffuse:Vec3;

        function fragment() {
            ambientOcclusionForDirectDiffuse = ambientOcclusionColor; 
        }
	}
}