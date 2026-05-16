#pragma once
#include <JuceHeader.h>

class MainComponent : public juce::Component,
    public juce::Slider::Listener,
    public juce::Timer,
    public juce::OSCReceiver,
    public juce::OSCReceiver::Listener<juce::OSCReceiver::MessageLoopCallback> 
{
public:
    MainComponent();
    ~MainComponent() override;

    void paint(juce::Graphics& g) override;
    void resized() override;
    void sliderValueChanged(juce::Slider* slider) override;
    void timerCallback() override;

    void oscMessageReceived(const juce::OSCMessage& message) override;

private:
    juce::Slider faderDryWet, faderDrive, faderCutoff, faderVolume;
    juce::Slider faderSelector;

    juce::Label lblDryWet, lblDrive, lblCutoff, lblVolume, lblSelector;

    juce::OSCSender oscSender;
    bool isIncomingMessage = false;
    float phase = 0.0f;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(MainComponent)
};
