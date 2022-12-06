package h3d.scene;

typedef Constraint = {
    var type:JointType;
	@:optional var twist:Limit;
	@:optional var axis:h3d.Vector;
	@:optional var limits:Limit;
	@:optional var polar:Limit;
	@:optional var azimuth:Limit;
}

typedef Limit = {
	var min:Float;
	var max:Float;
}

enum JointType {
	OMNI;
	HINGE;
	BALLSOCKET;
}


@:access(h3d.scene.Skin)
class SkeletonIK {

    public var root:h3d.anim.Skin.Joint;
    public var joint:h3d.anim.Skin.Joint;
    public var skin:h3d.scene.Skin;
    public var targetTransform(default, set):h3d.Matrix;
    public var currentPosition:h3d.Vector;
    public var interpolation:Float = 1;
    public var overrideTipBasis:Bool = true;
    public var useMagnet:Bool = false;
    public var magnetPosition:h3d.Vector;
    public var constraint:JointConstraint;

    var task:Task;
    var complete:Bool;

    function set_targetTransform(t:h3d.Matrix) {
        targetTransform = t;
        if (t == null) return t;

        currentPosition.x = targetTransform._41;
        currentPosition.y = targetTransform._42;
        currentPosition.z = targetTransform._43;
        IKBoxHeaps.IKBH.g6.clear();

        reloadChain();
        return t;
    }

    public function new( r:h3d.anim.Skin.Joint, j:h3d.anim.Skin.Joint, s:h3d.scene.Skin ) {
        root = r;
        joint = j;
        skin = s;
        currentPosition = new h3d.Vector();
    }

    public function reloadChain() {
        task = null;
    
        if (skin==null || targetTransform==null) return;

        complete = false;

        task = FabrikInverseKinematic.createSimpleTask(skin, findBone(root), findBone(joint), targetTransform);
    }

    public function sync(force = false) {
        if (task==null || targetTransform==null || (complete && !force)) return;

        IKBoxHeaps.IKBH.g1.clear();
        IKBoxHeaps.IKBH.g2.clear();
        IKBoxHeaps.IKBH.g3.clear();
        IKBoxHeaps.IKBH.g4.clear();
        IKBoxHeaps.IKBH.g5.clear();
   
        FabrikInverseKinematic.solve(task, interpolation, overrideTipBasis, useMagnet, magnetPosition);

        skin.jointsUpdated = true;
        complete = true;
    }

    public function findBone(j:h3d.anim.Skin.Joint):Int {
        return skin.skinData.allJoints.indexOf(j);
    }

    public static function hasBone(j:h3d.anim.Skin.Joint, s:h3d.scene.Skin) {
        return s.currentAbsPose[j.index]!=null;
    }

    public function debugJoints() {
        for (j in skin.skinData.allJoints) {
            // Dbg.printJointLimits( j, skin.getJointAbsTransform( skin.skinData.allJoints[j.index] ) );
        }
    } 

    inline function r(v:Float) return Std.int((v * 10000) + 0.5) / 10000;
	function mtos(m:h3d.Matrix, preF:String = "") return m==null ? "--NULL--" : (preF==null ? "" : preF+": ")+r(m._11)+","+r(m._12)+","+r(m._13)+","+r(m._14)+","+r(m._21)+","+r(m._22)+","+r(m._23)+","+r(m._24)+","+r(m._31)+","+r(m._32)+","+r(m._33)+","+r(m._34)+","+r(m._41)+","+r(m._42)+","+r(m._43)+","+r(m._44);
}

@:access(h3d.scene.Skin)
class FabrikInverseKinematic {

    static function getBoneParent(b:Int, s:h3d.scene.Skin):Int {
        var par = s.skinData.allJoints[b].parent;
        return par==null ? -1 : par.index;
    }

    static function getBoneGlobalPose(b:Int, s:h3d.scene.Skin):h3d.Matrix {
        var m = s.getJointAbsTransform( s.skinData.allJoints[b] );
        Dbg.dJ(IKBoxHeaps.IKBH.j1, b, m.tx, m.ty, m.tz);
        trace("getBoneGlobalPose: bone="+b+" name="+s.skinData.allJoints[b].name+" globalPose="+mtos(m));
        
        return m;
    }

    static function buildChain( task:Task, forceSimpleChain:Bool = true ):Bool {
        if (task.rootBone==-1) return false;

        trace("IK: BuildChain");
        var chain = task.chain;
        
        chain.tips = [];
        chain.chainRoot.bone = task.rootBone;
        chain.chainRoot.initialTransform = getBoneGlobalPose(chain.chainRoot.bone, task.skeleton); 
        chain.chainRoot.currentPos = chain.chainRoot.initialTransform.origin;
        chain.middleChainItem = null;
        // setBoneConstraint(chain.chainRoot, task.skeleton);
     
        // Holds all IDs that are composing a single chain in reverse order
        var chainIds:Array<Int> = [];
        var sub_chain_size:Int;
    
        var x = task.endEffectors.length-1;
        while (x >= 0) {
            var ee = task.endEffectors[x];
            if (task.rootBone >= ee.tipBone) return false;
            if (ee.tipBone<0 || ee.tipBone>=task.skeleton.skinData.allJoints.length) return false;
    
            var subChainSize = 0;
            var chainSubTip:Int = ee.tipBone;
            while (chainSubTip > task.rootBone) {
                chainIds.push(chainSubTip);
                subChainSize++;
                var ocst = chainSubTip;
                chainSubTip = getBoneParent(chainSubTip, task.skeleton);
            }
    
            var middleChainItemId:Int = Std.int(subChainSize * 0.5);
            var subChain = chain.chainRoot;
            var i = subChainSize-1;
            while (i>=0) { 
                var childCi = subChain.findChild(chainIds[i]);
                if (childCi==null) {
                    childCi = subChain.addChild(chainIds[i]);
 
                    childCi.initialTransform = getBoneGlobalPose(childCi.bone, task.skeleton); // task.skeleton.currentAbsPose[ childCi.bone ]; //
                    childCi.currentPos = childCi.initialTransform.origin;
        
                    if (childCi.parentItem!=null) {
                        childCi.length = childCi.parentItem.currentPos.distance(childCi.currentPos);
                        var dir = childCi.parentItem.currentPos.directionTo(childCi.currentPos);
                        setBoneConstraint(childCi.parentItem, task.skeleton, dir);
                    }
                }
    
                subChain = childCi;
    
                if (middleChainItemId == i ) {
                    chain.middleChainItem = childCi;
                }
                i--;
            }
    
            if (middleChainItemId==null) {
                chain.middleChainItem = null;
            }
    
            chain.tips[x] = new ChainTip(subChain, ee);
    
            if (forceSimpleChain) {
                // NOTE:
                //	This is a "hack" that force to create only one tip per chain since the solver of multi tip (end effector)
                //	is not yet created.
                //	Remove this code when this is done
                break;
            }
            x--;
        }


        Dbg.drawChain(IKBoxHeaps.IKBH.g1, 0x800080, chain, 2, new h3d.Vector(), 0.3, 0.5);
        return true;
    }

    static function setBoneConstraint(ci:ChainItem, s:h3d.scene.Skin, boneDir:h3d.Vector){
        if (s.skinData.allJoints[ci.bone].constraint!=null) {
            // var g = h3d.Matrix.I();
            // // g.basis.multiply(ci.initialTransform.basis, s.skinData.allJoints[ci.bone].defMat.getInverse().basis);
            // g.load(s.skinData.allJoints[ci.bone].defMat);
            // var sc = g.getScale();
            ci.bindQuat = new h3d.Quat();
            ci.bindQuat.initDirection( boneDir );
            // var boneDir = ci.initialTransform.origin.clone();//new h3d.Vector(0, 0, 1); // ci.bindQuat.getDirection();
            // if ()
            var c = s.skinData.allJoints[ci.bone].constraint;
            // ci.bindQuat = new h3d.Quat();
            // ci.bindQuat.initRotateMatrix( ci.initialTransform );//s.skinData.allJoints[ci.bone].defMat );//s.skinData.allJoints[ci.bone].defMat );
            // var boneDir = ci.bindQuat.getDirection();
            // Dbg.dQ(IKBoxHeaps.IKBH.g6, 0x800080, 5, ci.initialTransform.origin, ci.bindQuat);
            // Dbg.dV(IKBoxHeaps.IKBH.g6, 0x00FF26, 2, ci.initialTransform.origin, boneDir.multiply(0.5));
            trace("SetBoneConstraint: name:"+ci.bone+" boneDir="+boneDir+" bindQuat="+ci.bindQuat+" initTrns:"+mtos(ci.initialTransform));
            if (c.type==JointType.HINGE) ci.constraint = new JCHinge( boneDir );
            if (c.type==JointType.BALLSOCKET) ci.constraint = new JCBallSocket( boneDir );
            if (ci.constraint!=null) ci.constraint.setConstraint( c );
        }
    }


    static function solveSimple( task:Task, solveMagnet:Bool, originPos:h3d.Vector ) {
        trace("SolveSimple: originPos: "+originPos);
        var distanceToGoal:Float = 1e4;
        var previousDistanceToGoal:Float = 0;
        var canSolve = task.maxIterations;
        while (distanceToGoal > task.minDistance && Math.abs(previousDistanceToGoal - distanceToGoal) > 0.000005 && canSolve>0) {
            previousDistanceToGoal = distanceToGoal;
            --canSolve;
    
            solveSimpleBackwards(task, task.chain, solveMagnet);
            // Dbg.drawChain(IKBoxHeaps.IKBH.g2, 0x808000, task.chain);
            solveSimpleForwards(task, task.chain, solveMagnet, originPos);
            // Dbg.drawChain(IKBoxHeaps.IKBH.g3, 0x106030, task.chain, 0, new h3d.Vector(), 0.4, 0.5);
            
            distanceToGoal = task.chain.tips[0].endEffector.goalTransform.origin.distance(task.chain.tips[0].chainItem.currentPos);
            trace("SolveSimple: distToGoal="+distanceToGoal);
        }
        Dbg.drawChain(IKBoxHeaps.IKBH.g3, 0xff0000, task.chain, 0, new h3d.Vector(), 0.4, 1.5);
    }

    static function solveSimpleBackwards( task:Task, chain:Chain, solveMagnet:Bool ) {
        if (solveMagnet && chain.middleChainItem==null) {
            return;
        }
    
        if (!IKBox.debug) trace("solveSimpleBackwards:");

        var goal:h3d.Vector;
        var subChainTip:ChainItem;
        if (solveMagnet) {
            goal = chain.magnetPosition;
            subChainTip = chain.middleChainItem;
        } else {
            goal = chain.tips[0].endEffector.goalTransform.origin;
            if (!IKBox.debug) trace("Goal: "+goal);
            subChainTip = chain.tips[0].chainItem;
        }

        while (subChainTip!=null) {
            subChainTip.currentPos = goal;
            // printJointLimits( task.skeleton.skinData.allJoints[subChainTip.bone], subChainTip.initialTransform.clone() );
    
            if (subChainTip.parentItem!=null) {
                // Not yet in the chain root
                var look_parent = subChainTip.parentItem.currentPos.sub( subChainTip.currentPos );
                look_parent.normalize();
                var localGoalVector = look_parent.multiply( subChainTip.length );
                goal = subChainTip.currentPos.add( localGoalVector );
                Dbg.dJ(IKBoxHeaps.IKBH.j2, subChainTip.bone, goal.x, goal.y, goal.z);
 
                // [TODO] Constraints goes here

                // if (subChainTip.constraint!=null) 
                //     applyConssdftraint(subChainTip, task.skeleton);

                // var diff = goal.sub(subChainTip.currentPos);
                // var base = subChainTip.parentItem.currentPos.clone();
                // var defMat = task.skeleton.skinData.allJoints[subChainTip.parentItem.bone].defMat;
                // var fromVector = subChainTip.initialTransform.origin.sub( subChainTip.parentItem.initialTransform.origin );
                // var toVector = subChainTip.currentPos.sub( subChainTip.parentItem.currentPos );//.tx, subChainTip.initialTransform.ty, subChainTip.initialTransform.tz );
                // // BAD var axis = fromVector.cross( toVector ).normalized();
                // // BAD var angle = Math.acos( toVector.dot( fromVector ) );
    
                // var joint = task.skeleton.skinData.allJoints[subChainTip.parentItem.bone];

                // var newBonePose = subChainTip.initialTransform.clone();
                // var currentOri = subChainTip.currentPos.sub(subChainTip.parentItem.currentPos);
                // var initialOri = subChainTip.initialTransform.origin.sub(subChainTip.parentItem.initialTransform.origin);
                // initialOri.normalize();
                // var rotAxis = initialOri.cross(currentOri);
                // rotAxis.normalize();
   
                // var rotAngle:Float = 0;
                // if (rotAxis.x != 0 && rotAxis.y != 0 && rotAxis.z != 0) {
                //     rotAngle = Math.acos(hxd.Math.clamp(initialOri.dot(currentOri), -1, 1));
                //     newBonePose.basis.rotateAxis(rotAxis, rotAngle);
                // }

                // var m = h3d.Matrix.I();
                // m.basis.rotateAxis(rotAxis, rotAngle);
                // var eu = m.getEulerAngles();
                // eu.scale(180/Math.PI);
                // var eu2 = newBonePose.getEulerAngles();
                // eu2.scale(180/Math.PI);

                // trace("Backwards: j="+joint.name+" len2child:"+subChainTip.length);
                // trace("Vec: "+diff);
                // trace("AxisAng: axis="+rotAxis+" angle="+rotAngle);
                // trace("M-Eulers: "+eu);
                // trace("NewBonePose-Eulers: "+eu2);
                // trace("Min: "+joint.minAngle);
                // trace("Max: "+joint.maxAngle);
               
            }
        
            subChainTip = subChainTip.parentItem;
        }
    }

    static function solveSimpleForwards( task:Task, chain:Chain, solveMagnet:Bool, originPos:h3d.Vector ) {
        if (solveMagnet && chain.middleChainItem==null) {
            return;
        }
    
        // trace("solveSimpleForwards:");
        var subChainRoot = chain.chainRoot;
        var origin = originPos;
    
        while (subChainRoot!=null) { // Reach the tip
            subChainRoot.currentPos = origin;
            
            if (subChainRoot.children.length>0) {
                var child = subChainRoot.children[0];
    
                subChainRoot.currentOri = child.currentPos.sub(subChainRoot.currentPos);
                subChainRoot.currentOri.normalize();
                origin = subChainRoot.currentPos.add(subChainRoot.currentOri.multiply(child.length));
    
                // [TODO] Constraints goes here

                if (solveMagnet && subChainRoot == chain.middleChainItem) {
                    // In case of magnet solving this is the tip
                    subChainRoot = null;
                } else {
                    subChainRoot = child;
                }
            } else {
                // Is tip
                subChainRoot = null;
            }
        }
    }

    static function applyConstraint(ci:ChainItem, task:Task) {
        var invBindRot = ci.bindQuat.clone();
        invBindRot.conjugate();

        trace("ApplyContraint: globalPose:"+mtos(ci.globalPose));
        
        // ***** Section showed rotation around Z(Up) for elbow joint -90 (arm out) to 75 (hand to chest)
        // var poseRot = new h3d.Quat();
        // var currentOri = new h3d.Vector(1,0,0);
        // var initialOri = new h3d.Vector(1,0,0);

        // initialOri.transform3x3(ci.initialTransform);
        // currentOri.transform3x3(ci.globalPose);
        // var diff = initialOri.directionTo(currentOri);
        // trace("InitialTransform: angles:"+Dbg.angs(ci.initialTransform));
        // trace(" - origin: "+ci.initialTransform.origin);
        // trace(" - initialOri: "+initialOri);
        // trace("GlobalPose: angles:"+Dbg.angs(ci.globalPose));
        // trace(" - origin: "+ci.globalPose.origin);
        // trace(" - currentOri: "+currentOri);
        // trace("Diff: "+diff);

        // Get Matrix difference between initialTransform and globalPose
        var poseRotation = h3d.Matrix.I();
        poseRotation.basis.multiply(ci.globalPose.basis, ci.initialTransform.getInverse().basis); // Difference betwen globalPose and initialTransform - rotational difference
        trace("PoseRotation: angles:"+Dbg.angs(poseRotation));
        var poseRot = new h3d.Quat();
        poseRot.initRotateMatrix( poseRotation );
        Dbg.dQ(IKBoxHeaps.IKBH.g2, 0x808000, 3, ci.initialTransform.origin, poseRot); // Rotation difference represented as a Quat

        trace("PoseRot: "+Dbg.quat(poseRot));
        
        trace(" - about to apply constraint:"+poseRot);
        var newOut = new h3d.Quat();//poseRot.clone();
        ci.constraint.applyJointConstraint( poseRot, newOut, ci );
        trace(" - constrained pose: poseRot:"+poseRot+" newOut:"+newOut);

        var qGlobalPose = new h3d.Quat();
        qGlobalPose.initRotateMatrix( ci.initialTransform );
        trace(" - initTransform: globalPose:"+mtos(ci.globalPose));
        var q = new h3d.Quat();
        q.multiply(newOut, qGlobalPose);
        q.normalize();

        trace(" - constrained-orig: globalPose:"+mtos(ci.globalPose));
        var m = h3d.Matrix.I();
        q.toMatrix( m );
        // m.invert();
        Dbg.dQ(IKBoxHeaps.IKBH.g6, 0x004080, 4, ci.initialTransform.origin, newOut);
        ci.globalPose.multiply(m, ci.initialTransform);
        // ci.globalPose.load( ci.initialTransform );
        trace(" - constrained-new: globalPose:"+mtos(ci.globalPose)+" m="+mtos(m));
    }

    public static function createSimpleTask( sk:h3d.scene.Skin, rootBone:Int, tipBone:Int, goalTransform:h3d.Matrix ) {
        var ee = new EndEffector();
        ee.tipBone = tipBone;
    
        var task = new Task();
        task.skeleton = sk;
        task.rootBone = rootBone;
        task.endEffectors.push(ee);
        task.goalGlobalTransform = goalTransform;
        trace("Task.GoalTransform: "+mtos(task.goalGlobalTransform));
    
        if (!buildChain(task)) {
            task = null;
            return null;
        }
    
        return task;
    }

    public static function setGoal( task:Task, goal:h3d.Matrix ) {
        task.goalGlobalTransform = goal;
    }

    public static function makeGoal( task:Task, inverseTransf:h3d.Matrix, blendingDelta:Float ) {
        if (blendingDelta >= 0.99) {
            // Update the endEffector (local transform) without blending
            task.endEffectors[0].goalTransform.multiply( inverseTransf, task.goalGlobalTransform );
            trace("IK: GoalTransform: "+mtos(task.endEffectors[0].goalTransform));
        } else {
            // End effector in local transform
            var endEffectorPose = getBoneGlobalPose(task.endEffectors[0].tipBone, task.skeleton); 

            var interpMat = h3d.Matrix.I();
            interpMat.multiply(inverseTransf, task.goalGlobalTransform);
            task.endEffectors[0].goalTransform = h3d.Matrix.interpolate(endEffectorPose, interpMat, blendingDelta);
        }
    }

    public static function solve( task:Task, blendingDelta:Float, overrideTipBasis:Bool, useMagnet:Bool, magnetPosition:h3d.Vector ) {
        if (blendingDelta <= 0.01) {
            
            // Before skipping, make sure we undo the global pose overrides
            var ci = task.chain.chainRoot;
            while (ci!=null) {
                ci.globalPose = null;
                task.skeleton.currentRelPose[ci.bone] = null;
                if (ci.children.length>0) {
                    ci = ci.children[0];
                } else {
                    ci = null;
                }
            }
    
            return; 
        }
    
        // Update the initial root transform so its synced with any animation changes
        updateChain(task.skeleton, task.chain.chainRoot);
    
        task.chain.chainRoot.globalPose = Matrix.I();

        var originPos = getBoneGlobalPose(task.chain.chainRoot.bone, task.skeleton).origin; // task.skeleton.currentAbsPose[ task.chain.chainRoot.bone ].origin; // 
    
        var gT = task.skeleton.getAbsPos().clone();
        gT.initInverse3x3(gT);
    
        makeGoal(task, gT, blendingDelta);
    
        if (useMagnet && task.chain.middleChainItem!=null) {
            task.chain.magnetPosition.lerp( task.chain.middleChainItem.initialTransform.origin, magnetPosition, blendingDelta);
            solveSimple(task, true, originPos);
        }
        solveSimple(task, false, originPos);
    
        // Assign new bone position.
        var ci = task.chain.chainRoot;
        while (ci!=null) {
            var newBonePose = ci.initialTransform.clone();
            newBonePose.origin = ci.currentPos;
    
            if (ci.children.length>0) {
                var initialOri = ci.children[0].initialTransform.origin.sub(ci.initialTransform.origin);
                initialOri.normalize();
                var rotAxis = initialOri.cross(ci.currentOri);
                rotAxis.normalize();
   
                if (rotAxis.x != 0 && rotAxis.y != 0 && rotAxis.z != 0) {
                    var rotAngle = Math.acos(hxd.Math.clamp(initialOri.dot(ci.currentOri), -1, 1));
                    newBonePose.basis.rotateAxis(rotAxis, rotAngle);
                }
                  
            } else {
                // Set target orientation to tip
                if (overrideTipBasis) {
                    newBonePose.basis = task.chain.tips[0].endEffector.goalTransform.basis;
                } else {
                    newBonePose.basis.multiply( newBonePose.basis, task.chain.tips[0].endEffector.goalTransform.basis );
                }
            }
    
            // IK should not affect scale, so undo any scaling
            newBonePose.basis.orthonormalize();
            var pos = getBoneGlobalPose(ci.bone, task.skeleton); // task.skeleton.currentAbsPose[ ci.bone ]; // 
            var sc = pos.getScale();
            newBonePose.basis.scale(sc.x, sc.y, sc.z);
            Dbg.dJ(IKBoxHeaps.IKBH.j3, ci.bone, newBonePose.tx, newBonePose.ty, newBonePose.tz);
            var or = ci.initialTransform.origin;
            Dbg.dJ(IKBoxHeaps.IKBH.j4, ci.bone, or.x, or.y, or.z);

            // var defMat = task.skeleton.skinData.allJoints[ci.bone].defMat;
            // Dbg.dM(IKBoxHeaps.IKBH.g2, pos, pos.origin, 1., 5, new h3d.Vector(0.1,0,0));
            // Dbg.dM(IKBoxHeaps.IKBH.g2, ci.initialTransform, ci.initialTransform.origin, 1., 2.5, new h3d.Vector(0.2,0,0));
            ci.globalPose = newBonePose;

            trace("CI.globalPose: b="+ci.bone+" globalPos:"+mtos(ci.globalPose));

            if (ci.constraint!=null) 
                applyConstraint(ci, task);

            // var tmp = h3d.Matrix.I();
            // tmp.initRotationAxis( new h3d.Vector(0,1,0), Math.PI*0.5);
            // var g = ci.globalPose.clone();
            // // g.basis.multiply(ci.globalPose.basis, ci.initialTransform.getInverse().basis);
            // g.basis.multiply(ci.initialTransform.basis, task.skeleton.skinData.allJoints[ci.bone].defMat.getInverse().basis);
            // // var sc = g.getScale();
            // // tmp.basis.scale(sc.x, sc.y, sc.z);

            // tmp.basis.multiply(g.basis, tmp.basis);
            // tmp.tx = ci.initialTransform.tx;
            // tmp.ty = ci.initialTransform.ty;
            // tmp.tz = ci.initialTransform.tz;
            // // tmp.basis.multiply(tmp.basis, ci.initialTransform.getInverse().basis);
            // Dbg.printJointLimits( ci, tmp );

            // Dbg.dM(IKBoxHeaps.IKBH.g2, newBonePose, newBonePose.origin, 2, 10);

            trace(" - post constraint: b="+ci.bone+" globalPos:"+mtos(ci.globalPose));

            if (ci.children.length>0) {
                ci = ci.children[0];
            } else {
                ci = null;
            }
        }
        // Dbg.drawChain(IKBoxHeaps.IKBH.g4, 0x4080F0, task.chain, 1, new h3d.Vector(0, 0.25, 0), 1, 0.5);
        
        var subChainTip = task.chain.tips[0].chainItem;

        var par = task.chain.chainRoot;
        while (par!=null) {
            if (par.children.length > 0) {
                var child = par.children[0];
                var relPose = h3d.Matrix.I();
                if (par == task.chain.chainRoot) {
                    relPose.multiply3x4inline( par.globalPose, par.initialTransform.getInverse() );
                    relPose.multiply3x4inline( relPose, task.skeleton.skinData.allJoints[par.bone].defMat );
                } else {
                    relPose.multiply3x4inline( par.globalPose, par.parentItem.globalPose.getInverse() );
                }

                task.skeleton.currentRelPose[par.bone] = relPose;
                   
                // trace("RelPos:");
                // trace(" - par="+par.bone+"("+" name="+task.skeleton.skinData.allJoints[par.bone].name+")");
                // trace(" - child="+child.bone+"("+" name="+task.skeleton.skinData.allJoints[child.bone].name+")");
                // trace(" - relPose="+mtos(relPose));
            }
            if (par.children.length>0) {
                par = par.children[0];
            } else {
                par = null;
            }
        }
    }

    public static function updateChain( sk:h3d.scene.Skin, chainItem:ChainItem ) {
        if (chainItem==null) return;
    
        // trace(" - uc bone="+chainItem.bone+" name="+sk.skinData.allJoints[chainItem.bone].name);
        chainItem.initialTransform = getBoneGlobalPose(chainItem.bone, sk); 
        chainItem.currentPos = chainItem.initialTransform.origin;
    
        var items = chainItem.children;
        for (i in 0...items.length) {
            updateChain(sk, items[i]);
        }
    }

    // public static function setJointTransform( mat:h3d.Matrix, j:h3d.anim.Skin.Joint, s:h3d.scene.Skin) {
	// 	var m = j.transPos.clone();
	// 	m.multiply(m, mat);
	// 	m.invert();
	// 	if (j.parent!=null) {
	// 		var parMat:Matrix = s.setJointTransform( j.parent ); 
	// 		parMat.invert();
	// 		m.multiply(m, parMat);
	// 	}
	// 	s.currentRelPose[j.index] = m;
	// }

    public static inline function r(v:Float) return Std.int((v * 10000) + 0.5) / 10000;
	public static function mtos(m:h3d.Matrix, preF:String = "") return m==null ? "--NULL--" : (preF==null ? "" : preF+": ")+r(m._11)+","+r(m._12)+","+r(m._13)+","+r(m._14)+","+r(m._21)+","+r(m._22)+","+r(m._23)+","+r(m._24)+","+r(m._31)+","+r(m._32)+","+r(m._33)+","+r(m._34)+","+r(m._41)+","+r(m._42)+","+r(m._43)+","+r(m._44);

}

/*
ikSolver.createChain(
    [5,4,3,2,1,0],
    [ 
        null, // ignored always

        {type: FABRIKSolver.JOINTTYPES.OMNI, twist:[ 0, 0.0001 ] },   

        {type: FABRIKSolver.JOINTTYPES.HINGE, twist:[ 0, 0.0001 ], axis:[1,0,0], min: 0, max: Math.PI * 0.5 },   
        
        {type: FABRIKSolver.JOINTTYPES.HINGE, twist:[ 0, 0.0001 ], axis:[1,0,0] }, // unconstrained angle of hinge   
        
        {type: FABRIKSolver.JOINTTYPES.BALLSOCKET, twist:[ -Math.PI*0.25, Math.PI*0.25 ], polar:[0, Math.PI*0.5], azimuth:[-Math.PI * 0.6, Math.PI*0.4]},

        {type: FABRIKSolver.JOINTTYPES.BALLSOCKET, twist:[ -Math.PI*0.25, Math.PI*0.25 ], polar:[0, Math.PI*0.5]} // unconstrained azimuth
    ],
    target,
    "MyChain"
);
*/

class JointConstraint {
    
    public var _boneDir:h3d.Vector;
    public var twist:Limit;
    public var swingFront:h3d.Vector;
    public var swingUp:h3d.Vector;
    public var swingRight:h3d.Vector;
    public var type:JointType; 


    /**
     * @param {h3d.Vector} boneDir direction of the bone that start at this joint. Used to determine twist, swing and constraints
     */
    public function new( boneDir:h3d.Vector  = null ){
        this._boneDir = new h3d.Vector(); 
        if ( boneDir != null ) this._boneDir = boneDir.clone();
        this._boneDir.normalize();

        this.twist = null; //[ 0, Math.PI*2 - 0.0001 ];
        // twist axis == this._boneDir

        // this.swingFront = new h3d.Vector(0,0,1); // axis on which joint rotates
        // this.swingUp = new h3d.Vector(0,1,0);
        // this.swingRight = new h3d.Vector(1,0,0);

        this.swingFront = new h3d.Vector(0,1,0); // axis on which joint rotates
        this.swingUp = new h3d.Vector(0,0,1);
        this.swingRight = new h3d.Vector(1,0,0);

       // vS.set(0, -lw, 0); vE.set(0, -l, 0); am.initRotation( -a+deg90, 0, 0);
       // vS.set(0, 0, -lw); vE.set(0, 0, -l); am.initRotation( 0, -a, 0);
       // vS.set(-lw, 0, 0); vE.set(-l, 0, 0); am.initRotation( 0, 0, -a+deg90);

        this.type = JointType.OMNI; 
    }
    
    /**
     * @param {Object} constraint 
     * possible (concurrent) properties:
     *  - twist : [ minAngle, maxAngle ]  
     */
    public function setConstraint( constraint:Constraint ){
        var temp1 = new h3d.Vector();//_vec3;
        var temp2 = new h3d.Vector();//_vec3_2;

        if ( constraint.twist!=null ){
            this.twist = { min:0, max:0.0001 };
            this.twist.min = constraint.twist.min % (Math.PI*2); 
            this.twist.max = constraint.twist.max % (Math.PI*2); 
            if ( this.twist.min < 0 ) this.twist.min += Math.PI*2;
            if ( this.twist.max < 0 ) this.twist.max += Math.PI*2;
        } else { 
            this.twist = null;
        }

        if ( this.type == JointType.OMNI ) return;

        // compute front, right, up vectors. Usual information for constraint computation
        var front = this.swingFront;
        var right = this.swingRight;
        var up = this.swingUp;

        // fix axis ( user assumes that (0,0,1) == boneDir )
        if ( constraint.axis == null )
            front.set(0,1,0); //front.set(0,0,1); // default same direction as bone
        else 
            front.set( constraint.axis.x, constraint.axis.y, constraint.axis.z );
        
        if ( front.lengthSq() < 0.00001 )
            front.set(0,1,0); //front.set(0,0,1);   // default same direction as bone
        front.normalize();
        
        // compute right axis ( X = cross(Y,Z) ) check front axis is not Y
        up.set(0,0,1); //up.set( 0,1,0 );
        right = up.clone();
        right.cross( front ); // X = cross( Y, Z )
        if ( right.lengthSq() < 0.0001 )
            right.set( 1,0,0 ); // z axis == -+y axis, right will be +x
        else
            right.normalize();

        up = front.clone();
        up.cross( right ); // Y = cross( Z, X )
        up.normalize();

        // transform front, right, up from '+z == boneDir' space to bone space
        temp1.set( 0,0,0 );
        temp2.set( 0,0,1 ); //temp2.set( 0,1,0 ); // default up
        // var mat4 = h3d.Matrix.I();
        // var mat3 = h3d.Matrix.I();
        var mat4 = h3d.Matrix.lookAtX( this._boneDir );// temp1, temp2 ); // apparently it does not set the translation... threejs...
        var lookAtMat = mat4.clone();
        trace("SetConstraint: lookAtX: "+FabrikInverseKinematic.mtos(lookAtMat));
        
        front.transform3x3( lookAtMat );
        right.transform3x3( lookAtMat );
        up.transform3x3( lookAtMat );
        
    }
    
    /**
     * Internal function. Derived classes implements their cusotm behaviours
     * @param {h3d.Vector} swingPos position of bone after applying the swing rotation. Overwritten with corrected position  
     */
    function applyConstraintSwing( swingPos ) {}

    /**
     * @param {THREE.Quaternion} inQuat quaternion to correct. This quaternion represent the rotation to apply to boneDir
     * @param {THREE.Quaternion} outQuat corrected quaternion. Can be the same as inQuat
     */
    public function applyJointConstraint( inQuat:h3d.Quat, outQuat:h3d.Quat, ci:ChainItem ){ 
        var boneDir = this._boneDir;
        var twist = new h3d.Quat();
        var swing = new h3d.Quat();
        var swingPos = new h3d.Vector();
        var swingCorrectedAxis = new h3d.Vector();
        var twistCorrectedAxis = new h3d.Vector(); // this is used after swingCorrectedAxis has finished

        trace("JointConstraint: boneDir:"+boneDir+" in:"+inQuat+" out:"+outQuat);
        // TwistQuat = [ WR,  proj_VTwist( VRot ) ]
        var q = new h3d.Quat( inQuat.x, inQuat.y, inQuat.z );
        q.initDirection( boneDir );
        twist.set( q.x, q.y, q.z, inQuat.w );
        twist.normalize();
        trace(" - twist:"+twist);
        
        // SwingQuat = R*inv(T)
        swing = twist.clone();
        swing.conjugate();
        swing.multiply( swing, inQuat );
        swing.normalize();
        trace(" - swing:"+swing);

        // swing bone
        swingPos = boneDir.clone();
        swingPos.applyQuaternion( swing );
        trace(" - swingQuat:"+swing);

        // actual SWING pos constraint. Specific of each class
        this.applyConstraintSwing( swingPos );
        trace(" - swingPosConstrained:"+swingPos);
        
        // compute corrected swing. 
        swingCorrectedAxis = boneDir.clone();
        swingCorrectedAxis.cross( swingPos );

        trace(" - swingAxisCorrected:"+swingCorrectedAxis);
 
        if ( swingCorrectedAxis.lengthSq() < 0.0001 ){ // swing corrected Position is parallel to twist axis
            if  ( boneDir.dot( swingPos ) < -0.9999) {  // opposite side -> rotation = 180º
                swingCorrectedAxis.set( -boneDir.y, boneDir.x, boneDir.z ); 
                swingCorrectedAxis.cross( boneDir ); // find any axis perpendicular to bone
                swingCorrectedAxis.normalize();
                swing.initRotateAxis( swingCorrectedAxis.x, swingCorrectedAxis.y, swingCorrectedAxis.z, Math.PI ); // rotate 180º
                swing.normalize();
            } else
                swing.set(0,0,0,1); // same vector as twist. No swing required
        } else { 
            swingCorrectedAxis.normalize();
            // swing.setFromAxisAngle( swingCorrectedAxis, boneDir.angleTo( swingPos ) ); //boneDir.angleTo( swingPos ) );
            swing.initRotateAxis( swingCorrectedAxis.x, swingCorrectedAxis.y, swingCorrectedAxis.z, boneDir.angleTo( swingPos ) ); //boneDir.angleTo( swingPos ) );
            swing.normalize();
        }
        Dbg.dQ(IKBoxHeaps.IKBH.g6, 0x008080, 3, ci.initialTransform.origin, swing);
        trace(" - swing:"+swing);
        
        // actual TWIST constraint
        if( this.twist!=null ) {
            var twistAngle = 2 * Math.acos( twist.w ); 
            twistCorrectedAxis.set( twist.x, twist.y, twist.z ); // in reality this is axis*sin(angle/2) but it does not have any effect here
            if ( twistCorrectedAxis.dot( boneDir ) < 0 ) 
                twistAngle = ( -twistAngle ) + Math.PI * 2; // correct angle value as acos only returns 0-180

            twistAngle = _constraintAngle( twistAngle, this.twist.min, this.twist.max );  
            trace(" - twistAngle:"+twistAngle);
          
            // twist.setFromAxisAngle( boneDir, twistAngle );
            twist.initRotateAxis( boneDir.x, boneDir.y, boneDir.z, twistAngle );
            trace(" - twist:"+twist);
        }

        // result
        outQuat.set(twist.x, twist.y, twist.z, twist.w);
        outQuat.multiply(swing, outQuat);
        trace(" - out:"+outQuat);
    }

    function _constraintAngle ( angle:Float, minConstraint:Float = 0, maxConstraint:Float = 6.283185307179586 ) {
        trace("ConstraintAngle: angle:"+angle+" minMax:"+minConstraint+"/"+maxConstraint);
        if ( angle < 0 ){ angle += Math.PI * 2; }
        if ( minConstraint > maxConstraint ){ // range crosses 0º (like range [300º, 45º] )
            if ( angle > maxConstraint && angle < minConstraint ){ // out of boundaries
                angle = _snapToClosestAngle( angle, minConstraint, maxConstraint ); 
            }
        }else{ // normal range (like [0º, 135º] )
            if ( !( angle > minConstraint && angle < maxConstraint ) ){ // out of boundaries
                angle = _snapToClosestAngle( angle, minConstraint, maxConstraint );
            }    
        }
        trace(" - new angle:"+angle);
        return angle;
    }

    function _snapToClosestAngle ( angle:Float, minConstraint:Float = 0, maxConstraint:Float = 6.283185307179586 ) {
        // needed to ensure boundaries when constraint crosses the 0º/360º (discontinuity)
        var min = Math.min ( Math.abs( minConstraint - angle), Math.min( Math.abs( minConstraint - ( angle - Math.PI * 2 ) ), Math.abs( minConstraint - ( angle + Math.PI * 2 ) ) ) );
        var max = Math.min ( Math.abs( maxConstraint - angle), Math.min( Math.abs( maxConstraint - ( angle - Math.PI * 2 ) ), Math.abs( maxConstraint - ( angle + Math.PI * 2 ) ) ) );
        var snapAngle = ( min < max ) ? minConstraint : maxConstraint;
        trace("SnapToClosestAngle: snapAngle:"+snapAngle+" angle:"+angle+" minMax:"+minConstraint+"/"+maxConstraint);
        return snapAngle;
    }
    
}


/**
 * Uses spherical coordinates to handle swing constraint
 */
class JCBallSocket extends JointConstraint {

    public var _polar:Limit;
    public var _azimuth:Limit;

    /**
     * @param {h3d.Vector} boneDir direction of the bone that start at this joint. Used to determine twist, swing and constraints
     */
    public function new( boneDir:h3d.Vector ){
        super( boneDir );
        this.type = JointType.BALLSOCKET;
        
        this._polar = null; // [min, max] rads
        this._azimuth = null; // [min, max] rads
    }

    /**
     * @param {Object} constraint 
     * possible (concurrent) properties:
     *  - twist : [ minAngle, maxAngle ]  rads
     *  - axis : h3d.Vector axis of swing rotation. +z == bone direction
     *  - polar : [ minAngle, maxAngle ] rads. valid ranges are inside [0,PI]. Aperture with respect to axis
     *  - azimuth : [ minAngle, maxAngle ] rads. valid ranges [0, 2PI]. Angle in the plane generated by axis
     */
    override public function setConstraint( constraint:Constraint ){
        super.setConstraint( constraint );
        this._polar = null;
        this._azimuth = null;

        if ( constraint.polar!=null ){ // POLAR range [0-180]
            this._polar = { min: 0, max: Math.PI }; 
            this._polar.min = Math.max( 0, Math.min( Math.PI, constraint.polar.min ) );
            this._polar.max = Math.max( this._polar.min, Math.max(0, Math.min( Math.PI, constraint.polar.max ) ) );
        }
        if ( constraint.azimuth!=null ){
            this._azimuth = { min: 0, max: Math.PI*2 }; 
            this._azimuth.min = constraint.azimuth.min % (Math.PI*2); 
            this._azimuth.max = constraint.azimuth.max % (Math.PI*2);
            if ( this._azimuth.min < 0 ){ this._azimuth.min += Math.PI*2; } 
            if ( this._azimuth.max < 0 ){ this._azimuth.max += Math.PI*2; } 
        }
    }

    /**
     * Internal function. Derived classes implements their cusotm behaviours
     * @param {h3d.Vector} swingPos position of bone after applying the swing rotation. Overwritten with corrected position  
     */
    override function applyConstraintSwing( swingPos:h3d.Vector ){
        if ( this._polar==null && this._azimuth==null ) return;
        var swingPolarAngle:Float = 0;
        var swingAzimuthAngle:Float = 0; // XY plane where +X is 0º
        
        var front = this.swingFront;
        var right = this.swingRight;
        var up = this.swingUp;
        var xy = new h3d.Vector(); 
        // xy = front.clone();
        // xy.sub( swingPos, xy.multiply( front.dot( swingPos ) ) ); // rejection of swingPos
        var v = front.clone();
        var v1 = v.multiply( front.dot( swingPos ) );
        var xy = swingPos.clone();
        xy.sub( v1 ); // rejection of swingPos


        // compute polar and azimuth angles
        swingPolarAngle = front.angleTo( swingPos );
        swingAzimuthAngle = right.angleTo( xy );
        trace("JCBallSocket: swingPolarAngle:"+swingPolarAngle+" swingAzimuthAngle:"+swingAzimuthAngle);
        if( up.dot( xy ) < 0 )
            swingAzimuthAngle = -swingAzimuthAngle + Math.PI * 2;

        // constrain angles
        if ( this._polar!=null )
            swingPolarAngle = _constraintAngle( swingPolarAngle, this._polar.min, this._polar.max );
        if ( this._azimuth!=null )
            swingAzimuthAngle = _constraintAngle( swingAzimuthAngle, this._azimuth.min, this._azimuth.max );
        trace(" - constrained: swingPolarAngle:"+swingPolarAngle+" swingAzimuthAngle:"+swingAzimuthAngle);

        // regenerate point with fixed angles
        swingPos.set( right.x, right.y, right.z );
        swingPos.applyAxisAngle( front.x, front.y, front.z, swingAzimuthAngle );
        trace(" - swingPos(azimuth): "+swingPos);
        var v = swingPos.clone();
        v.cross( front ); // find perpendicular vector
        v.normalize();
        swingPos.applyAxisAngle( v.x, v.y, v.z, Math.PI * 0.5 - swingPolarAngle ); //cross product starts at swingPos. Polar is angle from front -> a = 90 - a
        trace(" - swingPos(polar): "+swingPos);
    }
}

/**
 * Simple hinge constraint
 */
class JCHinge extends JointConstraint {

    public var limits:Limit;

    /**
     * @param {h3d.Vector} boneDir direction of the bone that start at this joint. Used to determine twist, swing and constraints
     */
    public function new( boneDir:h3d.Vector ){
        super( boneDir );
        this.type = JointType.HINGE;
        this.limits = null; // [min,max] rads
    }

    /**
     * @param {Object} constraint 
     * possible (concurrent) properties:
     *  - twist : [ minAngle, maxAngle ]  rads
     *  - axis : h3d.Vector axis of swing rotation. +z == bone direction
     *  - min : minimum angle. Valid ranges [0, 2PI]. Angle in the plane generated by axis
     *  - max : minimum angle. Valid ranges [0, 2PI]. Angle in the plane generated by axis
     */
    override public function setConstraint( constraint:Constraint ){
        super.setConstraint( constraint );
        this.limits = null;
        if ( constraint.limits!=null ) { 
            this.limits = { min: 0, max: Math.PI*2 }; 
            this.limits.min = constraint.limits.min % (Math.PI*2);
            this.limits.max = constraint.limits.max % (Math.PI*2); 
            if ( this.limits.min < 0 ) this.limits.min += Math.PI*2; 
            if ( this.limits.max < 0 ) this.limits.max += Math.PI*2; 
            trace("JCHinge.setConstraints: min="+this.limits.min+" max="+this.limits.max);
        }
    }

    /**
     * Internal function. Derived classes implements their cusotm behaviours
     * @param {h3d.Vector} swingPos position of bone after applying the swing rotation. Overwritten with corrected position  
     */
    override function applyConstraintSwing( swingPos:h3d.Vector ) {
        var v = this.swingFront.clone();

        var dot = v.dot( swingPos );
        if ( dot < -0.9999 && dot > 0.9999 ) 
            swingPos = this.swingRight.clone(); // swingPos parallel to rotation axis
        else {
            swingPos = swingPos.sub( v.multiply( dot ) );
        } // project onto plane

        if ( this.limits==null ) return;

        //TODO:  can be optimized to no use any angle, but cos and sin instead
        var angle = this.swingRight.angleTo( swingPos ); // [0,180]
        trace("JCHinge: angle:"+angle);
        
        // fix angle range from [0,180] to [0,360]
        if ( this.swingUp.dot( swingPos ) < 0)
            angle = -angle + Math.PI*2;
        
        angle = _constraintAngle( angle, this.limits.min, this.limits.max );
        trace(" - constrained: angle: "+angle);

        swingPos.set(swingRight.x, swingRight.y, swingRight.z, swingRight.w);
        swingPos.applyAxisAngle( this.swingFront.x, this.swingFront.y, this.swingFront.z, angle );
        trace(" - swingPos(angle): "+swingPos);
    }
}

class EndEffector {
    public var tipBone:Int;
    public var goalTransform:h3d.Matrix;

    public function new() {
        goalTransform = h3d.Matrix.I();
    }
}

class ChainItem {

    public var children:Array<ChainItem> = [];
    public var parentItem:ChainItem = null;
    public var bone:Int = -1;
    public var length:Float = 0;
    public var initialTransform:h3d.Matrix;
    public var currentPos:h3d.Vector;
    public var currentOri:h3d.Vector;
    public var globalPose:h3d.Matrix;
    public var constraint:JointConstraint;
    public var bindQuat : h3d.Quat;

    public function new() {}

    public function findChild(boneId:Int):ChainItem {
        for (i in children)
            if (boneId == i.bone) return i;
        return null;
    }

    public function addChild(boneId:Int):ChainItem {
        var infantChildId:Int = children.length;
        children[infantChildId] = new ChainItem();
        children[infantChildId].bone = boneId;
        children[infantChildId].parentItem = this;
        return children[infantChildId];
    }
}

class ChainTip {
    public var chainItem:ChainItem = null;
    public var endEffector:EndEffector = null;

    public function new(cI:ChainItem, eE:EndEffector) {
        chainItem = cI;
        endEffector = eE;
    }
}

class Chain {
    public var chainRoot:ChainItem;
    public var middleChainItem:ChainItem = null;
    public var tips:Array<ChainTip> = [];
    public var magnetPosition:h3d.Vector;

    public function new() {
        chainRoot = new ChainItem();
    }
}

class Task {

    public var skeleton: h3d.scene.Skin;
 
    public var chain:Chain;
 
    public var minDistance:Float = 0.00000001;
    public var maxIterations:Int = 10;
 
    public var rootBone:Int = -1;
    public var endEffectors:Array<EndEffector>;
    public var goalGlobalTransform:h3d.Matrix;

    public function new () {
        chain = new Chain();
        endEffectors = [];
    }
}


class Dbg {

    public static function angs(m:h3d.Matrix) {
        var angs = m.getEulerAngles();
        var deg = angs.multiply(180/Math.PI );
        return "angs: "+deg.x+"/"+deg.y+"/"+deg.z+" ("+angs.x+"/"+angs.y+"/"+angs.z+")";
    }

    public static function quat(q:h3d.Quat) {
        var v = new h3d.Vector(1,0,0);
        v.applyQuaternion(q);
        return q.x+"/"+q.y+"/"+q.z+"/"+q.w+" vec:"+v.x+"/"+v.y+"/"+v.z+"(1,0,0)";
    }


    public static function dM(g:h3d.scene.Graphics, m:h3d.Matrix, b:h3d.Vector, t:Float = 2, len:Float = 0.1, offset:h3d.Vector = null ) {
        if (!IKBox.debug) return;
        if (offset==null) offset=new h3d.Vector(0, 0, 0);
        b = b.add(offset);
        var v=new h3d.Vector(len, 0, 0);
        g.lineStyle(t, 0xff0000, 1);
        v.transform3x3(m);
        g.moveTo( b.x, b.y, b.z );
        g.lineTo( b.x+v.x, b.y+v.y, b.z+v.z );

        v.set(0, len, 0);
        g.lineStyle(t, 0x00A000, 1);
        v.transform3x3(m);
        g.moveTo( b.x, b.y, b.z );
        g.lineTo( b.x+v.x, b.y+v.y, b.z+v.z );

        v.set(0, 0, len);
        g.lineStyle(t, 0x0000A0, 1);
        v.transform3x3(m);
        g.moveTo( b.x, b.y, b.z );
        g.lineTo( b.x+v.x, b.y+v.y, b.z+v.z );
    }

    public static function dJ(j:Array<h3d.scene.Mesh>, b, x, y, z) {
        if (j[b]==null) IKBoxHeaps.add(j, b);
        j[b].visible = IKBox.debug;
        j[b].x = x;
        j[b].y = y;
        j[b].z = z;
    }

    public static function drawChain(g:h3d.scene.Graphics, col:Int, chain:Chain, dataType:Int, off:h3d.Vector, alpha:Float, thick:Float) {
        if (!IKBox.debug) return;
        g.lineStyle(thick, col, alpha);
        var subChainTip = chain.tips[0].chainItem;
        var l = 0.04;
        while (subChainTip!=null) {
            if (dataType==1) {
                var pos = subChainTip.globalPose;
                if (subChainTip.parentItem!=null) {
                    var parPos = subChainTip.parentItem.globalPose;
                    g.moveTo(pos.tx+off.x, pos.ty+off.y, pos.tz+off.z);
                    g.lineTo(parPos.tx+off.x, parPos.ty+off.y, parPos.tz+off.z);
                }
            } else if (dataType==2) {
                var pos = subChainTip.initialTransform.clone();
                if (subChainTip.parentItem!=null) {
                    var parPos = subChainTip.parentItem.initialTransform.clone();
                    g.moveTo(pos.tx+off.x, pos.ty+off.y, pos.tz+off.z);
                    g.lineTo(parPos.tx+off.x, parPos.ty+off.y, parPos.tz+off.z);
                }
            } else {
                var pos = subChainTip.currentPos;
                if (subChainTip.parentItem!=null) {
                    var parPos = subChainTip.parentItem.currentPos;
                    g.moveTo(pos.x+off.x, pos.y+off.y, pos.z+off.z);
                    g.lineTo(parPos.x+off.x, parPos.y+off.y, parPos.z+off.z);
                }
            }

            subChainTip = subChainTip.parentItem;
        }
    }

    public static function dQ(g:h3d.scene.Graphics, col:Int, t:Float, base:h3d.Vector, q:h3d.Quat) {
        var v = new h3d.Vector(1,0,0);
        v.applyQuaternion(q);
        dV(g, col, t, base, v);
    }

    public static function dV(g:h3d.scene.Graphics, col:Int, t:Float, base:h3d.Vector, v:h3d.Vector) {
        g.lineStyle(t, col, 1);
        g.moveTo(base.x, base.y, base.z);
        g.lineTo(base.x+v.x, base.y+v.y, base.z+v.z);
    }

    public static function printJointLimits(j, m) {
        // if (j.minAngle!=null) {
            // fan( IKBoxHeaps.IKBH.g5, j.minAngle.x, j.maxAngle.x, 0xff0000, m, 0 );
            // fan( IKBoxHeaps.IKBH.g5, j.minAngle.y, j.maxAngle.y, 0x00ff00, m, 1 );
            // fan( IKBoxHeaps.IKBH.g5, j.minAngle.z, j.maxAngle.z, 0x0000ff, m, 2 );
        // }
        fanC( IKBoxHeaps.IKBH.g5, j, 0xff0000, m, 0 );
    }

    public static function fan(g:h3d.scene.Graphics, minAng:Float, maxAng:Float, col:UInt, mat:h3d.Matrix, xyz:Int ) {
        if (!IKBox.debug) return;
        g.lineStyle(1, col, 0.5);
        var min = minAng * Math.PI / 180;
        var max = maxAng * Math.PI / 180;
        var stp = Math.PI / 72; // 5 deg I think
        var ang = -(2*Math.PI);
        var m = h3d.Matrix.I();
        m.load( mat );
        var am = h3d.Matrix.I();
        var lw = 0.025;
        var ext = lw / Math.floor((max - min) / stp);
        var vS = new h3d.Vector();
        var vE = new h3d.Vector();
        var deg90 = Math.PI/2;
        var base = mat.origin.clone();
        trace("Angles: min: "+min+"("+minAng+") max="+max+"("+maxAng+")");

        function drawAng(a:Float, l:Float) {
            switch (xyz) {
                case 0: vS.set(0, -lw, 0); vE.set(0, -l, 0); am.initRotation( -a+deg90, 0, 0);
                case 1: vS.set(0, 0, -lw); vE.set(0, 0, -l); am.initRotation( 0, -a, 0);
                case 2: vS.set(-lw, 0, 0); vE.set(-l, 0, 0); am.initRotation( 0, 0, -a+deg90);
                // case 0: vS.set(0, -lw, 0); vE.set(0, -l, 0); am.initRotation( -a, 0, 0);
                // case 1: vS.set(0, 0, -lw); vE.set(0, 0, -l); am.initRotation( 0, -a, 0);
                // case 2: vS.set(-lw, 0, 0); vE.set(-l, 0, 0); am.initRotation( 0, 0, -a);
           }
            am.basis.multiply(am.basis, m.basis);

            // trace(" - drawing fan for :"+a+" vS:"+vS+" vE:"+vE+" m"+mtos(am));
            vS.transform3x3(am);
            vE.transform3x3(am);
            // trace(" - transformed vS:"+vS+" vE:"+vE);
            g.moveTo(base.x+vS.x, base.y+vS.y, base.z+vS.z);
            g.lineTo(base.x+vE.x, base.y+vE.y, base.z+vE.z);
        }
        drawAng(min, 0.1);
        drawAng(max, 0.1);
        var len = lw;
        while (ang <= (2*Math.PI)) {
            if (ang>=min && ang<=max) {
                drawAng(ang, len);
                len+=ext;
            } 
            ang += stp;
        }
        drawAng(min, 0.1);
        drawAng(max, 0.1);
    }

    public static function fanC(g:h3d.scene.Graphics, ci:ChainItem, col:UInt, mat:h3d.Matrix, xyz:Int ) {
        if (!IKBox.debug || ci.constraint==null) return;
        g.lineStyle(1, col, 0.5);

        var m = h3d.Matrix.I();
        m.load( mat );
        var am = h3d.Matrix.I();
        var vS = new h3d.Vector();
        var vE = new h3d.Vector();
        var deg90 = Math.PI/2;
        var stp = Math.PI / 72; // 5 deg I think
        var base = mat.origin.clone();

        function drawAng(a:Float, lS:Float, lE:Float, xyz:Int) {
            switch (xyz) {
                case 0: vS.set(0, -lS, 0); vE.set(0, -lE, 0); am.initRotation( -a, 0, 0);
                case 1: vS.set(0, 0, -lS); vE.set(0, 0, -lE); am.initRotation( 0, -a, 0);
                case 2: vS.set(-lS, 0, 0); vE.set(-lE, 0, 0); am.initRotation( 0, 0, -a+deg90);
                // case 0: vS.set(0, -lw, 0); vE.set(0, -l, 0); am.initRotation( -a, 0, 0);
                // case 1: vS.set(0, 0, -lw); vE.set(0, 0, -l); am.initRotation( 0, -a, 0);
                // case 2: vS.set(-lw, 0, 0); vE.set(-l, 0, 0); am.initRotation( 0, 0, -a);
           }
            am.basis.multiply(am.basis, m.basis);

            // trace(" - drawing fan for :"+a+" vS:"+vS+" vE:"+vE+" m"+mtos(am));
            vS.transform3x3(am);
            vE.transform3x3(am);
            // trace(" - transformed vS:"+vS+" vE:"+vE);
            g.moveTo(base.x+vS.x, base.y+vS.y, base.z+vS.z);
            g.lineTo(base.x+vE.x, base.y+vE.y, base.z+vE.z);
        }

        function drawFan(min:Float, max:Float, stp:Float, xyz:Int) {
            var len = 0.1;
            var l2 = len * 2;
            var ext = 0.1 / Math.floor((max - min) / stp);
            drawAng(min, 0, l2, xyz);
            drawAng(max, 0, l2, xyz);
            var ang:Float = 0;
            while (ang <= (2*Math.PI)) {
                if (ang>=min && ang<=max) {
                    drawAng(ang, 0, len, xyz);
                    // len+=ext;
                } 
                ang += stp;
            }
            drawAng(min, 0, l2, xyz);
            drawAng(max, 0, l2, xyz);
        }


        var c=ci.constraint;
        if (c.type==JointType.HINGE) {
            var jcH:JCHinge = cast c;
            var min = jcH.limits.min;
            var max = jcH.limits.max;
            trace("FanC-Hinge: min: "+min+"("+(min*180/Math.PI)+") max="+max+"("+(max*180/Math.PI)+")");
            drawFan(min, max, stp, 0);
        }

        if (c.type==JointType.BALLSOCKET) {
            var jcBS:JCBallSocket = cast c;
        }
    }

}
