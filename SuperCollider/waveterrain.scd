(
// 1. BOOT DEL SERVER E APERTURA ANALIZZATORI
s.boot;
s.scope;
s.freqscope;
)



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
	makeB: { |norm| norm.linlin(0, 1, 0.1, 2) }, // 0.5->3 prova
    baseFreq: [80, 80.1],
    amp: 1,
	lim: 0.2

    ),

  vivisciolto: (
	func: { |x, y, a, b| sin(a*(x*x+y*y)) }, //*cos(b*x) prova
    makeX: { |norm| norm.linlin(0, 1, -20, 20) },
    makeY: { |norm| norm.linlin(0, 1, -20, 20) },
    makeR: { |norm| norm.linlin(0, 1, 0, 5) },      // come MouseX.kr(0,5)
    makeA: { |norm| LFSaw.kr(norm.linlin(0, 1, 0.05, 20)).range(1, 10) },  // LFSaw, vel max 20
	makeB: { |norm| norm.linexp(0, 1, 0.5, 10) }, //linexp per var. esponenziali
 //makeB: { |norm| norm.linlin(0, 1, 0.1, 15) }, // Più aumenti b, più il suono si "sfrangia" e diventa metallico
    baseFreq: [40, 40.5],
    amp: 1,
	lim: 0.2

  ),

    ritmo1: (
    func: { |x, y, a, b| sin(a*(b*(x*x+y*y)).exp) },
    makeX: { |norm| norm.linlin(0, 1, -20, 20) },
    makeY: { |norm| norm.linlin(0, 1, -20, 20) },
    makeR: { |norm|
      var maxR = SinOsc.kr(10).range(0.15, 0.5);        // tetto pulsante a 10 Hz
      SinOsc.kr(norm.linlin(0, 1, 0, 10)).range(0.02, maxR)       // r pulsa, vel dal sensore
    },
    makeA: { |norm| SinOsc.kr(norm.linlin(0, 1, 0.05, 10)).range(1, 10) },  // a = SinOsc
	makeB: { |norm| norm.linexp(0, 1, 0.5, 0.8) }, // linexp per var. esponenziali
 //makeB: { |norm| norm.linexp(0, 1, 0.05, 1.2) }, // Esponenziale: da quasi fermo a glitch ritmico totale
    baseFreq: [120, 120.5],
    amp: 4,
    lim: 1.0        // compensazione volume!
    ),

    extra: (
    func: { |x, y, a, b| sin(a*(y*x))*cos(b*(x*x-y*y)) },
    makeX: { |norm| norm.linlin(0, 1, -20, 20) },
    makeY: { |norm| norm.linlin(0, 1, -20, 20) },
    makeR: { |norm| norm.linlin(0, 1, 0.1, 8) },
    makeA: { |norm| norm.linlin(0, 1, 1, 5) },
	makeB: { |norm| norm.linexp(0, 1, 0.5, 10) }, // Usiamo linexp per variazioni esponenziali
 //makeB: { |norm| norm.linlin(0, 1, 0.5, 8) }, // Controllo di densità delle armoniche superiori
    baseFreq: [60, 60.1],
    amp: 1,
	lim: 0.2
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
		var b  = t[\makeB].value(norm_b); // Ora usa la funzione del dizionario!

        var phi = LFSaw.ar(t[\baseFreq], -1).range(0, 2pi);
        var x = cx + (r * cos(phi));
        var y = cy + (r * sin(phi));

        var sig = t[\func].value(x, y, a, b) * t[\amp];
        Limiter.ar(sig, t[\lim])
    });
};

// Inizializziamo lo stato
~isLayered = false;

// Creiamo un generatore di Synth (NodeProxy) riutilizzabile.
// L'argomento 'isLive' decide se leggere dai sensori in tempo reale o usare valori fissi.
~makeTerrainFunc = { |name, isLive = true|
    var t = ~terrains[name];
    { |freeze_cx=0.5, freeze_cy=0.5, freeze_r=0.5, freeze_a=0.5, freeze_b=0.5|
        // Se è Live, leggiamo i Bus. Se è Drone (Freeze), leggiamo gli argomenti della funzione
        var norm_cx = if(isLive, { In.kr(~b_cx, 1).lag(0.1) }, { freeze_cx });
        var norm_cy = if(isLive, { In.kr(~b_cy, 1).lag(0.1) }, { freeze_cy });
        var norm_r  = if(isLive, { In.kr(~b_r, 1).lag(0.1)  }, { freeze_r });
        var norm_a  = if(isLive, { In.kr(~b_a, 1).lag(0.1)  }, { freeze_a });
        var norm_b  = if(isLive, { In.kr(~b_b, 1).lag(0.1)  }, { freeze_b });

        var cx = t[\makeX].value(norm_cx);
        var cy = t[\makeY].value(norm_cy);
        var r  = t[\makeR].value(norm_r);
        var a  = t[\makeA].value(norm_a);
        var b  = t[\makeB].value(norm_b);

        var phi = LFSaw.ar(t[\baseFreq], -1).range(0, 2pi);
        var x = cx + (r * cos(phi));
        var y = cy + (r * sin(phi));

        var sig = t[\func].value(x, y, a, b) * t[\amp];
        Limiter.ar(sig, t[\lim])
    }
};

// Carichiamo il primo suono LIVE
Ndef(\live, ~makeTerrainFunc.value(~terrainNames[~currentIndex], true)).play;
Ndef(\drone).play; // Prepariamo il canale drone vuoto

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
// FASE 4: RICEVITORI OSC (NUOVA MAPPATURA ACCELEROMETRO / JOYSTICK)
// =====================================================================
(
OSCdef(\sensorInput, { |msg, time, addr, recvPort|
    // msg.postln; // Scommenta solo se vuoi fare debug e vedere i numeri

    // --- NUOVA MAPPATURA ---
    // msg[1]=jx, msg[2]=jy, msg[3]=ax, msg[4]=ay, msg[5]=az

    // 1. Accelerometro (ax, ay) muove il centro dell'orbita (X, Y)
    ~b_cx.set(msg[3].linlin(0, 1023, 0.0, 1.0)); //100-700
    ~b_cy.set(msg[4].linlin(0, 1023, 0.0, 1.0)); //100-700

    // 2. Accelerometro (az) muove il Raggio
    ~b_r.set(msg[5].linlin(0, 1023, 0.0, 1.0)); //100-600

    // 3. Joystick (jx, jy) modula i parametri timbrici A e B
    ~b_a.set(msg[1].linlin(200, 1000, 0.0, 1.0));
    ~b_b.set(msg[2].linlin(200, 1000, 0.0, 1.0));

}, '/sensors');


// MACCHINA A STATI (BOTTONE)
OSCdef(\buttonInput, { |msg, time, addr, recvPort|
    if(msg[1] == 0) {
        if(~isLayered == false) {
            // STATO 1: FREEZE (Drone)
            var currentTerrain = ~terrainNames[~currentIndex];
            "--- FREEZE! --- Salvataggio % come Drone...".format(currentTerrain).postln;

            // 1. Leggiamo (in modo sincrono) il valore esatto dei bus in questo istante
            ~b_cx.get({ |val_cx|
            ~b_cy.get({ |val_cy|
            ~b_r.get({  |val_r|
            ~b_a.get({  |val_a|
            ~b_b.get({  |val_b|

                // 2. Creiamo il drone passandogli i valori congelati (isLive = false)
                Ndef(\drone).fadeTime = 0.5;
                Ndef(\drone, ~makeTerrainFunc.value(currentTerrain, false));
                Ndef(\drone).set(
                    \freeze_cx, val_cx, \freeze_cy, val_cy,
                    \freeze_r, val_r,   \freeze_a, val_a, \freeze_b, val_b
                );
            })})})})});

            // 3. Avanziamo il suono LIVE al terreno successivo
            ~currentIndex = (~currentIndex + 1) % ~terrainNames.size;
            "Nuovo suono Live: %".format(~terrainNames[~currentIndex]).postln;
            Ndef(\live).fadeTime = 0.5;
            Ndef(\live, ~makeTerrainFunc.value(~terrainNames[~currentIndex], true));

            ~isLayered = true;
        } {
            // STATO 0: CLEAR (Solo)
            "--- CLEAR! --- Spegnimento Drone...".postln;

            Ndef(\drone).fadeTime = 4;
            Ndef(\drone).clear(4); // Rilascia il synth con un fade di 4 secondi

            // Avanziamo il suono LIVE
            ~currentIndex = (~currentIndex + 1) % ~terrainNames.size;
            "Nuovo suono Live: %".format(~terrainNames[~currentIndex]).postln;
            Ndef(\live).fadeTime = 0.5;
            Ndef(\live, ~makeTerrainFunc.value(~terrainNames[~currentIndex], true));

            ~isLayered = false;
        };
    };
}, '/btn');

"OSCdefs in ascolto con nuova mappatura (Acc=Movimento, Joy=Timbro)".postln;
)