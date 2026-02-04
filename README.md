
---

## 🔁 System Workflow

1. Sender generates telemetry packet.
2. Checksum and parity are calculated.
3. Optional corruption flips a selected bit.
4. Packet is written to TX.DAT.
5. Receiver reads TX.DAT.
6. Receiver recalculates checksum and parity.
7. If valid → ACK written to RX.DAT.
8. If corrupted → NACK written to RX.DAT.
9. Sender reads RX.DAT and displays result.

This simulates a stop-and-wait telemetry protocol.

---

## 🖥️ User Controls (Sender)

| Key | Function |
|-----|----------|
| N | Send packet |
| P | Toggle corruption ON/OFF |
| D | Select data byte |
| B | Select bit position |
| ESC | Exit |

---

## ⚙️ Tools Required

- NASM (Netwide Assembler)
- DOSBox
- Linux / Windows with DOSBox installed

---

## ▶️ How to Run

### 1️⃣ Assemble Programs

Inside your project directory:

```bash
nasm -f bin sender.asm -o sender.com
nasm -f bin receiver.asm -o receiver.com

---

## 🔁 System Workflow

1. Sender generates telemetry packet.
2. Checksum and parity are calculated.
3. Optional corruption flips a selected bit.
4. Packet is written to TX.DAT.
5. Receiver reads TX.DAT.
6. Receiver recalculates checksum and parity.
7. If valid → ACK written to RX.DAT.
8. If corrupted → NACK written to RX.DAT.
9. Sender reads RX.DAT and displays result.

This simulates a stop-and-wait telemetry protocol.

---

## 🖥️ User Controls (Sender)

| Key | Function |
|-----|----------|
| N | Send packet |
| P | Toggle corruption ON/OFF |
| D | Select data byte |
| B | Select bit position |
| ESC | Exit |

---

## ⚙️ Tools Required

- NASM (Netwide Assembler)
- DOSBox
- Linux / Windows with DOSBox installed

---

## ▶️ How to Run

### 1️⃣ Assemble Programs

Inside your project directory:

```bash
nasm -f bin sender.asm -o sender.com
nasm -f bin receiver.asm -o receiver.com
