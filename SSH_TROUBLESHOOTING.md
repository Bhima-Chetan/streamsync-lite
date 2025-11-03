# 🔧 SSH Connection Troubleshooting Guide

## Error: "Failed to connect to your instance"

This error typically occurs when trying to SSH into an EC2 instance. Here are the solutions:

---

## Quick Fixes (Try These First)

### 1. **Check Instance Status**

```powershell
# Check if instance is running
aws ec2 describe-instances --instance-ids i-xxxxxxxxx --query "Reservations[0].Instances[0].State.Name"

# Should return: "running"
# If "stopped" or "stopping", start it:
aws ec2 start-instances --instance-ids i-xxxxxxxxx

# Wait for instance to be ready (2-3 minutes)
aws ec2 wait instance-running --instance-ids i-xxxxxxxxx
```

### 2. **Get Correct Public IP Address**

The IP might have changed if you stopped/started the instance.

```powershell
# Get current public IP
aws ec2 describe-instances --instance-ids i-xxxxxxxxx --query "Reservations[0].Instances[0].PublicIpAddress" --output text

# Try SSH with new IP
ssh -i your-key.pem ec2-user@NEW-IP-ADDRESS
```

### 3. **Fix Key File Permissions (Windows)**

Windows permissions might prevent SSH from using the key.

```powershell
# Option A: Using icacls (Windows command)
icacls "C:\path\to\your-key.pem" /inheritance:r
icacls "C:\path\to\your-key.pem" /grant:r "%USERNAME%:R"

# Option B: Right-click key file → Properties → Security
# Remove all users except yourself, give yourself Read permission
```

### 4. **Test Connection with Verbose Mode**

```powershell
# This shows detailed error messages
ssh -vvv -i your-key.pem ec2-user@YOUR-EC2-IP
```

---

## Common Issues & Solutions

### Issue 1: "Connection timed out"

**Cause:** Security group doesn't allow SSH (port 22)

**Solution:**
```powershell
# Get your current IP
$MyIP = (Invoke-WebRequest -Uri "https://api.ipify.org").Content

# Add SSH rule to security group
aws ec2 authorize-security-group-ingress `
  --group-id sg-xxxxxxxxx `
  --protocol tcp `
  --port 22 `
  --cidr "$MyIP/32"

# Or allow from anywhere (less secure)
aws ec2 authorize-security-group-ingress `
  --group-id sg-xxxxxxxxx `
  --protocol tcp `
  --port 22 `
  --cidr 0.0.0.0/0
```

### Issue 2: "Permission denied (publickey)"

**Cause:** Wrong key file or permissions

**Solutions:**

1. **Verify correct key file:**
   ```powershell
   # List your key pairs in AWS
   aws ec2 describe-key-pairs --query "KeyPairs[*].[KeyName,KeyPairId]" --output table
   
   # Make sure you're using the right .pem file
   ```

2. **Fix permissions (Windows):**
   ```powershell
   # Remove inheritance
   icacls "your-key.pem" /inheritance:r
   
   # Grant read access to current user only
   icacls "your-key.pem" /grant:r "$env:USERNAME`:R"
   
   # Verify permissions
   icacls "your-key.pem"
   ```

3. **Use different SSH client:**
   ```powershell
   # Try PuTTY (convert .pem to .ppk first)
   # Or use Windows OpenSSH:
   ssh -i your-key.pem ec2-user@YOUR-EC2-IP
   ```

### Issue 3: "Host key verification failed"

**Cause:** Host key changed (IP reassigned)

**Solution:**
```powershell
# Remove old host key
ssh-keygen -R YOUR-EC2-IP

# Try connecting again
ssh -i your-key.pem ec2-user@YOUR-EC2-IP
```

### Issue 4: "No route to host"

**Cause:** Instance doesn't have public IP or VPC issues

**Solution:**
```powershell
# Check if instance has public IP
aws ec2 describe-instances --instance-ids i-xxxxxxxxx --query "Reservations[0].Instances[0].[PublicIpAddress,PublicDnsName]"

# If no public IP, allocate Elastic IP
aws ec2 allocate-address --domain vpc

# Associate it with instance
aws ec2 associate-address --instance-id i-xxxxxxxxx --allocation-id eipalloc-xxxxxxxxx
```

---

## Using AWS Session Manager (Alternative to SSH)

If SSH continues to fail, use AWS Systems Manager Session Manager:

### 1. **Install Session Manager Plugin**

```powershell
# Download from: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# For Windows, download the MSI installer
```

### 2. **Attach SSM Policy to EC2 Role**

```powershell
aws iam attach-role-policy `
  --role-name StreamSyncEC2Role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

### 3. **Connect Without SSH**

```powershell
# Start session (no SSH key needed!)
aws ssm start-session --target i-xxxxxxxxx

# Once connected, you can run commands
```

---

## Step-by-Step Connection Guide

### Step 1: Verify Prerequisites

```powershell
# 1. Instance is running
aws ec2 describe-instances --instance-ids i-xxxxxxxxx --query "Reservations[0].Instances[0].State.Name"

# 2. Get public IP
$EC2_IP = aws ec2 describe-instances --instance-ids i-xxxxxxxxx --query "Reservations[0].Instances[0].PublicIpAddress" --output text
Write-Host "EC2 Public IP: $EC2_IP"

# 3. Get security group ID
$SG_ID = aws ec2 describe-instances --instance-ids i-xxxxxxxxx --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" --output text
Write-Host "Security Group: $SG_ID"

# 4. Check SSH rule exists
aws ec2 describe-security-groups --group-ids $SG_ID --query "SecurityGroups[0].IpPermissions[?FromPort==``22``]"
```

### Step 2: Test Network Connectivity

```powershell
# Ping test (ICMP might be blocked, but worth trying)
Test-Connection -ComputerName $EC2_IP -Count 4

# Test port 22 connectivity
Test-NetConnection -ComputerName $EC2_IP -Port 22
```

### Step 3: Fix Permissions and Connect

```powershell
# Fix key permissions
icacls "your-key.pem" /inheritance:r
icacls "your-key.pem" /grant:r "$env:USERNAME`:R"

# Try connecting with verbose output
ssh -vvv -i your-key.pem ec2-user@$EC2_IP
```

---

## Using EC2 Instance Connect (Browser-Based)

No SSH client needed!

### Via AWS Console:
1. Go to **EC2 Console** → **Instances**
2. Select your instance
3. Click **Connect** button (top right)
4. Choose **EC2 Instance Connect** tab
5. Click **Connect**

### Via AWS CLI:
```powershell
# Send your public key and connect
aws ec2-instance-connect send-ssh-public-key `
  --instance-id i-xxxxxxxxx `
  --availability-zone us-east-1a `
  --instance-os-user ec2-user `
  --ssh-public-key file://~/.ssh/id_rsa.pub
```

---

## PowerShell Alternative Deployment

If you can't SSH but need to deploy, use AWS Systems Manager Run Command:

```powershell
# 1. Ensure SSM agent is running (pre-installed on Amazon Linux 2023)

# 2. Run deployment commands remotely
aws ssm send-command `
  --document-name "AWS-RunShellScript" `
  --instance-ids "i-xxxxxxxxx" `
  --parameters 'commands=[
    "cd /home/ec2-user",
    "git clone https://github.com/Bhima-Chetan/streamsync-lite.git || (cd streamsync-lite && git pull)",
    "cd streamsync-lite/backend",
    "npm ci --only=production",
    "npm run build",
    "pm2 restart streamsync-api || pm2 start dist/main.js --name streamsync-api"
  ]'

# 3. Get command ID from output, then check status
aws ssm get-command-invocation `
  --command-id "command-id-here" `
  --instance-id "i-xxxxxxxxx"
```

---

## Debugging Checklist

- [ ] Instance is in "running" state
- [ ] Instance has a public IP address
- [ ] Security group allows SSH (port 22) from your IP
- [ ] Using correct key pair (.pem file)
- [ ] Key file has correct permissions (read-only for current user)
- [ ] Correct username (`ec2-user` for Amazon Linux)
- [ ] No typos in IP address
- [ ] Your local firewall allows outbound SSH
- [ ] VPC has Internet Gateway attached
- [ ] Subnet has route to Internet Gateway (0.0.0.0/0)
- [ ] Network ACLs allow SSH traffic

---

## Get Help from AWS

```powershell
# Check AWS service health
curl https://status.aws.amazon.com/

# View CloudWatch logs for instance (if configured)
aws logs tail /aws/ec2/i-xxxxxxxxx --follow

# Check instance system logs
aws ec2 get-console-output --instance-id i-xxxxxxxxx
```

---

## Alternative: Use AWS CloudShell

AWS CloudShell is a browser-based shell with AWS CLI pre-installed:

1. **Open CloudShell** in AWS Console (icon in top nav bar)
2. **Upload your .pem key**:
   ```bash
   # Click Actions → Upload file
   # Select your .pem file
   
   chmod 400 your-key.pem
   ```
3. **Connect to EC2**:
   ```bash
   ssh -i your-key.pem ec2-user@YOUR-EC2-IP
   ```

---

## Still Not Working?

### Contact Information
- Replace `i-xxxxxxxxx` with your actual Instance ID
- Replace `sg-xxxxxxxxx` with your actual Security Group ID
- Replace `YOUR-EC2-IP` with your actual public IP

### Last Resort: Create New Instance
If nothing works, create a new EC2 instance:

```powershell
# Terminate old instance
aws ec2 terminate-instances --instance-ids i-old-instance

# Launch new one (see QUICK_DEPLOY.md Step 1)
# Use a NEW key pair
```

---

**Quick Command Reference:**

```powershell
# Get instance info
aws ec2 describe-instances --instance-ids i-xxxxx

# Start instance
aws ec2 start-instances --instance-ids i-xxxxx

# Fix key permissions
icacls "key.pem" /inheritance:r
icacls "key.pem" /grant:r "$env:USERNAME`:R"

# Connect
ssh -i key.pem ec2-user@IP-ADDRESS

# Use Session Manager instead
aws ssm start-session --target i-xxxxx
```
