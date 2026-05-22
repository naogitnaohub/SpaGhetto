#include "MainComponent.h"

MainComponent::MainComponent()
{
    // 1. Connect networks: Out to Processing (9001), In from Processing (9002)
    oscSender.connect ("127.0.0.1", 9001); 
    if (connect (9002)) 
    {
        juce::OSCReceiver::addListener (this); 
    }

    // 2. Inline helper to quickly generate standard rotary knobs
    auto setupFader = [this](juce::Slider& s, juce::Label& l, juce::String name, double min, double max, double defaultVal) 
    {
        addAndMakeVisible (s);
        s.setSliderStyle (juce::Slider::RotaryHorizontalVerticalDrag);
        s.setTextBoxStyle (juce::Slider::TextBoxBelow, false, 70, 20);
        s.setRange (min, max, 0.01);
        s.setValue (defaultVal);
        s.addListener (this);
        
        addAndMakeVisible (l);
        l.setText (name, juce::dontSendNotification);
        l.setJustificationType (juce::Justification::centred);
    };

    // 3. Instantiate the three parameters
    setupFader (faderScale,  lblScale,  "SCALE",  0.3, 5.0, 1.5);
    setupFader (faderRadius, lblRadius, "RADIUS", 0.2, 6.0, 2.0);
    setupFader (faderSpeed,  lblSpeed,  "SPEED",  0.1, 6.0, 1.0);

    setSize (450, 150); 
}

MainComponent::~MainComponent() 
{
    juce::OSCReceiver::removeListener (this);
}

// ---- OUTBOUND TRAFFIC: Dragging a knob sends data to Processing ----
void MainComponent::sliderValueChanged (juce::Slider* slider)
{
    if (isIncomingMessage) return; // Halt infinite loop echoes

    if (slider == &faderScale)   oscSender.send ("/juce/scale",  (float)faderScale.getValue());
    if (slider == &faderRadius)  oscSender.send ("/juce/radius", (float)faderRadius.getValue());
    if (slider == &faderSpeed)   oscSender.send ("/juce/speed",  (float)faderSpeed.getValue());
}

// ---- INBOUND TRAFFIC: Processing moves a slider, JUCE updates to match ----
void MainComponent::oscMessageReceived (const juce::OSCMessage& message)
{
    if (message.size() == 0) return;

    float value = message[0].getFloat32();
    juce::String path = message.getAddressPattern().toString();

    isIncomingMessage = true; 

    if (path == "/processing/scale")        faderScale.setValue (value, juce::sendNotificationSync);
    else if (path == "/processing/radius")  faderRadius.setValue (value, juce::sendNotificationSync);
    else if (path == "/processing/speed")   faderSpeed.setValue (value, juce::sendNotificationSync);

    isIncomingMessage = false; 
}

void MainComponent::paint (juce::Graphics& g) 
{ 
    g.fillAll (juce::Colour::fromRGB (20, 18, 16)); // Minimal dark canvas
}

void MainComponent::resized()
{
    int dialW = 120, dialH = 90, labelY = 15, dialY = 40;
    
    // Lay out dials horizontally side-by-side
    faderScale.setBounds  (20,  dialY, dialW, dialH); lblScale.setBounds  (20,  labelY, dialW, 20);
    faderRadius.setBounds (160, dialY, dialW, dialH); lblRadius.setBounds (160, labelY, dialW, 20);
    faderSpeed.setBounds  (300, dialY, dialW, dialH); lblSpeed.setBounds  (300, labelY, dialW, 20);
}
