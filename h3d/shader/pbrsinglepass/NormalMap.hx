package h3d.shader.pbrsinglepass;

class NormalMap extends PBRSinglePassLib {

	static var SRC = {
        
        @param var bumpSampler : Sampler2D;                             // uniform sampler2D bumpSampler;
        @param var vBumpInfos : Vec3;                                   // uniform vec3 vBumpInfos;

        var normalW:Vec3;
        var positionW:Vec3;
        var viewDirectionW:Vec3;

        var NdotVUnclamped:Float;
        var NdotV:Float;
        var AARoughnessFactors:Vec2;

 		function fragment() {
            var TBN = cotangent_frameWithTS(normalW, positionW, vMainUV1, vec2(1.,-1.)); //mat3 // vBumpUV -> vMainUV1
            var bmp = bumpSampler.get(vMainUV1);
            var pt = perturbNormal(TBN, bmp.xyz, vBumpInfos.y);
            normalW = vec3(pt.x, pt.y, pt.z);

            NdotVUnclamped = dot(normalW, viewDirectionW);
            NdotV = absEps(NdotVUnclamped);
            AARoughnessFactors = getAARoughnessFactors(normalW.xyz);
        }
    };

	public function new() {
        super();

        this.vBumpInfos.set( 0, 1, 0.0500 );
    }
}