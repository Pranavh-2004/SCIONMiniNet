#!/usr/bin/env python3
"""
SCION Visualizer Backend Server

A simple Flask server that executes Docker commands and returns JSON results.
Run with: python3 visualizer/server.py
"""

from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
import subprocess
import os
import re

app = Flask(__name__, static_folder='.', static_url_path='')
CORS(app)

# Project root directory
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def run_command(cmd, cwd=None):
    """Execute a shell command and return output."""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=30,
            cwd=cwd or PROJECT_ROOT
        )
        return {
            'success': result.returncode == 0,
            'output': result.stdout,
            'error': result.stderr if result.returncode != 0 else None
        }
    except subprocess.TimeoutExpired:
        return {'success': False, 'error': 'Command timed out'}
    except Exception as e:
        return {'success': False, 'error': str(e)}


@app.route('/')
def index():
    """Serve the main HTML file."""
    return send_from_directory('.', 'index.html')


@app.route('/api/health')
def health():
    """Health check endpoint."""
    return jsonify({'status': 'ok'})


@app.route('/api/status')
def status():
    """Get container status."""
    result = run_command('docker compose ps --format json')
    
    if not result['success']:
        return jsonify({'error': result.get('error', 'Failed to get status')})
    
    containers = []
    for line in result['output'].strip().split('\n'):
        if line.strip():
            try:
                import json
                data = json.loads(line)
                containers.append({
                    'name': data.get('Name', 'unknown'),
                    'status': data.get('Status', 'unknown'),
                    'state': data.get('State', 'unknown')
                })
            except:
                # Fallback for non-JSON output
                containers.append({'name': line, 'status': 'unknown'})
    
    return jsonify({'containers': containers})


@app.route('/api/paths')
def paths():
    """Get available paths from AS111 to AS211."""
    cmd = 'docker exec scion-as111 scion showpaths 2-ff00:0:211 --sciond 172.20.0.20:30255 2>&1'
    result = run_command(cmd)
    
    if not result['success'] and 'no path found' in result.get('output', '').lower():
        return jsonify({'paths': [], 'message': 'No paths found'})
    
    # Parse paths from output
    paths = []
    output = result.get('output', '')
    
    for line in output.split('\n'):
        # Look for path lines like "[0] Hops: [...]"
        if 'Hops:' in line:
            hops_match = re.search(r'\[(\d+)\].*Hops:\s*\[(.*?)\]', line)
            if hops_match:
                path_num = hops_match.group(1)
                hops_str = hops_match.group(2)
                hop_count = hops_str.count('~~') + 1
                paths.append({
                    'id': int(path_num),
                    'hops': hop_count,
                    'route': hops_str.strip(),
                    'status': 'alive' if 'alive' in line else 'unknown'
                })
    
    return jsonify({'paths': paths})


@app.route('/api/ping')
def ping():
    """Run SCION ping from AS111 to AS110."""
    cmd = 'docker exec scion-as111 scion ping 1-ff00:0:110,172.20.0.10 -c 3 --sciond 172.20.0.20:30255 2>&1'
    result = run_command(cmd)
    
    output = result.get('output', '')
    success = '0% packet loss' in output or 'bytes from' in output
    
    return jsonify({
        'success': success,
        'output': output
    })


@app.route('/api/logs')
def logs():
    """Get recent logs from control service."""
    cmd = 'docker compose logs --tail=20 2>&1 | grep -E "(beacon|path|signer|error)" | head -15'
    result = run_command(cmd)
    
    logs = [line.strip() for line in result.get('output', '').split('\n') if line.strip()]
    
    return jsonify({'logs': logs[-15:]})  # Last 15 lines


@app.route('/api/topology')
def topology():
    """Return network topology info."""
    return jsonify({
        'isds': [
            {'id': 1, 'name': 'Academic Network'},
            {'id': 2, 'name': 'Commercial Network'}
        ],
        'ases': [
            {'id': '1-ff00:0:110', 'isd': 1, 'type': 'core', 'ip': '172.20.0.10'},
            {'id': '1-ff00:0:111', 'isd': 1, 'type': 'leaf', 'ip': '172.20.0.20'},
            {'id': '2-ff00:0:210', 'isd': 2, 'type': 'core', 'ip': '172.20.0.30'},
            {'id': '2-ff00:0:211', 'isd': 2, 'type': 'leaf', 'ip': '172.20.0.40'}
        ],
        'links': [
            {'from': '1-ff00:0:110', 'to': '2-ff00:0:210', 'type': 'CORE'},
            {'from': '1-ff00:0:110', 'to': '1-ff00:0:111', 'type': 'CHILD'},
            {'from': '2-ff00:0:210', 'to': '2-ff00:0:211', 'type': 'CHILD'},
            {'from': '1-ff00:0:111', 'to': '2-ff00:0:211', 'type': 'PEER'}
        ]
    })


if __name__ == '__main__':
    print("🚀 SCION Visualizer Server")
    print("   Open http://localhost:8080 in your browser")
    print("   Press Ctrl+C to stop")
    print()
    app.run(host='0.0.0.0', port=8080, debug=True)
