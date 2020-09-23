package h3d.pass;

class PBRSinglePass extends Default {

	public var environmentBrdf : h3d.mat.Texture;
	var environmentBrdfId : Int;

	public var reflectionCubeMap : h3d.mat.Texture;
	var reflectionCubeMapId : Int;

	public function new(name) {
		super(name);

		environmentBrdfId = hxsl.Globals.allocID("environmentBrdfSampler");
		reflectionCubeMapId = hxsl.Globals.allocID("reflectionSampler");
	}

	override function draw( passes, ?sort ) {

		ctx.setGlobalID(environmentBrdfId, environmentBrdf );
		ctx.setGlobalID(reflectionCubeMapId, reflectionCubeMap );

		super.draw(passes, sort);
	}
}