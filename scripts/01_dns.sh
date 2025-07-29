#!/bin/bash

set -e

echo "[+] Installing bind9 and DNS tools..."
apt-get install -y bind9 bind9utils dnsutils

echo "[+] Creating DNS zone directory..."
mkdir -p /etc/bind/zones

# Get the VM's IP address (bridged network interface)
VM_IP=$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1); exit}')
echo "[+] Detected VM IP address: $VM_IP"

echo "[+] Defining zone file for myapp.local..."
cat <<EOF > /etc/bind/zones/db.myapp.local
\$TTL    604800
@       IN      SOA     ns.myapp.local. admin.myapp.local. (
                        2         ; Serial
                        604800    ; Refresh
                        86400     ; Retry
                        2419200   ; Expire
                        604800 )  ; Negative Cache TTL
;
@       IN      NS      ns.myapp.local.
ns      IN      A       127.0.0.1
www     IN      A       $VM_IP
myapp.local.    IN      A       $VM_IP
EOF

echo "[+] Updating named.conf.local with zone config..."
cat <<EOF >> /etc/bind/named.conf.local

zone "myapp.local" {
    type master;
    file "/etc/bind/zones/db.myapp.local";
    allow-query { any; };
};
EOF

echo "[+] Configuring BIND9 to accept external queries..."
# Allow queries from any source
sed -i 's/listen-on-v6 { any; };/listen-on-v6 { any; };\n\tlisten-on { any; };/' /etc/bind/named.conf.options

# Add forwarders for external DNS resolution
sed -i '/\/\/ forwarders {/,/\/\/ };/c\
\tforwarders {\
\t\t8.8.8.8;\
\t\t8.8.4.4;\
\t};' /etc/bind/named.conf.options

echo "[+] Checking bind configuration syntax..."
named-checkconf
named-checkzone myapp.local /etc/bind/zones/db.myapp.local

echo "[+] Restarting bind9..."
systemctl restart named
systemctl enable named

echo "[+] Configuring DNS resolution..."
# Check if systemd-resolved is available
if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
    echo "[+] Configuring systemd-resolved to use 127.0.0.1 as DNS..."
    sed -i 's/^#DNS=/DNS=127.0.0.1/' /etc/systemd/resolved.conf
    sed -i 's/^#FallbackDNS=.*/FallbackDNS=8.8.8.8/' /etc/systemd/resolved.conf
    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    systemctl restart systemd-resolved
else
    echo "[+] systemd-resolved not available, configuring /etc/resolv.conf directly..."
    # Backup original resolv.conf
    cp /etc/resolv.conf /etc/resolv.conf.backup
    
    # Create new resolv.conf with local DNS first
    cat <<EOF > /etc/resolv.conf
nameserver 127.0.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
search myapp.local
EOF
fi

echo "Testing BIND9..."
systemctl status bind9 --no-pager -l

echo "Testing DNS resolution..."
dig @127.0.0.1 www.myapp.local +short

echo ""
echo " Setup completed successfully!"
echo "==========================================="
echo "VM IP Address: $VM_IP"
echo "Web Server: http://$VM_IP"
echo "Local Domain: http://www.myapp.local"
echo "DNS Server: 127.0.0.1"
echo "==========================================="
echo ""
echo "To access from your host machine:"
echo "1. Configure your host DNS to use $VM_IP"
echo "2. Or add to your host's /etc/hosts file:"
echo "   $VM_IP www.myapp.local myapp.local"