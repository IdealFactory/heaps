package h3d.shader.pbrsinglepass;

class SpecEnvReflectMap extends PBRSinglePassLib {

	static var SRC = {

        var viewDirectionW:Vec3;
        var normalW:Vec3;
        var geometricNormalW:Vec3;
        var ambientMonochrome:Float;
        var specularEnvironmentReflectance:Vec3;

        var NdotVUnclamped:Float;
        var seo:Float;
        var eho:Float;

        function fragment() {
            // seo = environmentRadianceOcclusion(ambientMonochrome, NdotVUnclamped); //float
            // eho = environmentHorizonOcclusion(-viewDirectionW, normalW, geometricNormalW); //float
            // specularEnvironmentReflectance *= seo;
            // specularEnvironmentReflectance *= eho;

            glslsource("
            ");
        }
	}
}