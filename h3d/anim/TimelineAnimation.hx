package h3d.anim;

import h3d.anim.TimelineLinearAnimation;

class TimelineAnimation extends Animation {

	var totalDuration:Float;
	var restartAnim:Bool = true;

	function new(name, frameCount, totalDuration) {
		this.totalDuration = totalDuration;
		super( name, frameCount, 0 );
	}

	override public function getDuration() {
		return totalDuration;
	}

	override function clone( ?a : Animation ) {
		if( a == null )
			a = new TimelineAnimation(name, frameCount, totalDuration);
		super.clone(a);
		return a;
	}

	function getTimeFrame( o:TimelineLinearObject ) {
		var frm:h3d.anim.TimelineLinearAnimation.TimelineLinearFrame;
		for (f in o.currentFrame...o.frames.length) {
			frm = o.frames[f];
			if (frm.keyTime > frame)
				return f-1;
		}
		return o.frames.length-1;
	}

	override public function update(dt:Float) : Float {
		if( !isInstance )
			throw "You must instanciate this animation first";

		if( !isPlaying() )
			return 0;

		// check events
		if( events != null && onEvent != null ) {
			var f0 = Std.int(frame);
			var f1 = Std.int(frame + dt * speed * sampling);
			if( f1 >= frameCount ) f1 = frameCount - 1;
			for( f in f0...f1 + 1 ) {
				if( f == lastEvent ) continue;
				lastEvent = f;
				if( events[f] != null ) {
					var oldF = frame, oldDT = dt;
					dt -= (f - frame) / (speed * sampling);
					frame = f;
					for(e in events[f])
						onEvent(e);
					if( frame == f && f == frameCount - 1 ) {
						frame = oldF;
						dt = oldDT;
						break;
					} else
						return dt;
				}
			}
		}

		// check on anim end
		if( onAnimEnd != null ) {
			var end = endFrame();
			var et = speed == 0 ? 0 : (end - frame) / (speed * sampling);
			if( et <= dt && et > 0 ) {
				frame = end;
				dt -= et;
				onAnimEnd();
				// if we didn't change the frame or paused the animation, let's end it
				if( frame == end && isPlaying() ) {
					if( loop ) {
						frame = 0;
					} else {
						// don't loop infinitely
						dt = 0;
					}
				}
				return dt;
			}
		}

		// update frame
		frame += dt * speed;
		if( frame >= totalDuration ) {
			if( loop ) {
				frame %= totalDuration;
				restartAnim = true;
			} else
				frame = totalDuration;
		}
		return 0;
	}
}