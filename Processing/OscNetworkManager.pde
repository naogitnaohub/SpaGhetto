/*
  ==============================================================================
    OSC NETWORK MANAGER
    
    This class handles the bidirectional communication between Processing and JUCE via OSC messages.
    - It listens for knob movements in JUCE and instantly updates Processing's sliders.
    - It sends messages back to JUCE when you slide faders inside Processing.
    
  ==============================================================================
*/

import oscP5.*;
import netP5.*;

class OscNetworkManager {
  OscP5 oscP5;            // Handles incoming network data
  NetAddress juceAddress; // Stores where to send outgoing network data
  PApplet app;

  // Port settings 
  final int PORT_IN  = 9001; 
  final int PORT_OUT = 9002; 
  final String IP_LOCAL = "127.0.0.1";

  // Setup the connection when the function is called
  OscNetworkManager(PApplet app) {
    this.app = app;
    this.oscP5 = new OscP5(app, PORT_IN);
    this.juceAddress = new NetAddress(IP_LOCAL, PORT_OUT);
    println("OscNetworkManager: Listening for JUCE dials on Port " + PORT_IN);
  }

  // Receives and parses messages sent from JUCE
  void parseIncoming(OscMessage msg) {
    String pattern = msg.addrPattern();
    if (msg.arguments().length == 0) return; // safety for empty messages

    float value = msg.get(0).floatValue(); // Grab the first data number

    // Sync incoming values directly to Processing faders
    if (pattern.equals("/juce/scale")) {
      fScale.setValue(value);
    } 
    else if (pattern.equals("/juce/radius")) {
      fRadius.setValue(value);
    } 
    else if (pattern.equals("/juce/speed")) {
      fSpeed.setValue(value);
    }
    else if (pattern.equals("/sc/cx")) {
    // 0..1 → -8..+8 nel mondo
    float wx = value * 16 - 8;
    orbit.setPosition(wx, orbit.cz);
    }
    else if (pattern.equals("/sc/cy")) {
    float wz = value * 16 - 8;
    orbit.setPosition(orbit.cx, wz);
    }
else if (pattern.equals("/sc/radius")) {
  // 0..1 → range del fader RADIUS
  fRadius.setValue(lerp(0.2, 6.0, value));
}
else if (pattern.equals("/sc/a")) {
  fScale.setValue(lerp(0.3, 5.0, value));
}
else if (pattern.equals("/sc/b")) {
  // b non ha un fader, lo settiamo direttamente sul terreno
  terrain.setB(lerp(0.1, 2.0, value));
}
else if (pattern.equals("/sc/terrain")) {
  terrain.setWaveNumber((int) value);
}
  }

  // Sends messages from Processing to JUCE when moving sliders
  void transmit(String addressPattern, float parameterValue) {
    OscMessage messagePacket = new OscMessage(addressPattern);
    messagePacket.add(parameterValue);
    oscP5.send(messagePacket, juceAddress);
  }
}
