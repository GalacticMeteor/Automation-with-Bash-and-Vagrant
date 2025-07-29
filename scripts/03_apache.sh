#!/bin/bash
echo "[INFO] Installing Apache web server"
apt-get update
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2

VM_IP=$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1); exit}')

echo "[+] Creating a simple web page..."
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to MyApp</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .info { background: #e7f3ff; padding: 15px; border-left: 4px solid #2196F3; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1> Welcome to MyApp Local Server!</h1>
        <p>Your web server is running successfully!</p>
        <div class="info">
            <strong>Server Info:</strong><br>
            Server IP: $VM_IP<br>
            Domain: myapp.local<br>
            DNS Server: Working
        </div>
        <p>You can access this server at:</p>
        <ul>
            <li><a href="http://www.myapp.local">http://www.myapp.local</a></li>
            <li><a href="http://myapp.local">http://myapp.local</a></li>
            <li><a href="http://$VM_IP">http://$VM_IP</a></li>
        </ul>
    </div>
</body>
</html>
EOF

echo "[+] Restarting Apache2..."
systemctl restart apache2