#include "MainComponent.h"

MainComponent::MainComponent()
{
    oscSender.connect("127.0.0.1", 9001); // Out to Processing

    if (connect(9002)) // In from Processing
    {
        addListener(this); // Listens globally to all incoming paths on 9002
    }

    auto setupFader = [this](juce::Slider& s, juce::Label& l, juce::String name, double max, double defaultValue) {
        addAndMakeVisible(s);
        s.setRange(0.0, max, 0.01);
        s.setValue(defaultValue);
        s.addListener(this);
        addAndMakeVisible(l);
        l.setText(name, juce::dontSendNotification);
        l.setJustificationType(juce::Justification::centred);
        };

    setupFader(faderDryWet, lblDryWet, "Dry / Wet", 1.0, 0.5);
    setupFader(faderDrive, lblDrive, "Drive", 1.0, 0.2);
    setupFader(faderCutoff, lblCutoff, "Cutoff Freq", 1.0, 0.7);
    setupFader(faderVolume, lblVolume, "Volume", 1.0, 0.8);

    addAndMakeVisible(faderSelector);
    faderSelector.setRange(0.0, 3.0, 1.0);
    faderSelector.setValue(0.0);
    faderSelector.addListener(this);
    addAndMakeVisible(lblSelector);
    lblSelector.setText("Wave Type (0-3)", juce::dontSendNotification);
    lblSelector.setJustificationType(juce::Justification::centred);

    setSize(600, 180);
    startTimerHz(60);
}

MainComponent::~MainComponent() { stopTimer(); }

void MainComponent::sliderValueChanged(juce::Slider* slider)
{
    if (isIncomingMessage) return; // Prevent network feedback loop

    if (slider == &faderDryWet)   oscSender.send("/juce/drywet", (float)faderDryWet.getValue());
    if (slider == &faderDrive)    oscSender.send("/juce/drive", (float)faderDrive.getValue());
    if (slider == &faderCutoff)   oscSender.send("/juce/cutoff", (float)faderCutoff.getValue());
    if (slider == &faderVolume)   oscSender.send("/juce/volume", (float)faderVolume.getValue());
    if (slider == &faderSelector) oscSender.send("/juce/selector", (float)faderSelector.getValue());
}

void MainComponent::oscMessageReceived(const juce::OSCMessage& message)
{
    // Ensure the message actually contains data
    if (message.size() == 0) return;

    // Safely extract the first argument element directly using array indexing
    float receivedVal = message[0].getFloat32();
    juce::String path = message.getAddressPattern().toString();

    isIncomingMessage = true;

    if (path == "/processing/drywet")       faderDryWet.setValue(receivedVal, juce::sendNotificationSync);
    else if (path == "/processing/drive")   faderDrive.setValue(receivedVal, juce::sendNotificationSync);
    else if (path == "/processing/cutoff")  faderCutoff.setValue(receivedVal, juce::sendNotificationSync);
    else if (path == "/processing/volume")  faderVolume.setValue(receivedVal, juce::sendNotificationSync);

    isIncomingMessage = false;
}



void MainComponent::timerCallback()
{
    phase += 0.15f;
    if (phase > juce::MathConstants<float>::twoPi) phase -= juce::MathConstants<float>::twoPi;

    float outSample = 0.0f;
    int selection = (int)faderSelector.getValue();

    if (selection == 0)      outSample = std::sin(phase);
    else if (selection == 1) outSample = (std::sin(phase) >= 0.0f) ? 1.0f : -1.0f;
    else if (selection == 2) outSample = (phase / juce::MathConstants<float>::twoPi) * 2.0f - 1.0f;
    else if (selection == 3) outSample = std::abs((phase / juce::MathConstants<float>::twoPi) * 4.0f - 2.0f) - 1.0f;

    oscSender.send("/juce/waveform", outSample);
}

void MainComponent::paint(juce::Graphics& g) { g.fillAll(juce::Colour::fromRGB(25, 25, 30)); }

void MainComponent::resized()
{
    int w = 100, h = 90, y = 40;
    faderDryWet.setBounds(10, y, w, h); lblDryWet.setBounds(10, 15, w, 20);
    faderDrive.setBounds(120, y, w, h); lblDrive.setBounds(120, 15, w, 20);
    faderCutoff.setBounds(230, y, w, h); lblCutoff.setBounds(230, 15, w, 20);
    faderVolume.setBounds(340, y, w, h); lblVolume.setBounds(340, 15, w, 20);
    faderSelector.setBounds(470, y, 110, h); lblSelector.setBounds(470, 15, 110, 20);
}
