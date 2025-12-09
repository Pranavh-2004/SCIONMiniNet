#!/bin/bash
# generate-pki.sh - Generate SCION PKI for the local topology
# Run this inside a SCION container with scion-pki available

set -e

PKI_DIR="/tmp/pki"
rm -rf "$PKI_DIR"
mkdir -p "$PKI_DIR"/{ISD1,ISD2}
cd "$PKI_DIR"

echo "🔐 Generating SCION PKI..."

# ============================================
# ISD 1 PKI Generation
# ============================================
echo "📝 Creating ISD 1 PKI..."

mkdir -p ISD1/AS110

# Generate all private keys first
scion-pki key private ISD1/AS110/cp-root.key
scion-pki key private ISD1/AS110/cp-voting.key  
scion-pki key private ISD1/AS110/cp-regular.key
scion-pki key private ISD1/AS110/as-signing.key
scion-pki key symmetric ISD1/AS110/master0.key
scion-pki key symmetric ISD1/AS110/master1.key

# Create certificate templates (JSON format)
cat > ISD1/AS110/cp-root.json << 'EOF'
{
  "isd_as": "1-ff00:0:110",
  "common_name": "1-ff00:0:110 Root Certificate"
}
EOF

cat > ISD1/AS110/cp-voting.json << 'EOF'
{
  "isd_as": "1-ff00:0:110",
  "common_name": "1-ff00:0:110 Sensitive Voting Certificate"
}
EOF

cat > ISD1/AS110/cp-regular.json << 'EOF'
{
  "isd_as": "1-ff00:0:110",
  "common_name": "1-ff00:0:110 Regular Voting Certificate"
}
EOF

echo "  Generating ISD1 certificates..."

# Root certificate (self-signed)
scion-pki certificate create --force --profile=cp-root \
    --not-before=2024-01-01T00:00:00Z --not-after=2026-01-01T00:00:00Z \
    --key ISD1/AS110/cp-root.key \
    ISD1/AS110/cp-root.json ISD1/AS110/cp-root.crt ISD1/AS110/cp-root.key

# Sensitive voting certificate (self-signed with its own key)
scion-pki certificate create --force --profile=sensitive-voting \
    --not-before=2024-01-01T00:00:00Z --not-after=2026-01-01T00:00:00Z \
    --key ISD1/AS110/cp-voting.key \
    ISD1/AS110/cp-voting.json ISD1/AS110/cp-voting.crt ISD1/AS110/cp-voting.key

# Regular voting certificate (self-signed with its own key)  
scion-pki certificate create --force --profile=regular-voting \
    --not-before=2024-01-01T00:00:00Z --not-after=2026-01-01T00:00:00Z \
    --key ISD1/AS110/cp-regular.key \
    ISD1/AS110/cp-regular.json ISD1/AS110/cp-regular.crt ISD1/AS110/cp-regular.key

# Create TRC template for ISD 1
# 1704067200 = 2024-01-01T00:00:00Z as Unix timestamp
cat > ISD1/trc-template.toml << 'EOF'
isd = 1
description = "ISD 1 - Academic Network"
serial_version = 1
base_version = 1
voting_quorum = 1

core_ases = ["ff00:0:110"]
authoritative_ases = ["ff00:0:110"]
cert_files = ["AS110/cp-root.crt", "AS110/cp-voting.crt", "AS110/cp-regular.crt"]

no_trust_reset = false

[validity]
not_before = 1704067200
validity = "730d"
EOF

echo "  Generating ISD1 TRC..."
scion-pki trc payload --template ISD1/trc-template.toml --out ISD1/trc-payload.der
scion-pki trc sign ISD1/trc-payload.der ISD1/AS110/cp-voting.crt ISD1/AS110/cp-voting.key \
    --out ISD1/ISD1-B1-S1.trc

# Generate CA certificate for issuing AS certs
cat > ISD1/AS110/cp-ca.json << 'EOF'
{
  "isd_as": "1-ff00:0:110",
  "common_name": "1-ff00:0:110 CA Certificate"
}
EOF

scion-pki key private ISD1/AS110/cp-ca.key
scion-pki certificate create --force --profile=cp-ca \
    --ca ISD1/AS110/cp-root.crt --ca-key ISD1/AS110/cp-root.key \
    --not-before=2024-01-01T00:00:00Z --not-after=2026-01-01T00:00:00Z \
    --key ISD1/AS110/cp-ca.key \
    ISD1/AS110/cp-ca.json ISD1/AS110/cp-ca.crt ISD1/AS110/cp-ca.key

# Generate PKI for AS 111 (non-core)
echo "  Generating AS111 certificates..."
mkdir -p ISD1/AS111
scion-pki key private ISD1/AS111/cp-as.key
scion-pki key symmetric ISD1/AS111/master0.key
scion-pki key symmetric ISD1/AS111/master1.key

cat > ISD1/AS111/cp-as.json << 'EOF'
{
  "isd_as": "1-ff00:0:111",
  "common_name": "1-ff00:0:111 AS Certificate"
}
EOF

scion-pki certificate create --force --profile=cp-as --bundle \
    --ca ISD1/AS110/cp-ca.crt --ca-key ISD1/AS110/cp-ca.key \
    --not-before=2024-01-01T00:00:00Z --not-after=2025-01-01T00:00:00Z \
    --key ISD1/AS111/cp-as.key \
    ISD1/AS111/cp-as.json ISD1/AS111/cp-as.pem ISD1/AS111/cp-as.key

# ============================================
# ISD 2 PKI Generation
# ============================================
echo "📝 Creating ISD 2 PKI..."

mkdir -p ISD2/AS210
scion-pki key private ISD2/AS210/cp-root.key
scion-pki key private ISD2/AS210/cp-voting.key
scion-pki key private ISD2/AS210/cp-regular.key
scion-pki key private ISD2/AS210/as-signing.key
scion-pki key symmetric ISD2/AS210/master0.key
scion-pki key symmetric ISD2/AS210/master1.key

cat > ISD2/AS210/cp-root.json << 'EOF'
{
  "isd_as": "2-ff00:0:210",
  "common_name": "2-ff00:0:210 Root Certificate"
}
EOF

cat > ISD2/AS210/cp-voting.json << 'EOF'  
{
  "isd_as": "2-ff00:0:210",
  "common_name": "2-ff00:0:210 Sensitive Voting Certificate"
}
EOF

cat > ISD2/AS210/cp-regular.json << 'EOF'
{
  "isd_as": "2-ff00:0:210",
  "common_name": "2-ff00:0:210 Regular Voting Certificate"
}
EOF

echo "  Generating ISD2 certificates..."
scion-pki certificate create --force --profile=cp-root \
    --not-before=2024-01-01T00:00:00Z --not-after=2026-01-01T00:00:00Z \
    --key ISD2/AS210/cp-root.key \
    ISD2/AS210/cp-root.json ISD2/AS210/cp-root.crt ISD2/AS210/cp-root.key

scion-pki certificate create --force --profile=sensitive-voting \
    --not-before=2024-01-01T00:00:00Z --not-after=2026-01-01T00:00:00Z \
    --key ISD2/AS210/cp-voting.key \
    ISD2/AS210/cp-voting.json ISD2/AS210/cp-voting.crt ISD2/AS210/cp-voting.key

scion-pki certificate create --force --profile=regular-voting \
    --not-before=2024-01-01T00:00:00Z --not-after=2026-01-01T00:00:00Z \
    --key ISD2/AS210/cp-regular.key \
    ISD2/AS210/cp-regular.json ISD2/AS210/cp-regular.crt ISD2/AS210/cp-regular.key

cat > ISD2/trc-template.toml << 'EOF'
isd = 2
description = "ISD 2 - Commercial Network"
serial_version = 1
base_version = 1
voting_quorum = 1

core_ases = ["ff00:0:210"]
authoritative_ases = ["ff00:0:210"]
cert_files = ["AS210/cp-root.crt", "AS210/cp-voting.crt", "AS210/cp-regular.crt"]

no_trust_reset = false

[validity]
not_before = 1704067200
validity = "730d"
EOF

echo "  Generating ISD2 TRC..."
scion-pki trc payload --template ISD2/trc-template.toml --out ISD2/trc-payload.der
scion-pki trc sign ISD2/trc-payload.der ISD2/AS210/cp-voting.crt ISD2/AS210/cp-voting.key \
    --out ISD2/ISD2-B1-S1.trc

# Generate CA certificate for ISD2
cat > ISD2/AS210/cp-ca.json << 'EOF'
{
  "isd_as": "2-ff00:0:210",
  "common_name": "2-ff00:0:210 CA Certificate"
}
EOF

scion-pki key private ISD2/AS210/cp-ca.key
scion-pki certificate create --force --profile=cp-ca \
    --ca ISD2/AS210/cp-root.crt --ca-key ISD2/AS210/cp-root.key \
    --not-before=2024-01-01T00:00:00Z --not-after=2026-01-01T00:00:00Z \
    --key ISD2/AS210/cp-ca.key \
    ISD2/AS210/cp-ca.json ISD2/AS210/cp-ca.crt ISD2/AS210/cp-ca.key

# Generate PKI for AS 211
echo "  Generating AS211 certificates..."
mkdir -p ISD2/AS211
scion-pki key private ISD2/AS211/cp-as.key
scion-pki key symmetric ISD2/AS211/master0.key
scion-pki key symmetric ISD2/AS211/master1.key

cat > ISD2/AS211/cp-as.json << 'EOF'
{
  "isd_as": "2-ff00:0:211",
  "common_name": "2-ff00:0:211 AS Certificate"
}
EOF

scion-pki certificate create --force --profile=cp-as --bundle \
    --ca ISD2/AS210/cp-ca.crt --ca-key ISD2/AS210/cp-ca.key \
    --not-before=2024-01-01T00:00:00Z --not-after=2025-01-01T00:00:00Z \
    --key ISD2/AS211/cp-as.key \
    ISD2/AS211/cp-as.json ISD2/AS211/cp-as.pem ISD2/AS211/cp-as.key

echo ""
echo "✅ PKI generation complete!"
echo ""
echo "Generated TRCs:"
find /tmp/pki -name "*.trc" | sort

echo ""
echo "Generated certificates:"
find /tmp/pki -name "*.crt" -o -name "*.pem" | sort
