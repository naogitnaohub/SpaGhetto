/*
  ==============================================================================
    OSC NETWORK MANAGER
    
    This class handles the bidirectional comunication between Processing and JUCE via OSC messages.
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
  }

  // Sends messages from Processing to JUCE when you moving sliders
  void transmit(String addressPattern, float parameterValue) {
    OscMessage messagePacket = new OscMessage(addressPattern);
    messagePacket.add(parameterValue);
    oscP5.send(messagePacket, juceAddress);
  }
}
