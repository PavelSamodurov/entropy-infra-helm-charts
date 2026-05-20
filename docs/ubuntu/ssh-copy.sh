read -p "Enter SSH username: " USER
read -p "Enter server IP/hostname: " HOST

echo "[*] Copying SSH key to the server..."
cat ~/.ssh/id_ed25519.pub | ssh $USER@$HOST "mkdir -p ~/.ssh && \
    chmod 700 ~/.ssh && \
    touch ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys && \
    grep -qxF \"$(cat ~/.ssh/id_ed25519.pub)\" ~/.ssh/authorized_keys || \
    echo \"$(cat ~/.ssh/id_ed25519.pub)\" >> ~/.ssh/authorized_keys"

echo "[*] Disabling password authentication on the server..."
ssh $USER@$HOST "sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
                 sudo sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config && \
                 sudo sed -i 's/^#*UsePAM.*/UsePAM no/' /etc/ssh/sshd_config && \
                 sudo systemctl restart ssh"

echo "=========================================="
echo "   DONE! Password login is now disabled"
echo "=========================================="

echo "[*] Testing SSH login with key:"
ssh $USER@$HOST