package hxsl;
using hxsl.Ast;

private class AllocatedVar {
	public var id : Int;
	public var v : TVar;
	public var path : String;
	public var merged : Array<TVar>;
	public var kind : Null<FunctionKind>;
	public var parent : AllocatedVar;
	public var rootShaderName : String;
	public var instanceIndex : Int;
	public function new() {
	}
}

private class ShaderInfos {
	static var UID = 0;
	public var uid : Int;
	public var name : String;
	public var priority : Int;
	public var body : TExpr;
	public var usedFunctions : Array<TFunction>;
	public var deps : Map<ShaderInfos, Bool>;
	public var read : Map<Int,AllocatedVar>;
	public var write : Map<Int,AllocatedVar>;
	public var processed : Map<Int, Bool>;
	public var vertex : Null<Bool>;
	public var onStack : Bool;
	public var hasDiscard : Bool;
	public var sources : Array<Int>;
	public var hasSource : Bool;
	public var hasKeptVars : Bool;
	public var marked : Null<Bool>;
	public function new(n, v) {
		this.name = n;
		this.uid = UID++;
		this.vertex = v;
		processed = new Map();
		usedFunctions = [];
		read = new Map();
		write = new Map();
		sources = [];
		hasSource = false;
		hasKeptVars = false;
	}
}

typedef ShaderSource = {
	src:String,
	shader:ShaderInfos
}

class Linker {

	public var allVars : Array<AllocatedVar>;
	var varMap : Map<String,AllocatedVar>;
	var curShader : ShaderInfos;
	var shaders : Array<ShaderInfos>;
	var varIdMap : Map<Int,Int>;
	var locals : Map<Int,Bool>;
	var glsources : Map<String, Array<ShaderSource>>;
	var glvfuncs : Map<String, TGLSLFunc>;
	var glffuncs : Map<String, TGLSLFunc>;
	var curInstance : Int;
	var batchMode : Bool;
	var isBatchShader : Bool;
	var debugDepth = 0;

	public function new(batchMode=false) {
		this.batchMode = batchMode;
	}

	inline function debug( msg : String, ?pos : haxe.PosInfos ) {
		#if shader_debug_dump
		if( Cache.TRACE ) {
			for( i in 0...debugDepth ) msg = "    " + msg; haxe.Log.trace(msg, pos);
		}
		#end
	}

	function error( msg : String, p : Position ) : Dynamic {
		return Error.t(msg, p);
	}

	function mergeVar( path : String, v : TVar, v2 : TVar, p : Position, shaderName : String ) {
		switch( v.kind ) {
		case Global, Input, Var, Local, Output:
			// shared vars
		case Param if ( shaderName != null && v2.hasBorrowQualifier(shaderName) ):
			// Other variable attempts to borrow.
		case Param, Function:
			throw "assert";
		}
		if( v.kind != v2.kind && v.kind != Local && v2.kind != Local )
			error("'" + path + "' kind does not match : " + v.kind + " should be " + v2.kind,p);
		switch( [v.type, v2.type] ) {
		case [TStruct(fl1), TStruct(fl2)]:
			for( f1 in fl1 ) {
				var ft = null;
				for( f2 in fl2 )
					if( f1.name == f2.name ) {
						ft = f2;
						break;
					}
				// add a new field
				if( ft == null )
					fl2.push(allocVar(f1,p, shaderName).v);
				else
					mergeVar(path + "." + ft.name, f1, ft, p, shaderName);
			}
		default:
			if( !v.type.equals(v2.type) )
				error("'" + path + "' type does not match : " + v.type.toString() + " should be " + v2.type.toString(),p);
		}
	}

	function allocVar( v : TVar, p : Position, ?shaderName : String, ?path : String, ?parent : AllocatedVar ) : AllocatedVar {
		if( v.parent != null && parent == null ) {
			parent = allocVar(v.parent, p, shaderName);
			var p = parent.v;
			path = p.name;
			p = p.parent;
			while( p != null ) {
				path = p.name + "." + path;
				p = p.parent;
			}
		}
		var key = (path == null ? v.name : path + "." + v.name);
		if( v.qualifiers != null )
			for( q in v.qualifiers )
				switch( q ) {
				case Name(n): key = n;
				default:
				}
		var v2 = varMap.get(key);
		var vname = v.name;
		// trace("VName="+vname+" v2="+v2);
		// if(vname.indexOf("Sampler")>-1){
		// 	trace("AllocVar: got sampler="+vname);
		// }
		if( v2 != null ) { // && !v2.v.hasQualifier(Keep) ) {
			for( vm in v2.merged ) {
				// if (v.name == "vAlbedoColor" && vm.name == "vAlbedoColor")
					// trace("AllocVar: check:\nv:"+v+"\nvm:"+vm);
				if( vm == v || ((v.hasQualifier(Keep) || v.hasQualifier(KeepV)) && vm.name == v.name)) {
					// trace("AllocVar: already merged v="+v2.v.name+" v.id="+v2.id+" path="+v2.path+" inst="+v2.instanceIndex+" shdr="+v2.rootShaderName+" par="+(v2.parent==null ? "null" : v2.parent.v.name+"("+v2.parent.id+")"));
					return v2;
				}
			}
			function isUnique( v : TVar, borrowed : Bool ) {
				var isUn = (v.kind == Param && !borrowed && !v.hasQualifier(Shared) && !isBatchShader) || v.kind == Function || ((v.kind == Var || v.kind == Local) && v.hasQualifier(Private) );
				// trace("isUnique test: v="+v.name+" isUniqu="+isUn);
				return isUn;
			}
			if( isUnique(v, v2.v.hasBorrowQualifier(shaderName)) || isUnique(v2.v, v.hasBorrowQualifier(v2.rootShaderName)) || (v.kind == Param && v2.v.kind == Param) /* two shared : one takes priority */ ) {
				// allocate a new unique name in the shader if already in use
				var k = 2;
				while( true ) {
					var a = varMap.get(key + k);
					if( a == null ) break;
					for( vm in a.merged )
						if( vm == v ) {
							// trace("AllocVar: indexed mergerd v="+a.v.name+" v.id="+a.id+" path="+a.path+" inst="+a.instanceIndex+" shdr="+a.rootShaderName+" par="+(a.parent==null ? "null" : a.parent.v.name+"("+a.parent.id+")"));
							return a;
						}
					k++;
				}
				vname += k;
				key += k;
			} else {
				v2.merged.push(v);
				mergeVar(key, v, v2.v, p, v2.rootShaderName);
				varIdMap.set(v.id, v2.id);
				// trace("AllocVar: existing v="+v2.v.name+" v.id="+v2.id+" path="+v2.path+" inst="+v2.instanceIndex+" shdr="+v2.rootShaderName+" par="+(v2.parent==null ? "null" : v2.parent.v.name+"("+v2.parent.id+")"));
				return v2;
			}
		}
		var vid = allVars.length + 1;
		var v2 : TVar = {
			id : vid,
			name : vname,
			type : v.type,
			kind : v.kind,
			qualifiers : v.qualifiers,
			parent : parent == null ? null : parent.v,
		};
		var a = new AllocatedVar();
		a.v = v2;
		a.merged = [v];
		a.path = key;
		a.id = vid;
		a.parent = parent;
		a.instanceIndex = curInstance;
		a.rootShaderName = shaderName;
		allVars.push(a);
		varMap.set(key, a);
		switch( v2.type ) {
		case TStruct(vl):
			v2.type = TStruct([for( v in vl ) allocVar(v, p, shaderName, key, a).v]);
		default:
		}
		trace("AllocVar: new a="+a.v.name+" a.id="+a.id+" path="+a.path+" inst="+a.instanceIndex+" shdr="+a.rootShaderName+" par="+(a.parent==null ? "null" : a.parent.v.name+"("+a.parent.id+")"));
		return a;
		// }
		// trace("allocVar returning V2="+v2);
		// return v2;
	}

	function mapExprVar( e : TExpr ) {
		// trace("MapExprVar:"+e.e);
		switch( e.e ) {
		case TVar(v) if( !locals.exists(v.id) ):
			// trace("MapExprVar-TVar1: v="+v.name);
			// if (v.name=="visibility" || v.name=="uvisibility") {
			// 	trace(" - A: processing visibility || uvisibility: "+e.e);
			// }
			var v = allocVar(v, e.p);
			if( curShader != null && !curShader.write.exists(v.id) || (v.v.qualifiers != null && (v.v.qualifiers.indexOf(Keep)>-1 || v.v.qualifiers.indexOf(KeepV)>-1))) {
				// trace(" - B: "+curShader.name + " read " + v.path);
				curShader.read.set(v.id, v);
				// if we read a varying, force into fragment
				if( curShader.vertex == null && v.v.kind == Var ) {
					// trace(" - C: Force " + curShader.name+" into fragment (use varying)");
					curShader.vertex = false;
				}
			}
			return { e : TVar(v.v), t : v.v.type, p : e.p };
		// case TVar(v) if (v.qualifiers != null && (v.qualifiers.indexOf(Keep)>-1 || v.qualifiers.indexOf(KeepV)>-1)):
		// 	trace("MapExprVar-TVar2: v="+v.name);
		// 	var v = allocVar(v, e.p);
		// 	if( curShader != null) {
		// 		curShader.hasKeptVars = true;
		// 		curShader.read.set(v.id, v);
		// 	}
		// 	// return { e : TVar(v.v), t : v.v.type, p : e.p };
		// case TVar(v):
		// 	trace("MapExprVar-TVar3: v="+v.name);
		case TBinop(op, e1, e2):
			switch( [op, e1.e] ) {
			case [OpAssign, TVar(v)] if( !locals.exists(v.id) ):
				// if (v.name=="visibility" || v.name=="uvisibility") {
				// 	trace(" - A: processing visibility || uvisibity: "+e.e);
				// }
				var e2 = mapExprVar(e2);
				var v = allocVar(v, e1.p);
				if( curShader != null ) {
					if (v.v.qualifiers != null && (v.v.qualifiers.indexOf(Keep)>-1 || v.v.qualifiers.indexOf(KeepV)>-1)) {
						curShader.hasKeptVars = true;
						var e1 = mapExprVar(e1);
						curShader.read.set(v.id, v);
					}
					// trace("MapExprVar-TBinop( !locals): "+curShader.name + " write " + v.path);
					curShader.write.set(v.id, v);
				}
				// don't read the var
				return { e : TBinop(op, { e : TVar(v.v), t : v.v.type, p : e.p }, e2), t : e.t, p : e.p };
			case [OpAssign | OpAssignOp(_), (TVar(v) | TSwiz( { e : TVar(v) }, _))] if( !locals.exists(v.id) ):
				// read the var
				// if (v.name=="visibility" || v.name=="uvisibility") {
				// 	trace(" - A: processing visbility || uvisibity: "+e.e);
				// }
				var e1 = mapExprVar(e1);
				var e2 = mapExprVar(e2);
				var v = allocVar(v, e1.p);
				if( curShader != null ) {
					// TODO : mark as partial write if SWIZ
					// trace("MapExprVar-TBinop( ... ): "+curShader.name + " write " + v.path);
					curShader.write.set(v.id, v);
				}
				return { e : TBinop(op, e1, e2), t : e.t, p : e.p };
			default:
			}
		case TDiscard:
			if( curShader != null ) {
				curShader.vertex = false;
				curShader.hasDiscard = true;
			}
		case TVarDecl(v, _):
			locals.set(v.id, true);
		case TFor(v, _, _):
			locals.set(v.id, true);
		case TGLSLSource(src):
			if( curShader != null ) {
				if (!glsources.exists(curShader.name)) {
					glsources.set(curShader.name, []);
				}
				var srcArr = glsources[curShader.name];
				var expr = { e : TGLSLSource(src), t : TVoid, p : null };
				var shader = addSource( curShader.name+"_src"+srcArr.length, curShader.name.indexOf("vertex")>-1 ? true : curShader.name.indexOf("fragment")>-1 ? false : null, expr, curShader.priority, false );
				shader.deps = new Map();
				srcArr.push( { src: src, shader: shader } );
				trace("MapExprVar-TGLSLSource: "+curShader.name + " src=" + src);
				curShader.hasSource = true;
			}
		default:
		}
		return e.map(mapExprVar);
	}

	function addShader( name : String, vertex : Null<Bool>, e : TExpr, p : Int, add : Bool = true ) {
		var parent = curShader;
		var s = new ShaderInfos(name, vertex);
		curShader = s;
		s.priority = p;
		s.body = mapExprVar(e);
		if (add) shaders.push(s);
		else {
			s.deps = new Map();
			parent.deps.set(s, true);
		}
		curShader = null;
		trace("AddShader: "+name+" Pri="+p);
		return s;
	}

	function addSource( name : String, vertex : Null<Bool>, e : TExpr, p : Int, add : Bool = true ) {
		var s = new ShaderInfos(name, vertex);
		s.priority = p;
		s.body = e;
		trace("AddSource: "+name+" Pri="+p);
		return s;
	}

	function sortByPriorityDesc( s1 : ShaderInfos, s2 : ShaderInfos ) {
		if( s1.priority == s2.priority )
			return s1.uid - s2.uid;
		return s2.priority - s1.priority;
	}

	function sortByPriorityAsc( s1 : ShaderInfos, s2 : ShaderInfos ) {
		if (s1.priority >= 0 ) {
			return 0;
			// if( s1.priority == s2.priority )
			// 	return 0;
			// return s1.priority - s2.priority;
		} else {
			if( s1.priority == s2.priority )
				return s1.uid - s2.uid;
			return s1.priority - s2.priority;
		}	
	}

	function buildDependency( s : ShaderInfos, v : AllocatedVar, isWritten : Bool ) {
		var found = !isWritten;
		trace("BuildDependency:  s="+s.name+" var="+v.v.name+" isWritten="+isWritten);
		var skipRemainingShaders = false;
		for( parent in shaders ) {
			trace(" - processing Shader: parent="+parent.name);
			// if (STOP) {
			// 	trace("STOP POINT!!!");
			// }
	
			if( parent == s ) {
				found = true;
				skipRemainingShaders = true;
				trace(" - - LEAVING EARLY shader same as parent....");
				continue;
			} if( !found ) {
				trace(" - - LEAVING EARLY shader not found....");
				continue;
			}

			var sourcesToAdd = [];
			if (parent.body.e != null) {
				var added = false;
				var srcCount = 0;
				function addKeptVars(e, lvl=0) {
					var str:String = cast e.e;
					switch( e.e ) {
						case TVar(v) if (v.qualifiers!=null && (v.qualifiers.indexOf(Keep)>-1 || v.qualifiers.indexOf(KeepV)>-1)):
							if (!s.deps.exists(parent)) {
								trace(" - - BD: TVar Kept :setting dep: "+parent.name+" (pri="+parent.priority+") v="+v.name+" k="+(v.qualifiers.indexOf(Keep)>-1)+" kV="+(v.qualifiers.indexOf(KeepV)>-1));
								s.deps.set(parent, true);
								parent.deps = new Map();
								// debugDepth++;
								// initDependencies(parent);
								// debugDepth--;
							}
							added = true;
						case TBinop(op, e1, e2):
							addKeptVars(e1, lvl++);
							addKeptVars(e2, lvl++);
						case TBlock(el):
							for( e1 in el ) addKeptVars(e1, lvl+1);
						case TGLSLSource(srcel):
							var src = null;
							trace("BD:TGLSLSource: s="+parent.name+" src-el="+srcel+" lvl="+lvl+" sourcesToAdd.length="+sourcesToAdd.length+" pri="+parent.priority);

							for (i in 0...glsources[parent.name].length) {
								var srcStr = glsources[parent.name][i].src;
								var shader = glsources[parent.name][i].shader;
								if (lvl==0 && srcel==srcStr) {
									trace("BD:AddingSource dependency: src="+shader.name+" (pri="+shader.priority+") s.vert="+shader.vertex+" src="+new Printer().exprString(shader.body));
									s.deps.set(shader, true);
									glsources[parent.name] = glsources[parent.name].splice(i, 1);
									break;
								}
							}
							// if (srcel=="// RGBDecode __init__fragment-1") {
							// 	trace("FOUND // RGBDecode __init__fragment-1");
							// }
							// Trying this to iterate over the added sources
							// if (sourcesToAdd.length>0 && lvl>0) {
							// 	var idx = sourcesToAdd.indexOf(srcel);
							// 	for (i in 0...idx) {
							// 		var srcStr = glsources[parent.name][i].src;
							// 		var prio = glsources[parent.name][i].priority;
							// 		var expr = { e : TGLSLSource(srcStr), t : TVoid, p : null };
							// 		var src = addSource( parent.name+"_src"+srcCount, parent.vertex, expr, prio, false );
							// 		src.deps = new Map();
							// 		s.deps.set(src, true);
							// 		trace("BD:AddingSource: src="+src.name+" (pri="+src.priority+") s.vert="+parent.vertex+" src="+new Printer().exprString(src.body));
							// 		srcCount++;
							// 		sourcesToAdd = sourcesToAdd.splice(i, 1);
							// 		trace(" - BD: removing from glsources  s="+parent.name+" src-el="+srcel);
							// 	}
							// 	sourcesToAdd.remove(srcel);
							// 	trace(" - BD: removing from glsources s="+parent.name+" src-el="+srcel);
							// // }
							
							// // THIS ONE KIND OF WORKED
							// if (glsources.exists(parent.name) && lvl>0) {
							// 	var idx = glsources[parent.name].indexOf(srcel);
							// 	for (i in 0...idx) {
							// 		var srcStr = glsources[parent.name][i];
							// 		var expr = { e : TGLSLSource(srcStr), t : TVoid, p : null };
							// 		var src = addSource( parent.name+"_src"+srcCount, parent.vertex, expr, parent.priority, false );
							// 		src.deps = new Map();
							// 		s.deps.set(src, true);
							// 		trace("BD:AddingSource: src="+src.name+" (pri="+src.priority+") s.vert="+parent.vertex+" src="+new Printer().exprString(src.body));
							// 		srcCount++;
							// 		glsources[parent.name] = glsources[parent.name].splice(i, 1);
							// 		trace(" - BD: removing from glsources  s="+parent.name+" src-el="+srcel);
							// 	}
							// 	glsources[parent.name].remove(srcel);
							// 	trace(" - BD: removing from glsources s="+parent.name+" src-el="+srcel);
							// }

							// if (parent.name.indexOf("Irradiance.vertex")>-1 || srcel.indexOf("// Irradiance vertex")>-1) {
							// 	trace(" - Have Irradiance vertex src: parent="+parent.name);
							// }
							// if (true) {
							// 	trace("BD:S.VERTEX="+s.vertex+" P.VERTEX="+parent.vertex+" match="+(s.vertex==parent.vertex)+" par="+parent.name+" lvl="+lvl+" srcel="+srcel);
							// 	if (!glsources.exists(parent.name))
							// 		glsources.set(parent.name, []);
								
							// 	var srcArr = glsources[parent.name];
							// 	var found = false;
								
							// 	if (s.vertex==parent.vertex) {
							// 		src = addSource( parent.name+srcArr.length, parent.vertex, { e : e.e, t : e.t, p : e.p }, parent.priority, false );
							// 		// s.hasSource = false;
							// 		src.deps = new Map();
							// 		srcArr.push(src);
							// 		trace(" - - BD: src="+src.name+" lvl="+lvl+" cnt="+srcCount+" (pri="+src.priority+") parent="+parent.name+" src="+new Printer().exprString(e));
							// 		// s.deps.set(src, true);
							// 		srcCount++;
							// 	}
							// } else {
							// 	trace(" - - BD: lvl>0: parent="+parent.name+" srcel="+srcel);
							// }
						default:
					}
				}

// THis section below was trying to add the un-referenced __init__ type fragments to the final shader deps but it failed
// as it added stuff to frag and verts

// This adds ALL glsources when the shader is encountered BUT they are in the wrong order as they should potentially
// wrap around hxsl. Also they are duplicated by the normal process.

// Potentially - this could build a list of sources to add, if an add is required, add these in and perhaps do it
// at the end if there are left-overs.

// IDEAS:
//  - pre-process all GLSources to map them to an array like glsources
//  - All init versions need outputing with the __init__ code blocks (in order though)
//  - All init_vert versions need outputing with the __init__vertex code blocks  (in order though)
//  - All init_frag versions need outputing with the __init__fragment code blocks  (in order though)
//  - For all other - regular shader entries
//  	- if encountering a TGLSLSOurce - output any previous ones ?? Will there be if the above are done???
// 	- remove that from being added again.
// - For those not added: 
//   - Add them as a dependency before moving onto the next shader. (e.g. in the !write block)


// COMMENTS:
//  - Need to really determine WHEN the init/init_vert/init_frag blocks are processed to allow the injection
//  - of the glsources at the correct times.

// Test with RGBDDecode to begin with - NOTHING ELSE!!!!!
// Only when that is correct, move onto the PBR shader.


				for (k in glsources.keys()) {
					var shaderName = StringTools.replace(parent.name, ".vertex", "");
					shaderName = StringTools.replace(shaderName, ".fragment", "");
					// trace("SOURCES-TO-ADD for "+shaderName+" full="+parent.name+" k="+k);
					if (k!=parent.name && k.indexOf(shaderName)>-1) {
						var srcsAdded = [];
						for (i in 0...glsources[k].length) {
							if ((k.indexOf("vertex")>-1 && parent.name.indexOf("vertex")>-1) || (k.indexOf("fragment")>-1 && parent.name.indexOf("fragment")>-1) || (k.indexOf("__init__")>-1 && k.indexOf("__init__fragment")==-1 && k.indexOf("__init__vertex")==-1))
							{
								// sourcesToAdd.push(glsources[k][i]);
								var srcStr = glsources[k][i].src;
								var shader = glsources[k][i].shader;
								// var expr = { e : TGLSLSource(srcStr), t : TVoid, p : null };
								// var src = addSource( k+"_src"+srcCount, parent.vertex, expr, prio, false );
								// src.deps = new Map();
								s.deps.set(shader, true);
								trace("BD:PreAddingSource: src="+shader.name+" (pri="+shader.priority+") s.vert="+shader.vertex+" src="+new Printer().exprString(shader.body));
								srcCount++;
								srcsAdded.push(glsources[k][i]);
							}
						}
						for (s in srcsAdded) {
							trace(" - BD: removing from glsources k="+k+" s="+s.src);
							glsources[k].remove(s);
						}
		
					}
				}
				addKeptVars(parent.body);
				// if (added)
				// 	continue;
			}

			if( !parent.write.exists(v.id)) {
				// if (glsources.exists(parent.name)) {
				// 	// if (STOP) {
				// 	// 	trace("STOP POINT!!!");
				// 	// }
			
				// 	var srcArr = sourcesToAdd;
				// 	var srcCount = 0;
				// 	for (srcStr in srcArr) {
				// 		var expr = { e : TGLSLSource(srcStr.src), t : TVoid, p : null };
				// 		var src = addSource( s.name+"_src"+srcCount, parent.vertex, expr, srcStr.priority, false );
				// 		src.deps = new Map();
				// 		s.deps.set(src, true);
				// 		trace("BD-POSTWRITE:AddingSource: src="+src.name+" (pri="+src.priority+") s.vert="+parent.vertex+" src="+new Printer().exprString(src.body));
				// 		srcCount++;
				// 		// glsources[parent.name] = glsources[parent.name].splice(i, 1);
				// 	}
				// }
					// if (parent.body.e != null) {
				// 	var added = false;
				// 	var srcCount = 0;
				// 	function addSources(e, lvl=0) {
				// 		var str:String = cast e.e;
				// 		switch( e.e ) {
				// 			case TBlock(el):
				// 				for( e1 in el ) addSources(e1, lvl+1);
				// 			case TGLSLSource(srcel):
				// 				var src = null;
				// 				trace("TGLSLSource: src-el="+srcel+" par="+parent.name+" lvl="+lvl);
				// 				// if (parent.name.indexOf("Irradiance.vertex")>-1 || srcel.indexOf("// Irradiance vertex")>-1) {
				// 				// 	trace(" - Have Irradiance vertex src: parent="+parent.name);
				// 				// }
				// 				if (true) {
				// 					if (!glsources.exist(parent.name+"_src"+srcCount)) {
				// 						trace("S.VERTEX="+s.vertex+" P.VERTEX="+parent.vertex+" match="+(s.vertex==parent.vertex)+" par="+parent.name+" lvl="+lvl+" srcel="+srcel);
				// 						if (lvl==0 && s.vertex==parent.vertex) {
				// 							src = addSource( parent.name+"_src"+srcCount, parent.vertex, { e : e.e, t : e.t, p : e.p }, parent.priority, false );
				// 							// s.hasSource = false;
				// 							src.deps = new Map();
				// 							glsources.set(parent.name+"_src"+srcCount, src);
				// 							trace(" - - BD: addSource lvl="+lvl+" cnt="+srcCount+": bdsrc="+src.name+" (pri="+src.priority+")  parent="+parent.name+" src="+new Printer().exprString(e));
				// 							s.deps.set(src, true);
				// 							srcCount++;
				// 							parent.hasSource = false;
				// 						}
				// 					} else {
				// 						trace(" - - BD: src not null & lvl==0: parent="+parent.name+" srcel="+srcel);
				// 					}
				// 					added = true;
				// 				} else {
				// 					trace(" - - BD: lvl>0: parent="+parent.name+" srcel="+srcel);
				// 				}
				// 			default:
				// 		}
				// 	}
				// 	trace("AddSources: name="+parent.name+" added="+added);
				// 	addSources(parent.body);
				// }
	
				continue;
			}
			if( s.vertex ) {
				if( parent.vertex == false )
					continue;
				if( parent.vertex == null )
					parent.vertex = true;
			}
			trace(" - - BD: Adding parent as dep and initDeps: s:"+s.name + " => p:" + parent.name + " (v:" + v.path + ")");
			s.deps.set(parent, true);
			debugDepth++;
			initDependencies(parent);
			debugDepth--;
			if( !parent.read.exists(v.id) )
				return;
		}
		if( v.v.kind == Var && !(v.v.hasQualifier(Keep) || v.v.hasQualifier(KeepV)) )
			error("Variable " + v.path + " required by " + s.name + " is missing initializer", null);
	}


// In BuildDependencies it needs to somehow identify 'visibility' or 'uvisibility' 
// to be able to the add the line as a dependent shader line.

// initDependencies needs to somehow either have the Keep & KeepV vars in the loop 
// or at least be able to add the kept vars as deps in the correct location in buildDependencies


	function initDependencies( s : ShaderInfos ) {
		if( s.deps != null )
			return;
		s.deps = new Map();
		trace("InitDependencies for: "+s.name+" pri="+s.priority);
		for( r in s.read ) {
			trace(" - buildDeps readVar=: "+r.path+" s.write.exsits? "+s.write.exists(r.id));
			buildDependency(s, r, s.write.exists(r.id));
		}
		// propagate fragment flag
		if( s.vertex == null )
			for( d in s.deps.keys() )
				if( d.vertex == false ) {
					debug(s.name + " marked as fragment because of " + d.name);
					s.vertex = false;
					break;
				}
		// propagate vertex flag
		if( s.vertex )
			for( d in s.deps.keys() )
				if( d.vertex == null ) {
					debug(d.name + " marked as vertex because of " + s.name);
					d.vertex = true;
				}
	}

	function collect( cur : ShaderInfos, out : Array<ShaderInfos>, vertex : Bool, lvl:Int = 0 ) {
		if( cur.onStack )
			error("Loop in shader dependencies ("+cur.name+")", null);
		if( cur.marked == vertex )
			return;
		cur.marked = vertex;
		cur.onStack = true;
		var ind = [for (l in 0...lvl) " - "].join("");
		trace("Collect: "+ind+" cur="+cur.name+" pri="+cur.priority);
		var deps = [for( d in cur.deps.keys() ) d];
		deps.sort(sortByPriorityDesc);
		for( d in deps )
			collect(d, out, vertex, lvl+1);
		if( cur.vertex == null ) {
			debug("MARK " + cur.name+" " + (vertex?"vertex":"fragment"));
			cur.vertex = vertex;
		}
		if( cur.vertex == vertex ) {
			debug("COLLECT " + cur.name + " " + (vertex?"vertex":"fragment"));
			out.push(cur);
		}
		cur.onStack = false;
	}

	function uniqueLocals( expr : TExpr, locals : Map < String, Bool > ) : Void {
		switch( expr.e ) {
		case TVarDecl(v, _):
			if( locals.exists(v.name) ) {
				var k = 2;
				while( locals.exists(v.name + k) )
					k++;
				v.name += k;
			}
			locals.set(v.name, true);
		case TBlock(el):
			var locals = [for( k in locals.keys() ) k => true];
			for( e in el )
				uniqueLocals(e, locals);
		default:
			expr.iter(uniqueLocals.bind(_, locals));
		}
	}

	function dumpDeps(s:ShaderInfos, lvl:Int = 0) {
		if (s.body!=null) {
			function showExpr(e, eln=0) {
				switch( e.e ) {
					case TBlock(el):
						for( e1 in el ) showExpr(e1, eln++);
					default:
						trace(lvl+":  #"+eln+": "+new Printer().exprString(e)+"     : ("+ s.name+" pri="+s.priority+")");
					}
			}
			showExpr(s.body);
		}
		for( d in s.deps.keys() ) {
			dumpDeps(d, lvl++);
		}
	}


	function dumpFuns(e, ln = 0) {
		switch( e.e ) {
			case TBlock(el):
				for( e1 in el ) dumpFuns(e1, ln++);
			default:
				trace("Ln#"+ln+": "+new Printer().exprString(e));
			}
	}

	static var STOP = false;

	public function link( shadersData : Array<ShaderData> ) : ShaderData {
		debug("---------------------- LINKING -----------------------");
		varMap = new Map();
		varIdMap = new Map();
		allVars = new Array();
		shaders = [];
		locals = new Map();
		glsources = new Map();
		glvfuncs = new Map();
		glffuncs = new Map();

		var dupShaders = new Map();
		shadersData = [for( s in shadersData ) {
			var s = s, sreal = s;
			if( dupShaders.exists(s) )
				s = Clone.shaderData(s);
			dupShaders.set(s, sreal);
			s;
		}];

		// globalize vars
		curInstance = 0;
		var outVars = [];
		for( s in shadersData ) {
			isBatchShader = batchMode && StringTools.startsWith(s.name,"batchShader_");
			for( v in s.vars ) {
				var v2 = allocVar(v, null, s.name);
				if( isBatchShader && v2.v.kind == Param && !StringTools.startsWith(v2.path,"Batch_") )
					v2.v.kind = Local;
				if( v.kind == Output ) outVars.push(v);
			}
			for( f in s.funs ) {
				var v = allocVar(f.ref, f.expr.p);
				if (v==null || f==null) {
					trace("V-allocVar==null");
				}
				v.kind = f.kind;
			}
			curInstance++;
			if (curInstance==15) {
				trace("link: inst=15");
			}

		}

		// create shader segments
		var priority = 0;
		var initPrio = {
			init : [-1000],
			vert : [-2000],
			frag : [-3000],
		};
		trace("LINK: About to iterate over shaderDatas and addShaders");
		for( s in shadersData ) {
			for( f in s.funs ) {
				var v = allocVar(f.ref, f.expr.p);
				if( v.kind == null ) throw "assert";
				switch( v.kind ) {
				case Vertex, Fragment:
					addShader(s.name + "." + (v.kind == Vertex ? "vertex" : "fragment"), v.kind == Vertex, f.expr, priority);

				case Init:
					var prio : Array<Int>;
					var status : Null<Bool> = switch( f.ref.name ) {
					case "__init__vertex": prio = initPrio.vert; true;
					case "__init__fragment": prio = initPrio.frag; false;
					default: prio = initPrio.init; null;
					}
					switch( f.expr.e ) {
					case TBlock(el):
						var index = 0;
						for( e in el )
							addShader(s.name+"."+f.ref.name+(index++),status,e, prio[0]++);
					default:
						addShader(s.name+"."+f.ref.name,status,f.expr, prio[0]++);
					}
				case Helper:
					throw "Unexpected helper function in linker "+v.v.name;
				}
			}
			for (vf in s.glvfuncs) {
				if (!glvfuncs.exists(vf.name)) {
					glvfuncs.set( vf.name, vf );
				}
			}
			for (ff in s.glffuncs) {
				if (!glffuncs.exists(ff.name)) {
					glffuncs.set( ff.name, ff );
				}
			}
			priority++;
		}
		shaders.sort(sortByPriorityDesc);
		trace("LINK: ShadersSorted:");

		
		if (shaders.length > 50) {
			STOP = true;
			trace("GOT BIG SHADER");
		}

		// build dependency tree
		var entry = new ShaderInfos("<entry>", false);
		entry.deps = new Map();
		for( v in outVars ) { 
			trace("BuildDependencyOutVar: v="+v.name);
			buildDependency(entry, allocVar(v,null), false);
		}

		trace("LINK: DependeciesBuilt:");
		dumpDeps(entry);
		trace("LINK: About to include discards");
		// if (STOP) {
		// 	trace("STOP POINT!!!");
		// }
		
		// force shaders containing discard to be included
		for( s in shaders ) {
			if( s.hasDiscard || s.hasKeptVars) {
				initDependencies(s);
				entry.deps.set(s, true);
			}
			// if (glsources.exists(s.name)) {
			// 	var srcArr = glsources[s.name];
			// 	var srcCount = 0;
			// 	for (srcStr in srcArr) {
			// 		var expr = { e : TGLSLSource(srcStr), t : TVoid, p : null };
			// 		var src = addSource( s.name+"_src"+srcCount, s.vertex, expr, s.priority, false );
			// 		src.deps = new Map();
			// 		entry.deps.set(src, true);
			// 		trace("POST:AddingSource: src="+src.name+" (pri="+src.priority+") s.vert="+s.vertex+" src="+new Printer().exprString(src.body));
			// 		srcCount++;
			// 	}
			// }
			// if (s.hasSource) {
			// 	if (s.body.e != null) {
			// 		var added = false;
			// 		var srcCount = 0;
			// 		function addSources(e, lvl=0) {
			// 			var str:String = cast e.e;
			// 			switch( e.e ) {
			// 				case TBlock(el):
			// 					for( e1 in el ) addSources(e1, lvl+1);
			// 				case TGLSLSource(srcel):
			// 					var src = null;
			// 					trace("POSTSource: src-el="+srcel+" par="+s.name+" lvl="+lvl);
			// 					if (true) {
			// 						if (glsources.exists(s.name)) {
			// 							// // trace("S.VERTEX="+s.vertex+" P.VERTEX="+s.vertex+" match="+(s.vertex==s.vertex)+" par="+s.name+" lvl="+lvl+" srcel="+srcel);
			// 							// // if (s.vertex==s.vertex) {
			// 							// 	src = addSource( s.name+"_src", s.vertex, { e : e.e, t : e.t, p : e.p }, s.priority, false );
			// 							// 	// s.hasSource = false;
			// 							// 	src.deps = new Map();
			// 							// 	// glsources.push(src);
			// 							// 	trace("POST:AddingSource lvl="+lvl+" cnt="+srcCount+": bdsrc="+src.name+" (pri="+src.priority+")  s="+s.name+" s.vert="+s.vertex+" src="+new Printer().exprString(e));
			// 							// 	entry.deps.set(src, true);
			// 							// 	srcCount++;
			// 							// // }
			// 							var srcArr = 

			// 						} else {
			// 							trace(" - - POST: src not null & lvl==0: s="+s.name+" srcel="+srcel);
			// 						}
			// 						added = true;
			// 					} else {
			// 						trace(" - - POST: lvl>0: s="+s.name+" srcel="+srcel);
			// 					}
			// 				default:
			// 			}
			// 		}
			// 		addSources(s.body);
			// 	}
			// }
		}

		// shaders.concat(glsources);
		
		trace("LINK: Dumping ENTRY shaders:");
		dumpDeps(entry);
		// if (STOP) {
		// 	trace("STOP POINT!!!");
		// }
		
		trace("LINK: About to force params into frag shaders:");
		// force shaders reading only params into fragment shader
		// (pixelColor = color with no effect in BaseMesh)
		for( s in shaders ) {
			if( s.vertex != null ) continue;
			var onlyParams = true;
			for( r in s.read )
				if( r.v.kind != Param ) {
					onlyParams = false;
					break;
				}
			if( onlyParams ) {
				debug("Force " + s.name+" into fragment since it only reads params");
				s.vertex = false;
			}
		}

		// collect needed dependencies
		var v = [], f = [];
		trace("LINK: About to call COLLECT for Vert");
		collect(entry, v, true);
		trace("LINK: About to call COLLECT for Frag");
		collect(entry, f, false);
		if( f.pop() != entry ) throw "assert";

		trace("LINK: Check dependencies are matched");
		// check that all dependencies are matched
		for( s in shaders )
			s.marked = null;
		for( s in v.concat(f) ) {
			for( d in s.deps.keys() )
				if( d.marked == null && !d.hasSource && !d.hasKeptVars )
					error(d.name + " needed by " + s.name + " is unreachable", null);
			s.marked = true;
		}

		trace("LINK: Vertex Shaders validated");
		for (s in v) trace(" - "+s.name+" pri="+s.priority);
		trace("LINK: Fragment Shaders validated");
		for (s in f) trace(" - "+s.name+" pri="+s.priority);

		trace("SORTING Priority ascending");
		v.sort(sortByPriorityAsc);
		f.sort(sortByPriorityAsc);

		trace("LINK: Vertex Shaders validated");
		for (s in v) trace(" - "+s.name+" pri="+s.priority);
		trace("LINK: Fragment Shaders validated");
		for (s in f) trace(" - "+s.name+" pri="+s.priority);

		// build resulting vars
		var outVars = [];
		var varMap = new Map();
		function addVar(v:AllocatedVar) {
			if( varMap.exists(v.id) )
				return;
			varMap.set(v.id, true);
			if( v.v.parent != null )
				addVar(v.parent);
			else
				outVars.push(v.v);
			// trace(" - AddVar="+v.v.name+" v="+v);
		}
		trace("LINK: For shaders in V and F arrays, addVars that are read or written");
		for( s in v.concat(f) ) {
			for( v in s.read )
				addVar(v);
			for( v in s.write )
				addVar(v);
		}

		// cleanup unused structure vars
		function cleanVar( v : TVar ) {
			switch( v.type ) {
			case TStruct(vl) if( v.kind != Input ):
				var vout = [];
				for( v in vl )
					if( varMap.exists(v.id) ) {
						cleanVar(v);
						vout.push(v);
					}
				v.type = TStruct(vout);
			default:
			}
		}
		trace("LINK: CleanVars - I think that is collapsing structs");
		for( v in outVars )
			cleanVar(v);

		trace("LINK: Add Keep && KeepV vars");
		for( v in allVars) {
			if (v.v.qualifiers!=null && (v.v.qualifiers.indexOf(Keep)>-1 || v.v.qualifiers.indexOf(KeepV)>-1)) 
				addVar(v);
		}

		// build resulting shader functions
		function build(kind, name, a:Array<ShaderInfos> ) : TFunction {
			var ks:String = cast kind;
			trace("LINK: Build "+ks+" TFunction");
			var v : TVar = {
				id : Tools.allocVarId(),
				name : name,
				type : TFun([ { ret : TVoid, args : [] } ]),
				kind : Function,
			};
			outVars.push(v);
			var exprs = [];
			for( s in a )
				switch( s.body.e ) {
				case TBlock(el):
					for( e in el ) exprs.push(e);
				default:
					exprs.push(s.body);
				}
			var expr = { e : TBlock(exprs), t : TVoid, p : exprs.length == 0 ? null : exprs[0].p };
			uniqueLocals(expr, new Map());
			return {
				kind : kind,
				ref : v,
				ret : TVoid,
				args : [],
				expr : expr,
			};
		}

		var funs = [
			build(Vertex, "vertex", v),
			build(Fragment, "fragment", f),
		];

		trace("LINK: FUNS-VERT ------------");
		dumpFuns(funs[0].expr);
		trace("LINK: FUNS-FRAG ------------");
		dumpFuns(funs[1].expr);

		// make sure the first merged var is the original for duplicate shaders
		for( s in dupShaders.keys() ) {
			var sreal = dupShaders.get(s);
			if( s == sreal ) continue;
			for( i in 0...s.vars.length )
				allocVar(s.vars[i],null).merged.unshift(sreal.vars[i]);
		}
		trace("LINK: Shader list from 'shaders'");
		var ctr = 0;
		for (s in shaders) {
			trace(" - "+ctr+":"+s.name+" p="+s.priority);
		}

		return { name : "out", vars : outVars, funs : funs, glvfuncs : Lambda.array(glvfuncs), glffuncs :  Lambda.array(glffuncs) };
	}

}