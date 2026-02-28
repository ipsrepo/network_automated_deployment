#!/bin/bash
# 🚀 One‑click deployment script for WSL (Ubuntu)
# Uses Terraform outputs + Ansible to deploy your web app
# Relies on your existing Elastic IP (52.48.24.168)

set -e  # exit on any error

# ---------- Configuration ----------
PROJECT_ROOT="/mnt/d/DBS/Network/Assessment/network_automated_deployment"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
KEY_PATH="$HOME/.ssh/aws-key"
SSH_USER="ec2-user"
# ------------------------------------

echo "╔════════════════════════════════════════════╗"
echo "║     🚀 WSL DEPLOYMENT SCRIPT              ║"
echo "╚════════════════════════════════════════════╝"

# 1️⃣ Get instance info from Terraform
echo ""
echo "📦 [1/6] Reading Terraform outputs..."
cd "$TERRAFORM_DIR"
INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "")
ELASTIC_IP=$(terraform output -raw elastic_ip 2>/dev/null || echo "52.48.24.168")

if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "null" ]]; then
    echo "⚠️  Could not get instance_id from Terraform. Using hardcoded instance ID? (edit script)"
    # You can optionally set a fallback instance ID here:
    # INSTANCE_ID="i-xxxxxxxxxxxxxxxxx"
    echo "❌ Aborting. Please run terraform apply first or set INSTANCE_ID manually."
    exit 1
fi

echo "   ✅ Instance ID : $INSTANCE_ID"
echo "   🌐 Elastic IP  : $ELASTIC_IP"

# 2️⃣ Check instance state
echo ""
echo "🔎 [2/6] Checking EC2 instance state..."
STATE=$(aws ec2 describe-instances --region eu-west-1 --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].State.Name" --output text)

if [[ "$STATE" == "terminated" ]]; then
    echo "❌ Instance is terminated. Cannot continue."
    exit 1
fi

if [[ "$STATE" == "stopped" ]]; then
    echo "   ⏹️  Instance is STOPPED. Starting it now..."
    aws ec2 start-instances --region eu-west-1 --instance-ids "$INSTANCE_ID" >/dev/null
    echo "   ⏳ Waiting for instance to be running..."
    aws ec2 wait instance-running --region eu-west-1 --instance-ids "$INSTANCE_ID"
    echo "   ✅ Instance is now running."
elif [[ "$STATE" == "running" ]]; then
    echo "   ✅ Instance is already RUNNING."
else
    echo "   ⏳ Instance state: $STATE. Waiting for it to become running..."
    aws ec2 wait instance-running --region eu-west-1 --instance-ids "$INSTANCE_ID"
    echo "   ✅ Instance is now running."
fi

# 3️⃣ Wait for SSH to be ready (sometimes needed even after instance-running)
echo ""
echo "⏳ [3/6] Waiting for SSH to be reachable on $ELASTIC_IP..."
for i in {1..12}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$KEY_PATH" "$SSH_USER@$ELASTIC_IP" "echo ready" 2>/dev/null; then
        echo "   ✅ SSH is ready."
        break
    fi
    echo "   Attempt $i/12 – still waiting..."
    sleep 5
done

# 4️⃣ Run Ansible playbook
echo ""
echo "⚙️ [4/6] Running Ansible playbook..."

# Update inventory file with current IP
cd "$ANSIBLE_DIR"
echo "[web_server]" > inventory.ini
echo "$ELASTIC_IP ansible_user=$SSH_USER ansible_private_key_file=$KEY_PATH" >> inventory.ini
echo "   📝 Inventory updated for $ELASTIC_IP"

# Run Ansible
ansible-playbook -i inventory.ini playbook.yml

if [ $? -ne 0 ]; then
    echo "❌ Ansible playbook failed. Check the output above."
    exit 1
fi

# 5️⃣ Open website in browser (WSL → Windows)
echo ""
echo "🌐 [5/6] Opening website in your browser..."
# Use PowerShell to open the default browser from WSL
powershell.exe Start-Process "http://$ELASTIC_IP"

# 6️⃣ Final status
echo ""
echo "✅ [6/6] Deployment complete!"
echo "   📍 Instance ID : $INSTANCE_ID"
echo "   🌐 Elastic IP  : $ELASTIC_IP"
echo "   🖥️  Website    : http://$ELASTIC_IP"
echo ""
echo "🎉 SUCCESS!"