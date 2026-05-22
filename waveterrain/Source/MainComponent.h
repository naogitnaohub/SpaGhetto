#pragma once
#include <JuceHeader.h>

class MainComponent  : public juce::Component,
                       public juce::Slider::Listener,
                       public juce::OSCReceiver,
                       public juce::OSCReceiver::Listener<juce::OSCReceiver::MessageLoopCallback>
{
public:
    MainComponent();
    ~MainComponent() override;

    void paint (juce::Graphics&) override;
    void resized() override;
    
    // OSC and Slider interface overrides
    void sliderValueChanged (juce::Slider* slider) override;
    void oscMessageReceived (const juce::OSCMessage& message) override;

private:
    // UI Elements
    juce::Slider faderScale, faderRadius, faderSpeed;
    juce::Label  lblScale,  lblRadius,  lblSpeed;

    // Networking Core
    juce::OSCSender oscSender;
    bool isIncomingMessage = false;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MainComponent)
};
