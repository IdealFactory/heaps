package h3d.shader.pbrsinglepass;

class SpecEnvReflectMap extends hxsl.Shader {

	static var SRC = {

        var viewDirectionW:Vec3;
        var normalW:Vec3;
        var geometricNormalW:Vec3;
        var ambientMonochrome:Float;
        var specularEnvironmentReflectance:Vec3;

        var NdotVUnclamped:Float;
        var seo:Float;
        var eho:Float;

        function square(value:Float):Float {
            return value*value;
        }

        function environmentRadianceOcclusion(ambientOcclusion:Float, NdotVUnclamped:Float):Float {
            var temp = NdotVUnclamped + ambientOcclusion; //float
            return saturate(square(temp) - 1.0 + ambientOcclusion);
        }

       function environmentHorizonOcclusion(view:Vec3, normal:Vec3, geometricNormal:Vec3):Float {
            var reflection = reflect(view, normal); //vec3
            var temp = saturate(1.0 + 1.1 * dot(reflection, geometricNormal)); //float
            return square(temp);
        }
         
        function fragment() {
            seo = environmentRadianceOcclusion(ambientMonochrome, NdotVUnclamped); //float
            eho = environmentHorizonOcclusion(-viewDirectionW, normalW, geometricNormalW); //float
            specularEnvironmentReflectance *= seo;
            specularEnvironmentReflectance *= eho;
        }
	}
}