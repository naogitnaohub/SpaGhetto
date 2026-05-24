import serial
from pythonosc.udp_client import SimpleUDPClient

# --- configurazione (modifica solo queste se serve) ---
PORT = "COM5"          # <-- metti qui la TUA porta (quella vista nell'IDE)
BAUD = 115200          # deve combaciare con Serial.begin() su Arduino

SC_IP   = "127.0.0.1"  # localhost: SuperCollider sullo stesso PC
SC_PORT = 57120        # porta standard di SuperCollider

# --- setup ---
arduino = serial.Serial(PORT, BAUD)
osc = SimpleUDPClient(SC_IP, SC_PORT)
print("Bridge avviato. Leggo da", PORT)
prev_sw = None
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

# i 5 valori di movimento su /sensors, nell'ordine che SC si aspetta:
    # msg[1]=cx, msg[2]=cy, msg[3]=r, msg[4]=a, msg[5]=b
    osc.send_message("/sensors", [jx, jy, ax, ay, az])

    # il pulsante su /btn, solo quando cambia stato
    if sw != prev_sw:
        osc.send_message("/btn", sw)
        prev_sw = sw

    print(jx, jy, sw, "|", ax, ay, az)   # debug