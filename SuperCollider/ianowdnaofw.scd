(
// 1. BOOT DEL SERVER E APERTURA ANALIZZATORI
s.boot;
s.scope;
s.freqscope;
)

// Indirizzo OSC verso Processing
~processing = NetAddr("127.0.0.1", 9001);


// =====================================================================
// FASE 1: ALLOCAZIONE BUS DI CONTROLLO
// Questi conterranno SOLO valori normalizzati (da 0.0 a 1.0)
// in arrivo da Arduino via OSC.
// =====================================================================
(
~b_cx = Bus.control(s, 1).set(0.5); // Centro X (Joystick)
~b_cy = Bus.control(s, 1).set(0.5); // Centro Y (Joystick)
~b_r  = Bus.control(s, 1).set(0.5); // Raggio (Accelerometro/Pitch)
~b_a  = Bus.control(s, 1).set(0.5); // Parametro A (Giroscopio/Roll)
~b_b  = Bus.control(s, 1).set(0.5); // Parametro B (Giroscopio o Fader)

"Bus allocati con successo!".postln;
)

// =====================================================================
// FASE 2: IL DIZIONARIO INTELLIGENTE E MOTORE UNIFICATO
// =====================================================================
(
~terrains = (

	wave1: (
		func: { |x, y, a, b| sin((x*sin(x) - (y*sin(y) * log(x * x + 1))) / a) },
		makeX: { |norm| norm.linlin(0, 1, -20, 20) },   // centro X (feature nuova, joystick)
		makeY: { |norm| norm.linlin(0, 1, -20, 20) },   // centro Y
		makeR: { |norm| norm.linlin(0, 1, 0, 10) },     // r diretto, come MouseX.kr(0,10)
		makeA: { |norm| LFSaw.kr(norm.linlin(0, 1, 0.05, 100)).range(1, 10) },  // a = LFSaw, come prima
		baseFreq: [80, 80.1],
		amp: 1

    ),

	vivisciolto: (
		func: { |x, y, a, b| sin(a*(x*x+y*y)) },
		makeX: { |norm| norm.linlin(0, 1, -20, 20) },
		makeY: { |norm| norm.linlin(0, 1, -20, 20) },
		makeR: { |norm| norm.linlin(0, 1, 0, 5) },      // come MouseX.kr(0,5)
		makeA: { |norm| LFSaw.kr(norm.linlin(0, 1, 0.05, 20)).range(1, 10) },  // LFSaw, vel max 20
		baseFreq: [40, 40.5],
		amp: 1

	),

    ritmo1: (
		func: { |x, y, a, b| sin(a*(b*(x*x+y*y)).exp) },
		makeX: { |norm| norm.linlin(0, 1, -20, 20) },
		makeY: { |norm| norm.linlin(0, 1, -20, 20) },
		makeR: { |norm|
			var maxR = SinOsc.kr(10).range(0.15, 0.5);                  // tetto pulsante a 10 Hz
			SinOsc.kr(norm.linlin(0, 1, 0, 10)).range(0.02, maxR)       // r pulsa, vel dal sensore
		},
		makeA: { |norm| SinOsc.kr(norm.linlin(0, 1, 0.05, 10)).range(1, 10) },  // a = SinOsc
		baseFreq: [120, 120.5],
		amp: 5
                                     // compensazione volume!
    ),

    extra: (
		func: { |x, y, a, b| sin(a*(y*x))*cos(a*(x*x-y*y)) },
		makeX: { |norm| norm.linlin(0, 1, -20, 20) },
		makeY: { |norm| norm.linlin(0, 1, -20, 20) },
		makeR: { |norm| norm.linlin(0, 1, 0.1, 8) },
		makeA: { |norm| norm.linlin(0, 1, 1, 5) },
		baseFreq: [60, 60.1],
		amp: 1
	),
);

// Lista per lo switch tra i suoni
~terrainNames = [\wave1, \vivisciolto, \ritmo1, \extra];
~currentIndex = 0;

~loadTerrain = { |name|
    var t = ~terrains[name];
    "Caricamento Terrain: %".format(name).postln;

    Ndef(\myTerrain, {
        var norm_cx = In.kr(~b_cx, 1).lag(0.1);
        var norm_cy = In.kr(~b_cy, 1).lag(0.1);
        var norm_r  = In.kr(~b_r, 1).lag(0.1);
        var norm_a  = In.kr(~b_a, 1).lag(0.1);
        var norm_b  = In.kr(~b_b, 1).lag(0.1);

        // ogni parametro è ora COSTRUITO dal terrain (LFO inclusi)
        var cx = t[\makeX].value(norm_cx);
        var cy = t[\makeY].value(norm_cy);
        var r  = t[\makeR].value(norm_r);
        var a  = t[\makeA].value(norm_a);
        var b  = norm_b.linlin(0, 1, 0.1, 2);   // b lo lasciamo così per ora

        var phi = LFSaw.ar(t[\baseFreq], -1).range(0, 2pi);
        var x = cx + (r * cos(phi));
        var y = cy + (r * sin(phi));

        var sig = t[\func].value(x, y, a, b) * t[\amp];
        Limiter.ar(sig, 0.2)
    });
};

"Dizionario e funzioni caricati in memoria senza errori!".postln;
)

// =====================================================================
// FASE 3: AVVIO DEL MOTORE AUDIO
// =====================================================================
(
Ndef(\myTerrain).fadeTime = 4; // crossfade di 4 secondi
~loadTerrain.value(~terrainNames[~currentIndex]);
Ndef(\myTerrain).play;
"Motore audio avviato!".postln;
)

// =====================================================================
// FASE 4 (AGGIORNATA): RICEVITORI OSC CON DEBUG
// =====================================================================
(
OSCdef(\sensorInput, { |msg, time, addr, recvPort|
    var cx, cy, r, a, b;
    cx = msg[1].linlin(0, 1023, 0.0, 1.0);
    cy = msg[2].linlin(0, 1023, 0.0, 1.0);
    r  = msg[5].linlin(100, 600, 0.0, 1.0);
    a  = msg[4].linlin(150, 500, 0.0, 1.0);
    b  = msg[5].linlin(200, 700, 0.0, 1.0);
    ~b_cx.set(cx); ~b_cy.set(cy);
    ~b_r.set(r);   ~b_a.set(a);   ~b_b.set(b);
    // inoltra a Processing
    ~processing.sendMsg("/sc/cx", cx);
    ~processing.sendMsg("/sc/cy", cy);
    ~processing.sendMsg("/sc/radius", r);
    ~processing.sendMsg("/sc/a", a);
    ~processing.sendMsg("/sc/b", b);
}, '/sensors');
OSCdef(\buttonInput, { |msg, time, addr, recvPort|
    if(msg[1] == 1) {
        ~currentIndex = (~currentIndex + 1) % ~terrainNames.size;
        ~loadTerrain.value(~terrainNames[~currentIndex]);
        // 1-based per coerenza col waveNumber di Processing
        ~processing.sendMsg("/sc/terrain", ~currentIndex + 1);
    };
}, '/btn');

)