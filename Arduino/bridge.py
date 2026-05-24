import serial
from pythonosc.udp_client import SimpleUDPClient

# --- configurazione (modifica solo queste se serve) ---
PORT = "COM4"          # <-- metti qui la TUA porta (quella vista nell'IDE)
BAUD = 115200          # deve combaciare con Serial.begin() su Arduino

SC_IP   = "127.0.0.1"  # localhost: SuperCollider sullo stesso PC
SC_PORT = 57120        # porta standard di SuperCollider

# --- setup ---
arduino = serial.Serial(PORT, BAUD)
osc = SimpleUDPClient(SC_IP, SC_PORT)
print("Bridge avviato. Leggo da", PORT)

# --- loop infinito ---
while True:
    line = arduino.readline().decode().strip()   # legge "512,498,1,410,395,602"
    if not line:
        continue
    try:
        parts = line.split(",")
        jx = int(parts[0])    # joystick X
        jy = int(parts[1])    # joystick Y
        sw = int(parts[2])    # pulsante
        ax = int(parts[3])    # accelerometro X
        ay = int(parts[4])    # accelerometro Y
        az = int(parts[5])    # accelerometro Z
    except (ValueError, IndexError):
        continue   # riga incompleta o sporca: la salto

    # invio i valori a SuperCollider
    osc.send_message("/joystick", [jx, jy, sw])   # tre valori in un solo messaggio
    osc.send_message("/accel",    [ax, ay, az])   # tre valori in un solo messaggio

    print(jx, jy, sw, "|", ax, ay, az)   # debug: vediamo cosa arriva