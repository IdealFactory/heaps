package h3d.shader.pbr;

class PropsTexture extends hxsl.Shader {
	static var SRC = {
		@const var hasEmissiveMap : Bool;
		@const var hasOcclusionMap : Bool;
		@param var texture : Sampler2D;
		@param var emissiveMap : Sampler2D;
		@param var occlusionMap : Sampler2D;
		@param var emissive : Float;
		var output : {
			metalness : Float,
			roughness : Float,
			occlusion : Float,
			emissive : Float,
		};
		var calculatedUV : Vec2;
		function fragment() {
			var v = texture.get(calculatedUV);
			var vE = emissiveMap.get(calculatedUV);
			var vO = occlusionMap.get(calculatedUV);
			output.metalness = v.b;
			output.roughness = v.g;
			if (hasOcclusionMap)
				output.occlusion = vO.r;
			else
				output.occlusion = v.r;
			// if (hasEmissiveMap)
			// 	output.emissive = vE.rgb * v.a;
			// else
				output.emissive = emissive * v.a;
		}
	}
	public function new(?t, ?e, ?o ) {
		super();
		this.texture = t;
		if (e != null) this.hasEmissiveMap = true;
		this.emissiveMap = e != null ? e : h3d.mat.Texture.fromColor( 0x0 );
		if (o != null) this.hasOcclusionMap = true;
		this.occlusionMap = o != null ? o : h3d.mat.Texture.fromColor( 0x0 );
	}
}
