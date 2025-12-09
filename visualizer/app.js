// SCION Network Visualizer - JavaScript

// AS Information Database
const asInfo = {
    '110': {
        id: '1-ff00:0:110',
        name: 'AS 110 (Core)',
        isd: 'ISD 1 - Academic Network',
        ip: '172.20.0.10',
        type: 'Core AS',
        container: 'scion-as110',
        services: ['Control Service', 'Border Router', 'SCION Daemon'],
        description: 'Core AS in ISD 1. Provides transit services and maintains core links.'
    },
    '111': {
        id: '1-ff00:0:111',
        name: 'AS 111 (Leaf)',
        isd: 'ISD 1 - Academic Network',
        ip: '172.20.0.20',
        type: 'Leaf AS',
        container: 'scion-as111',
        services: ['Control Service', 'Border Router', 'SCION Daemon', 'End Host'],
        description: 'Leaf AS in ISD 1. Connected to core via parent link, peering with AS211.'
    },
    '210': {
        id: '2-ff00:0:210',
        name: 'AS 210 (Core)',
        isd: 'ISD 2 - Commercial Network',
        ip: '172.20.0.30',
        type: 'Core AS',
        container: 'scion-as210',
        services: ['Control Service', 'Border Router', 'SCION Daemon'],
        description: 'Core AS in ISD 2. Connected to AS110 via core link.'
    },
    '211': {
        id: '2-ff00:0:211',
        name: 'AS 211 (Leaf)',
        isd: 'ISD 2 - Commercial Network',
        ip: '172.20.0.40',
        type: 'Leaf AS',
        container: 'scion-as211',
        services: ['Control Service', 'Border Router', 'SCION Daemon', 'End Host'],
        description: 'Leaf AS in ISD 2. Connected to core via parent link, peering with AS111.'
    }
};

// Educational content
const eduContent = {
    isd: {
        title: '🏢 Isolation Domain (ISD)',
        body: `<p><strong>An ISD is a group of ASes under a common trust domain.</strong></p>
<p>Each ISD has:</p>
<ul>
<li><strong>Core ASes</strong> - Provide connectivity backbone</li>
<li><strong>Trust Root Configuration (TRC)</strong> - Defines trust anchors</li>
<li><strong>Independent governance</strong> - Controls policies within its domain</li>
</ul>
<p>In this network:</p>
<ul>
<li>ISD 1 = Academic Network (AS110, AS111)</li>
<li>ISD 2 = Commercial Network (AS210, AS211)</li>
</ul>`
    },
    as: {
        title: '🔗 Autonomous System (AS)',
        body: `<p><strong>An AS is a network under single administrative control.</strong></p>
<p>SCION AS types:</p>
<ul>
<li><strong>Core AS</strong> - Provides inter-ISD connectivity</li>
<li><strong>Non-Core (Leaf) AS</strong> - End-user networks</li>
</ul>
<p>Each AS runs:</p>
<ul>
<li><strong>Control Service</strong> - Manages paths and certificates</li>
<li><strong>Border Router</strong> - Forwards SCION packets</li>
<li><strong>SCION Daemon</strong> - Local path queries</li>
</ul>`
    },
    path: {
        title: '🛤️ Packet-Carried Forwarding State (PCFS)',
        body: `<p><strong>In SCION, each packet carries its complete path.</strong></p>
<p>Key benefits:</p>
<ul>
<li><strong>No routing tables</strong> - Routers just follow embedded path</li>
<li><strong>Path transparency</strong> - Sender knows exact route</li>
<li><strong>Multi-path</strong> - Can use different paths simultaneously</li>
<li><strong>Fast failover</strong> - Switch paths without waiting for convergence</li>
</ul>
<p>The sender chooses which path to use based on latency, bandwidth, or trust requirements.</p>`
    },
    beacon: {
        title: '📡 Beaconing Process',
        body: `<p><strong>Core ASes originate beacons that propagate through the network.</strong></p>
<p>How it works:</p>
<ol>
<li><strong>Core ASes</strong> create and sign beacons</li>
<li><strong>Non-core ASes</strong> receive, extend, and forward beacons</li>
<li><strong>Control Services</strong> register paths from beacons</li>
<li><strong>SCION Daemon</strong> queries for available paths</li>
</ol>
<p>Beaconing happens continuously, so the network converges within seconds.</p>`
    }
};

// State
let selectedAS = null;
let isLoading = false;

// API Base URL (will be set by server)
const API_BASE = window.location.origin;

// Select AS node
function selectAS(asId) {
    // Remove previous selection
    document.querySelectorAll('.as-node').forEach(node => {
        node.classList.remove('selected');
    });
    
    // Add selection to clicked node
    document.getElementById(`as-${asId}`).classList.add('selected');
    selectedAS = asId;
    
    // Update details panel
    const info = asInfo[asId];
    const detailsEl = document.getElementById('as-details');
    detailsEl.innerHTML = `
        <h3>📍 ${info.name}</h3>
        <div class="as-info">
            <p><strong>SCION Address:</strong> ${info.id}</p>
            <p><strong>IP Address:</strong> ${info.ip}</p>
            <p><strong>ISD:</strong> ${info.isd}</p>
            <p><strong>Type:</strong> ${info.type}</p>
            <p><strong>Container:</strong> ${info.container}</p>
            <p style="margin-top: 10px; color: var(--text-secondary); font-size: 13px;">${info.description}</p>
        </div>
    `;
}

// Console logging
function logToConsole(message, type = 'info') {
    const consoleEl = document.getElementById('console');
    const line = document.createElement('div');
    line.className = `console-line ${type}`;
    line.textContent = `[${new Date().toLocaleTimeString()}] ${message}`;
    consoleEl.appendChild(line);
    consoleEl.scrollTop = consoleEl.scrollHeight;
}

function clearConsole() {
    document.getElementById('console').innerHTML = '';
}

// API call helper
async function apiCall(endpoint) {
    try {
        const response = await fetch(`${API_BASE}${endpoint}`);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        return await response.json();
    } catch (error) {
        console.error('API Error:', error);
        return { error: error.message };
    }
}

// Check container status
async function checkStatus() {
    clearConsole();
    logToConsole('Checking container status...', 'info');
    
    const data = await apiCall('/api/status');
    
    if (data.error) {
        logToConsole(`Error: ${data.error}`, 'error');
        logToConsole('Make sure the server is running: python3 visualizer/server.py', 'error');
        return;
    }
    
    if (data.containers) {
        data.containers.forEach(c => {
            const status = c.status.includes('Up') ? '✅' : '❌';
            logToConsole(`${status} ${c.name}: ${c.status}`);
        });
    } else {
        logToConsole('Container status: ' + JSON.stringify(data));
    }
}

// Show paths
async function showPaths() {
    clearConsole();
    logToConsole('Discovering paths from AS111 to AS211...', 'info');
    
    const data = await apiCall('/api/paths');
    
    if (data.error) {
        logToConsole(`Error: ${data.error}`, 'error');
        return;
    }
    
    const pathDisplay = document.getElementById('path-display');
    const pathList = document.getElementById('path-list');
    
    if (data.paths && data.paths.length > 0) {
        pathDisplay.style.display = 'block';
        pathList.innerHTML = data.paths.map((path, i) => `
            <div class="path-item">
                <strong>Path ${i + 1}</strong> (${path.hops} hops)
                <div class="path-hops">${path.route}</div>
            </div>
        `).join('');
        
        logToConsole(`Found ${data.paths.length} path(s)`);
        highlightPath();
    } else {
        pathDisplay.style.display = 'none';
        logToConsole('No paths found. Network may still be converging.', 'error');
        logToConsole('Wait 30-60 seconds and try again.');
    }
}

// Highlight path on topology
function highlightPath() {
    const links = ['link-110-111', 'link-110-210', 'link-210-211'];
    links.forEach(id => {
        const el = document.getElementById(id);
        if (el) {
            el.classList.add('path-highlight');
            setTimeout(() => el.classList.remove('path-highlight'), 3000);
        }
    });
}

// Run ping test
async function runPing() {
    clearConsole();
    logToConsole('Running SCION ping from AS111 to AS110...', 'info');
    
    const data = await apiCall('/api/ping');
    
    if (data.error) {
        logToConsole(`Error: ${data.error}`, 'error');
        return;
    }
    
    if (data.output) {
        data.output.split('\n').forEach(line => {
            if (line.trim()) {
                logToConsole(line);
            }
        });
    }
    
    if (data.success) {
        logToConsole('✅ Ping successful!');
    } else {
        logToConsole('❌ Ping failed. Check network status.', 'error');
    }
}

// Refresh logs
async function refreshLogs() {
    clearConsole();
    logToConsole('Fetching recent logs...', 'info');
    
    const data = await apiCall('/api/logs');
    
    if (data.error) {
        logToConsole(`Error: ${data.error}`, 'error');
        return;
    }
    
    if (data.logs) {
        data.logs.forEach(line => {
            logToConsole(line);
        });
    }
}

// Show educational modal
function showEdu(topic) {
    const content = eduContent[topic];
    if (!content) return;
    
    document.getElementById('modal-title').textContent = content.title;
    document.getElementById('modal-body').innerHTML = content.body;
    document.getElementById('edu-modal').classList.add('active');
}

// Close modal
function closeModal() {
    document.getElementById('edu-modal').classList.remove('active');
}

// Close modal on outside click
document.getElementById('edu-modal')?.addEventListener('click', (e) => {
    if (e.target.id === 'edu-modal') {
        closeModal();
    }
});

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeModal();
    }
});

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    logToConsole('SCION Visualizer ready.');
    logToConsole('Click on AS nodes or use action buttons to explore.');
    
    // Check if server is running
    fetch(`${API_BASE}/api/health`)
        .then(r => r.json())
        .then(data => {
            if (data.status === 'ok') {
                logToConsole('✅ Server connected.', 'info');
            }
        })
        .catch(() => {
            logToConsole('⚠️ Backend server not running.', 'error');
            logToConsole('Start it with: python3 visualizer/server.py', 'error');
        });
});
