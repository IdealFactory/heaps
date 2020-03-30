package h3d.shader.pbrsinglepass;

class SpecEnvReflectMap extends hxsl.Shader {

	static var SRC = {

        var viewDirectionW:Vec3;
        var normalW:Vec3;
        var ambientMonochrome:Float;
        var specularEnvironmentReflectance:Vec3;

        var NdotVUnclamped:Float;

        function square(value:Float):Float {
            return value*value;
        }

        function environmentRadianceOcclusion(ambientOcclusion:Float, NdotVUnclamped:Float):Float {
            var temp = NdotVUnclamped + ambientOcclusion; //float
            return saturate(square(temp) - 1.0 + ambientOcclusion);
        }

        function environmentHorizonOcclusion(view:Vec3, normal:Vec3):Float {
            var reflection = reflect(view, normal); //vec3
            var temp = saturate(1.0 + 1.1 * dot(reflection, normal)); //float
            return square(temp);
        }
        
        function fragment() {
            var seo = environmentRadianceOcclusion(ambientMonochrome, NdotVUnclamped); //float
            specularEnvironmentReflectance *= seo;
            var eho = environmentHorizonOcclusion(-viewDirectionW, normalW); //float
            specularEnvironmentReflectance *= eho;
        }
	}
}