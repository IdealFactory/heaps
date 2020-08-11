package h3d.shader.pbrsinglepass;

class NormalMap extends hxsl.Shader {

	static var SRC = {
        
        @param var bumpSampler : Sampler2D;                             // uniform sampler2D bumpSampler;

        @var var vMainUV1 : Vec2;                                       // varying vec2 vMainUV1;
        
        @param var vBumpInfos : Vec3;                                   // uniform vec3 vBumpInfos;

        var normalW:Vec3;
        var positionW:Vec3;

        function cotangent_frameWithTS(normal:Vec3, p:Vec3, uv:Vec2, tangentSpaceParams:Vec2):Mat3 {
            uv = uv;// gl_FrontFacing ? uv : -uv;
            var dp1:Vec3 = dFdx(p); //vec3
            var dp2:Vec3 = dFdy(p); //vec3
            var duv1:Vec2 = dFdx(uv); //vec2
            var duv2:Vec2 = dFdy(uv); //vec2
            var dp2perp:Vec3 = cross(dp2, normal); //vec3 cross( dFdy(vPositionW), vNormal )
            var dp1perp:Vec3 = cross(normal, dp1); //vec3
            var tangent:Vec3 = dp2perp * duv1.x + dp1perp * duv2.x; //vec3
            var bitangent:Vec3 = dp2perp * duv1.y + dp1perp * duv2.y; //vec3
            tangent *= tangentSpaceParams.x;
            bitangent *= tangentSpaceParams.y;
            var invmax = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent))); //float
            return mat3(tangent * invmax, bitangent * invmax, normal);
        }

        function perturbNormal(cotangentFrame:Mat3, textureSample:Vec3, scale:Float):Vec3 {
            textureSample = textureSample * 2.0 - 1.0;
            textureSample = normalize(vec3(textureSample.x, textureSample.y, textureSample.z) * vec3(scale, scale, 1.0));
            return normalize( cotangentFrame * textureSample ); 
        }

		function fragment() {
            var TBN = cotangent_frameWithTS(normalW, positionW, vMainUV1, vec2(1.,-1.)); //mat3 // vBumpUV -> vMainUV1
            var bmp = bumpSampler.get(vMainUV1);
            var pt = perturbNormal(TBN, bmp.xyz, vBumpInfos.y);
            normalW = vec3(pt.x, pt.y, pt.z);
        }
    };

	public function new() {
        super();

        this.vBumpInfos.set( 0, 1, 0.0500 );
    }
}