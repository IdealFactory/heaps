package h3d.shader;

class GLTFMorphTarget extends hxsl.Shader {

	static var SRC = {

        @input var input : {
			var targetPosition_1 : Vec3;
			var targetNormal_1 : Vec3;
            //var targetTangent : Vec3;
		};

        @param var weight : Float;
        
		var relativePosition : Vec3;
        var relativeNormal : Vec3;
        //var transformedTangent : Vec4;

		function vertex() {
			relativePosition += input.targetPosition_1 * weight;
			relativeNormal += input.targetNormal_1 * weight;
            //transformedTangent += vec4(input.targetTangent * weight, 0);
        }
	};

	public function new( weight = 0. ) {
		super();
		this.weight = weight;
	}

}


