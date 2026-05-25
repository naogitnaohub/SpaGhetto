import oscP5.*;
import netP5.*;

class OscNetworkManager {
  OscP5 oscP5;            
  NetAddress scAddress; // Renamed to accurately track your SuperCollider target destination
  PApplet app;

  // Port settings 
  final int PORT_IN  = 9001; 
  final int PORT_OUT = 57120; // --- CHANGED: Points directly to SuperCollider's listener port!
  final String IP_LOCAL = "127.0.0.1";

  OscNetworkManager(PApplet app) {
    this.app = app;
    this.oscP5 = new OscP5(app, PORT_IN);
    this.scAddress = new NetAddress(IP_LOCAL, PORT_OUT);
    println("OscNetworkManager: Direct connection bound to SuperCollider on Port " + PORT_OUT);
  }

  // Parses incoming data streams (If SuperCollider sends control information back to Processing)
  void parseIncoming(OscMessage msg) {
    String pattern = msg.addrPattern();
    if (msg.arguments().length == 0) return; 

    float value = msg.get(0).floatValue(); 

    // --- Right Side Sync ---
    if (pattern.equals("/fader/scale") || pattern.equals("/sc/a")) {
      fScale.setValue(pattern.equals("/sc/a") ? lerp(0.3, 5.0, value) : value);
    } 
    else if (pattern.equals("/fader/radius") || pattern.equals("/sc/radius")) {
      fRadius.setValue(pattern.equals("/sc/radius") ? lerp(0.2, 6.0, value) : value);
    } 
    else if (pattern.equals("/fader/waveNumber") || pattern.equals("/sc/terrain")) {
      fWaveTerrain.setIntValue(value);
    }
    
    // --- Left Side Sync ---
    else if (pattern.equals("/fader/midDrive")) {
      fMidDrive.setValue(value);
    }
    else if (pattern.equals("/fader/highDrive")) {
      fHighDrive.setValue(value);
    }
    else if (pattern.equals("/fader/lowDrive")) {
      fLowDrive.setValue(value);
    }
    else if (pattern.equals("/fader/feedback")) {
      fFeedback.setValue(value);
    }
    else if (pattern.equals("/fader/delay")) {
      fDelay.setValue(value);
    }
    else if (pattern.equals("/fader/type")) {
      fType.setIntValue(value);
    }
     else if (pattern.equals("/fader/lmXover")) {
      fLMX.setValue(value);
    }
     else if (pattern.equals("/fader/mhXover")) {
      fMHX.setValue(value);
    }
    
    
    // --- Orbit Vector Synchronizations ---
    else if (pattern.equals("/sc/cx")) {
      float wx = value * 16 - 8;
      orbit.setPosition(wx, orbit.cz);
    }
    else if (pattern.equals("/sc/cy")) {
      float wz = value * 16 - 8;
      orbit.setPosition(orbit.cx, wz);
    }
    else if (pattern.equals("/sc/b")) {
      terrain.setB(lerp(0.1, 2.0, value));
    }
  }

  // Packages parameters up and fires them cleanly over the localhost bridge loop
  void transmit(String addressPattern, float parameterValue) {
    OscMessage messagePacket = new OscMessage(addressPattern);
    messagePacket.add(parameterValue);
    oscP5.send(messagePacket, scAddress);
  }
}
