package h3d.shader.pbrsinglepass;

class SpecEnvReflect extends hxsl.Shader {

	static var SRC = {

        var ambientMonochrome:Float;
        var specularEnvironmentReflectance:Vec3;

        var NdotVUnclamped:Float;

        var testvar:Vec4;
        
        function square(value:Float):Float {
            return value*value;
        }

        function environmentRadianceOcclusion(ambientOcclusion:Float, NdotVUnclamped:Float):Float {
            var temp = NdotVUnclamped + ambientOcclusion; //float
            return saturate(square(temp) - 1.0 + ambientOcclusion);
        }

        function fragment() {
            var seo = environmentRadianceOcclusion(ambientMonochrome, NdotVUnclamped); //float
            specularEnvironmentReflectance *= seo;

            // testvar = vec4(vec3(NdotVUnclamped), 1);
        }
	}
}