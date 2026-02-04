#!/usr/bin/env python3
"""
Test Data Generator
Creates sample TX.DAT and RX.DAT files for testing the web interface
without needing to run the assembly programs
"""

import struct
import random

def generate_test_packet(counter):
    """Generate a valid packet based on counter value"""
    data1 = counter ^ 0x55
    data2 = counter ^ 0xAA
    data3 = (counter + 3) & 0xFF
    checksum = data1 ^ data2 ^ data3
    
    # Calculate parity
    parity = 0
    for byte in [data1, data2, data3]:
        for bit in range(8):
            if byte & (1 << bit):
                parity += 1
    parity = parity & 1
    
    return [counter, data1, data2, data3, checksum, parity]

def write_tx_file(packet):
    """Write packet to TX.DAT"""
    with open('TX.DAT', 'wb') as f:
        f.write(bytes(packet))
    print(f"✓ TX.DAT written: {' '.join(f'{b:02X}' for b in packet)}")

def write_rx_file(response):
    """Write response to RX.DAT"""
    with open('RX.DAT', 'wb') as f:
        f.write(bytes([ord(response)]))
    print(f"✓ RX.DAT written: {response}")

def main():
    print("=" * 60)
    print("TEST DATA GENERATOR FOR TELEMETRY MONITOR")
    print("=" * 60)
    print()
    
    mode = input("Select mode:\n  [1] Generate valid packet\n  [2] Generate corrupted packet\n  [3] Auto-increment mode (press Ctrl+C to stop)\n\nChoice: ").strip()
    
    if mode == '1':
        # Generate valid packet
        counter = random.randint(0, 255)
        packet = generate_test_packet(counter)
        write_tx_file(packet)
        write_rx_file('A')  # ACK
        print("\n✓ Valid packet generated!")
        
    elif mode == '2':
        # Generate corrupted packet
        counter = random.randint(0, 255)
        packet = generate_test_packet(counter)
        
        # Corrupt a random byte
        corrupt_index = random.randint(1, 3)  # Corrupt one of the data bytes
        corrupt_bit = random.randint(0, 7)
        packet[corrupt_index] ^= (1 << corrupt_bit)
        
        write_tx_file(packet)
        write_rx_file('N')  # NACK
        print(f"\n✓ Corrupted packet generated! (bit {corrupt_bit} flipped in byte {corrupt_index})")
        
    elif mode == '3':
        # Auto-increment mode
        import time
        counter = 0
        print("\n▶ Auto-increment mode started. Press Ctrl+C to stop.\n")
        
        try:
            while True:
                counter = (counter + 1) & 0xFF
                packet = generate_test_packet(counter)
                
                # Randomly corrupt some packets (10% chance)
                if random.random() < 0.1:
                    corrupt_index = random.randint(1, 3)
                    corrupt_bit = random.randint(0, 7)
                    packet[corrupt_index] ^= (1 << corrupt_bit)
                    response = 'N'
                    status = "CORRUPTED"
                else:
                    response = 'A'
                    status = "VALID"
                
                write_tx_file(packet)
                write_rx_file(response)
                print(f"Counter: {counter:02X} | Status: {status}")
                
                time.sleep(1)  # Wait 1 second between packets
                
        except KeyboardInterrupt:
            print("\n\n✓ Auto-increment mode stopped.")
    
    else:
        print("Invalid choice!")
        return
    
    print("\n" + "=" * 60)
    print("Now start server.py and open http://localhost:5000")
    print("=" * 60)

if __name__ == '__main__':
    main()
