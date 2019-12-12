package h3d.shader;

class Skin4 extends SkinBase {

	static var SRC = {

		@input var input : {
			var position : Vec3;
			var normal : Vec3;
			var weights : Vec4;
			var indexes : Bytes4;
		};

		var transformedTangent : Vec4;

		function vertex() {
			// transformedPosition =
			// 	(relativePosition * bonesMatrixes[input.indexes.x]) * input.weights.x +
			// 	(relativePosition * bonesMatrixes[input.indexes.y]) * input.weights.y +
			// 	(relativePosition * bonesMatrixes[input.indexes.z]) * input.weights.z +
			// 	(relativePosition * bonesMatrixes[input.indexes.w]) * input.weights.w;
			var rp:Vec4 = vec4(relativePosition, 1.0);
			transformedPosition =
				((rp * bonesMatrixes[input.indexes.x]) * input.weights.x +
				(rp * bonesMatrixes[input.indexes.y]) * input.weights.y +
				(rp * bonesMatrixes[input.indexes.z]) * input.weights.z +
				(rp * bonesMatrixes[input.indexes.w]) * input.weights.w).xyz;
			transformedNormal = normalize(
				(input.normal * mat3(bonesMatrixes[input.indexes.x])) * input.weights.x +
				(input.normal * mat3(bonesMatrixes[input.indexes.y])) * input.weights.y +
				(input.normal * mat3(bonesMatrixes[input.indexes.z])) * input.weights.z +
				(input.normal * mat3(bonesMatrixes[input.indexes.w])) * input.weights.w);
		}

	};

}