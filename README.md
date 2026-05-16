# SpaGhetto
A collaborative audio-visual application featuring a JUCE-based hybrid synthesizer and processor, SuperCollider wavetable synthesis, and responsive Processing visuals.


## Core Architecture
* **The Brain (JUCE):** Central engine managing audio routing, MIDI input, and OSC/Serial communication.
* **Audio Engine (SuperCollider):** Generates and streams wavetable synthesis to the JUCE host.
* **Visuals & Control (Processing):** Drives the GUI, captures mouse interaction, and renders real-time audio waveforms.
* **Hardware Interface (Arduino):** Maps an accelerometer (wavetable modulation) and joystick (dry/wet, drive) via OSC/Serial.
* **Future Scope:** Full MIDI keyboard integration for pitch, gate, and velocity tracking.

## First commit: v1.0 (sendReceive)
* Implements basic OSC communication between Processing and JUCE.
* Synchronizes 4-waveform selection and parameter control across both GUIs.
