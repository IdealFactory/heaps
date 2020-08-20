package h3d.shader.pbrsinglepass;

class AmbientOcclusion extends PBRSinglePassLib {

	static var SRC = {

        var ambientOcclusionColor:Vec3;
        var ambientInfos:Vec4;
        var ambientOcclusionForDirectDiffuse:Vec3;

        function fragment() {
            ambientOcclusionColor = vec3(1., 1., 1.); //vec3
            ambientInfos = vAmbientInfos;
            
            ambientOcclusionForDirectDiffuse = ambientOcclusionColor; 
        }
	}
}