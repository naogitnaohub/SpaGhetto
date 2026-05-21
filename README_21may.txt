Hi Raga (:

if you need

*** Testing transfering data from JUCE to Processing:

- sendReceive/sendReceive.pde is the Processing interface sketch, you can find all the OSC messages it sends and receives. This is the one to use for testing communication with your JUCE app.

- source/Main.cpp is a test app on JUCE that generates 4 waveforms, let change the waveform index, and sends audio array, OSC messages for changing dry/wet, drive, volume and cutoff parameters. There is also a mini Gui for checking the bidirectionality of the communication, the controls can be changed from JUCE and from SUPERCOLLIDER.
You can check the messages and try to send similar from your plugin, if possible :)


*** checking the GUI in process:

- 03_GUI/main.pde : the one to run. If you ckeck the last commit message for the folder 03_GUI, there is explanation of all modules (:
There is nothing related to communication protocol with this sketch, you can just open it on Processing, try it and tell me everything you would change. But it is not possible to make it communicate with JUCE yet, use sendReceive.pde instead