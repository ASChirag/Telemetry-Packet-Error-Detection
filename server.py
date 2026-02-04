#!/usr/bin/env python3
"""
Telemetry Monitor Server
Reads TX.DAT and RX.DAT files and serves data to web interface
"""

from flask import Flask, jsonify, render_template, request
from flask_cors import CORS
import os
import time
import struct

app = Flask(__name__)
CORS(app)

# File paths for DAT files
TX_FILE = "TX.DAT"
RX_FILE = "RX.DAT"

def read_tx_data():
    """Read 6 bytes from TX.DAT"""
    try:
        if os.path.exists(TX_FILE):
            with open(TX_FILE, 'rb') as f:
                data = f.read(6)
                if len(data) == 6:
                    return list(data)
        return None
    except Exception as e:
        print(f"Error reading TX.DAT: {e}")
        return None

def read_rx_data():
    """Read 1 byte from RX.DAT"""
    try:
        if os.path.exists(RX_FILE):
            with open(RX_FILE, 'rb') as f:
                data = f.read(1)
                if len(data) == 1:
                    return chr(data[0])
        return None
    except Exception as e:
        print(f"Error reading RX.DAT: {e}")
        return None

def calculate_expected_values(counter):
    """Calculate expected values based on counter (byte 0)"""
    if counter is None:
        return None
    
    data1 = counter ^ 0x55
    data2 = counter ^ 0xAA
    data3 = (counter + 3) & 0xFF
    checksum = data1 ^ data2 ^ data3
    
    # Calculate parity (count 1-bits in data1, data2, data3)
    parity = 0
    for byte in [data1, data2, data3]:
        for bit in range(8):
            if byte & (1 << bit):
                parity += 1
    parity = parity & 1  # Even/odd parity
    
    return [counter, data1, data2, data3, checksum, parity]

@app.route('/')
def index():
    """Serve the main HTML page"""
    return render_template('index.html')

@app.route('/api/data')
def get_data():
    """API endpoint to get current telemetry data"""
    tx_data = read_tx_data()
    rx_response = read_rx_data()
    
    if tx_data is None:
        return jsonify({
            'status': 'error',
            'message': 'Waiting for data...',
            'tx_exists': False,
            'rx_exists': os.path.exists(RX_FILE)
        })
    
    # Calculate expected values
    expected = calculate_expected_values(tx_data[0])
    
    # Prepare sender data
    sender_data = {
        'counter': tx_data[0],
        'data1': tx_data[1],
        'data2': tx_data[2],
        'data3': tx_data[3],
        'checksum': tx_data[4],
        'parity': tx_data[5]
    }
    
    # Prepare receiver data
    receiver_data = {
        'raw': tx_data,
        'expected': expected,
        'checksum_calc': expected[4],
        'parity_calc': expected[5],
        'status': 'VALID' if tx_data == expected else 'CORRUPTED'
    }
    
    return jsonify({
        'status': 'success',
        'sender': sender_data,
        'receiver': receiver_data,
        'rx_response': rx_response if rx_response else 'N/A',
        'timestamp': time.time()
    })

@app.route('/api/status')
def get_status():
    """Check if DAT files exist"""
    return jsonify({
        'tx_exists': os.path.exists(TX_FILE),
        'rx_exists': os.path.exists(RX_FILE)
    })

if __name__ == '__main__':
    print("=" * 60)
    print("TELEMETRY MONITOR SERVER")
    print("=" * 60)
    print(f"Monitoring files:")
    print(f"  TX.DAT: {os.path.abspath(TX_FILE)}")
    print(f"  RX.DAT: {os.path.abspath(RX_FILE)}")
    print()
    print("Server running at: http://localhost:5000")
    print("Press Ctrl+C to stop")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5000, debug=True)
