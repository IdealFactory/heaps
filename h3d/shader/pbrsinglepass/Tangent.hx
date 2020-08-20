package h3d.shader.pbrsinglepass;

class Tangent extends PBRSinglePassLib {

	static var SRC = {
        
		@global var global : {
			@perObject var modelView : Mat4;
		};

		@input var input : {
            var normal : Vec3;                                        // attribute vec4 tangent;    
            var tangent : Vec4;                                        // attribute vec4 tangent;    
        }

        @param var bumpSampler : Sampler2D;                             // uniform sampler2D bumpSampler;
        @param var vBumpInfos : Vec3;                                   // uniform vec3 vBumpInfos;

        @var var vTBN : Mat3;
        
        var finalWorld:Mat4;
        var normalUpdated:Vec3;
        var normalW:Vec3;
        var TBN:Mat3;
        
        function vertex() {
            var tangentUpdated = input.tangent;
            var tbnNormal = normalize(normalUpdated);
            var tbnTangent = normalize(tangentUpdated.xyz);
            var tbnBitangent = cross(tbnNormal, tbnTangent) * tangentUpdated.w;
            vTBN = finalWorld.mat3() #if !flash * mat3(tbnTangent, tbnBitangent, tbnNormal) #end;
        }

        function fragment() {
            TBN = vTBN;
            var pt = perturbNormal(TBN, bumpSampler.get(vMainUV1).xyz, vBumpInfos.y);
            normalW = vec3(pt.x, -pt.z, -pt.y);
        }
    };

	public function new() {
        super();

        this.vBumpInfos.set( 0, 1, 0.0500 );
    }
}