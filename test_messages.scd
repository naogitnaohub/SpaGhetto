(
// Clean up any existing listeners before starting
OSCdef.freeAll;

"=============================================".postln;
" OSC MONITOR ACTIVE: Listening on Port 57120 ".postln;
"=============================================".postln;

// --- RIGHT PANEL LISTENERS ---

OSCdef(\printScale, { |msg|
	("👉 [RIGHT] SCALE: " + msg[1]).postln;
}, '/fader/scale');

OSCdef(\printRadius, { |msg|
	("👉 [RIGHT] RADIUS: " + msg[1]).postln;
}, '/fader/radius');

OSCdef(\printWaveNum, { |msg|
	("👉 [RIGHT] WAVE TERRAIN FUNCTION: " + msg[1].asInteger).postln;
}, '/fader/waveNumber');


// --- LEFT PANEL LISTENERS ---

OSCdef(\printMidDrive, { |msg|
	("👈 [LEFT]  MID DRIVE: " + msg[1]).postln;
}, '/fader/midDrive');

OSCdef(\printHighDrive, { |msg|
	("👈 [LEFT]  HIGH DRIVE: " + msg[1]).postln;
}, '/fader/highDrive');

OSCdef(\printFeedback, { |msg|
	("👈 [LEFT]  FEEDBACK: " + msg[1]).postln;
}, '/fader/feedback');

OSCdef(\printDelay, { |msg|
	("👈 [LEFT]  DELAY (ms): " + msg[1]).postln;
}, '/fader/delay');

OSCdef(\printType, { |msg|
	("👈 [LEFT]  TYPE SELECTOR: " + msg[1].asInteger).postln;
}, '/fader/type');

OSCdef(\printReverb, { |msg|
	("👈 [LEFT]  REVERB: " + msg[1]).postln;
}, '/fader/reverb');

)

// To stop printing completely without closing SuperCollider, run this line:
// OSCdef.freeAll;
