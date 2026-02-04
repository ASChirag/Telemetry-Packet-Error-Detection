// Global state
let autoRefreshInterval = null;
let isAutoRefresh = false;

// Format byte as hex
function toHex(value) {
    if (value === null || value === undefined) return '--';
    return value.toString(16).toUpperCase().padStart(2, '0');
}

// Update last update time
function updateTimestamp() {
    const now = new Date();
    const timeStr = now.toLocaleTimeString();
    document.getElementById('lastUpdate').textContent = timeStr;
}

// Update connection status
function setConnectionStatus(connected, message = '') {
    const statusEl = document.getElementById('connectionStatus');
    if (connected) {
        statusEl.classList.add('connected');
        statusEl.innerHTML = '<span class="status-dot"></span> Connected' + (message ? ` - ${message}` : '');
    } else {
        statusEl.classList.remove('connected');
        statusEl.innerHTML = '<span class="status-dot"></span> ' + (message || 'Disconnected');
    }
}

// Update sender panel
function updateSenderPanel(data) {
    document.getElementById('sender-counter').textContent = toHex(data.counter);
    document.getElementById('sender-data1').textContent = toHex(data.data1);
    document.getElementById('sender-data2').textContent = toHex(data.data2);
    document.getElementById('sender-data3').textContent = toHex(data.data3);
    document.getElementById('sender-checksum').textContent = toHex(data.checksum);
    document.getElementById('sender-parity').textContent = toHex(data.parity);
}

// Update receiver panel
function updateReceiverPanel(data) {
    // Update data rows
    for (let i = 0; i < 6; i++) {
        const rowEl = document.getElementById(`rx-row-${i}`);
        const raw = data.raw[i];
        const expected = data.expected[i];
        
        const rawHex = toHex(raw);
        const expectedHex = toHex(expected);
        
        // Update values
        rowEl.querySelector('.col-raw').textContent = rawHex;
        rowEl.querySelector('.col-expected').textContent = expectedHex;
        
        // Highlight mismatches
        if (raw !== expected) {
            rowEl.classList.add('mismatch');
        } else {
            rowEl.classList.remove('mismatch');
        }
    }
    
    // Update calculated values
    document.getElementById('rx-checksum-calc').textContent = toHex(data.checksum_calc);
    document.getElementById('rx-parity-calc').textContent = toHex(data.parity_calc);
    
    // Update status box
    const statusBox = document.getElementById('rxStatus');
    statusBox.textContent = data.status;
    statusBox.classList.remove('valid', 'corrupted', 'waiting');
    
    if (data.status === 'VALID') {
        statusBox.classList.add('valid');
    } else if (data.status === 'CORRUPTED') {
        statusBox.classList.add('corrupted');
    } else {
        statusBox.classList.add('waiting');
    }
}

// Update receiver response
function updateReceiverResponse(response) {
    const responseEl = document.getElementById('sender-response');
    responseEl.classList.remove('ack', 'nack');
    
    if (response === 'A') {
        responseEl.textContent = 'ACK [OK]';
        responseEl.classList.add('ack');
    } else if (response === 'N') {
        responseEl.textContent = 'NACK [ERR]';
        responseEl.classList.add('nack');
    } else {
        responseEl.textContent = response || '--';
    }
}

// Fetch data from server
async function fetchData() {
    try {
        const response = await fetch('/api/data');
        const result = await response.json();
        
        if (result.status === 'success') {
            updateSenderPanel(result.sender);
            updateReceiverPanel(result.receiver);
            updateReceiverResponse(result.rx_response);
            updateTimestamp();
            setConnectionStatus(true, 'Data received');
        } else {
            setConnectionStatus(false, result.message || 'Waiting for data...');
            
            // Update status box
            const statusBox = document.getElementById('rxStatus');
            statusBox.textContent = result.message || 'Waiting for data...';
            statusBox.classList.remove('valid', 'corrupted');
            statusBox.classList.add('waiting');
        }
    } catch (error) {
        console.error('Error fetching data:', error);
        setConnectionStatus(false, 'Connection error');
        
        // Update status box
        const statusBox = document.getElementById('rxStatus');
        statusBox.textContent = 'Error: Failed to fetch';
        statusBox.classList.remove('valid', 'corrupted');
        statusBox.classList.add('waiting');
    }
}

// Toggle auto-refresh
function toggleAutoRefresh() {
    const btn = document.getElementById('autoRefreshBtn');
    
    if (isAutoRefresh) {
        // Stop auto-refresh
        clearInterval(autoRefreshInterval);
        autoRefreshInterval = null;
        isAutoRefresh = false;
        btn.innerHTML = '<span class="btn-icon">▶</span> Start Auto-Refresh';
        btn.classList.remove('active');
    } else {
        // Start auto-refresh
        isAutoRefresh = true;
        btn.innerHTML = '<span class="btn-icon">⏸</span> Stop Auto-Refresh';
        btn.classList.add('active');
        
        // Fetch immediately
        fetchData();
        
        // Set up interval (every 500ms)
        autoRefreshInterval = setInterval(fetchData, 500);
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    console.log('Telemetry Monitor initialized');
    
    // Fetch data once on load
    fetchData();
    
    // Set up keyboard shortcuts
    document.addEventListener('keydown', function(e) {
        // R key - Refresh
        if (e.key === 'r' || e.key === 'R') {
            fetchData();
        }
        // Space - Toggle auto-refresh
        if (e.key === ' ') {
            e.preventDefault();
            toggleAutoRefresh();
        }
    });
});

// Expose functions to global scope for onclick handlers
window.fetchData = fetchData;
window.toggleAutoRefresh = toggleAutoRefresh;
