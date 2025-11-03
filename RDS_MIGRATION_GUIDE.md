# RDS Migration Guide - StreamSync

## Prerequisites
- ✅ Database backup created (`/tmp/streamsync-backup.sql`)
- ✅ Schema exported (`/tmp/streamsync-schema.sql`)
- ✅ IAM role with RDS permissions attached to EC2

## Step 1: Create RDS PostgreSQL Instance (AWS Console)

### Go to RDS Console:
https://console.aws.amazon.com/rds/home?region=us-east-1

### Create Database:
1. Click **"Create database"**

2. **Choose a database creation method:**
   - Select: ✅ **Standard create**

3. **Engine options:**
   - Engine type: **PostgreSQL**
   - Version: **PostgreSQL 15.x** (latest minor version)

4. **Templates:**
   - Select: ✅ **Free tier**

5. **Settings:**
   - DB instance identifier: `streamsync-db`
   - Master username: `postgres`
   - Master password: `[Create a strong password]`
   - Confirm password: `[Same password]`
   
   **Important:** Save this password securely!

6. **DB instance class:**
   - ✅ **db.t3.micro** (Free tier eligible)

7. **Storage:**
   - Storage type: **General Purpose SSD (gp3)**
   - Allocated storage: **20 GiB** (Free tier includes up to 20GB)
   - ⬜ Disable "Enable storage autoscaling" (keep costs predictable)

8. **Connectivity:**
   - Virtual private cloud (VPC): **Default VPC**
   - Subnet group: **default**
   - Public access: ✅ **Yes** (for initial setup; restrict later)
   - VPC security group: 
     - Create new: `streamsync-db-sg`
     - Or select existing and configure rules below

9. **Database authentication:**
   - ✅ **Password authentication**

10. **Additional configuration:**
    - Initial database name: `streamsync`
    - ⬜ Disable "Enable automated backups" (optional, but recommended to keep enabled)
    - Backup retention period: **7 days**
    - ⬜ Disable "Enable Enhanced monitoring" (uses CloudWatch, stay in free tier)

11. Click **"Create database"**

### Wait for Creation:
- Status will change from "Creating" → "Available" (5-10 minutes)

## Step 2: Configure Security Group

### After RDS is created:
1. Go to **EC2 Console** → **Security Groups**
2. Find the security group for RDS: `streamsync-db-sg` (or the one you selected)
3. Click **"Edit inbound rules"**
4. Add rule:
   - Type: **PostgreSQL**
   - Port: **5432**
   - Source: **Custom** → Select the EC2 instance security group (allows only your EC2 to connect)
   - Description: `Allow PostgreSQL from EC2 instance`
5. Save rules

### Get RDS Endpoint:
1. Go back to RDS Console
2. Click on `streamsync-db`
3. Copy the **Endpoint** under "Connectivity & security"
   - Example: `streamsync-db.abc123.us-east-1.rds.amazonaws.com`

## Step 3: Test RDS Connection from EC2

```bash
# SSH into EC2
ssh -i D:\streamsync.pem ec2-user@3.85.120.15

# Test connection (replace with your endpoint and password)
PGPASSWORD='your-rds-password' psql -h streamsync-db.abc123.us-east-1.rds.amazonaws.com -U postgres -d postgres -c "SELECT version();"
```

If successful, you'll see the PostgreSQL version.

## Step 4: Migrate Database to RDS

### Create the streamsync database and extensions:
```bash
# On EC2 instance
PGPASSWORD='your-rds-password' psql -h your-rds-endpoint.rds.amazonaws.com -U postgres -d postgres << 'EOF'
-- Create database
CREATE DATABASE streamsync;
EOF

# Enable uuid-ossp extension
PGPASSWORD='your-rds-password' psql -h your-rds-endpoint.rds.amazonaws.com -U postgres -d streamsync << 'EOF'
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
EOF
```

### Import the backup:
```bash
# Import data
PGPASSWORD='your-rds-password' psql -h your-rds-endpoint.rds.amazonaws.com -U postgres -d streamsync < /tmp/streamsync-backup.sql

# Verify import
PGPASSWORD='your-rds-password' psql -h your-rds-endpoint.rds.amazonaws.com -U postgres -d streamsync -c "
SELECT 
  (SELECT COUNT(*) FROM users) as users_count,
  (SELECT COUNT(*) FROM videos) as videos_count,
  (SELECT COUNT(*) FROM fcm_tokens) as fcm_tokens_count;
"
```

## Step 5: Move Secrets to AWS Systems Manager Parameter Store

### Install AWS CLI jq helper (if not installed):
```bash
sudo yum install -y jq
```

### Store database credentials in Parameter Store:
```bash
# Database host
aws ssm put-parameter \
  --name "/streamsync/prod/database/host" \
  --value "your-rds-endpoint.rds.amazonaws.com" \
  --type "String" \
  --region us-east-1

# Database password (encrypted)
aws ssm put-parameter \
  --name "/streamsync/prod/database/password" \
  --value "your-rds-password" \
  --type "SecureString" \
  --region us-east-1

# Database user
aws ssm put-parameter \
  --name "/streamsync/prod/database/user" \
  --value "postgres" \
  --type "String" \
  --region us-east-1

# Database name
aws ssm put-parameter \
  --name "/streamsync/prod/database/name" \
  --value "streamsync" \
  --type "String" \
  --region us-east-1

# Database port
aws ssm put-parameter \
  --name "/streamsync/prod/database/port" \
  --value "5432" \
  --type "String" \
  --region us-east-1

# JWT Secret
aws ssm put-parameter \
  --name "/streamsync/prod/jwt/secret" \
  --value "$(openssl rand -base64 32)" \
  --type "SecureString" \
  --region us-east-1

# Store other secrets
aws ssm put-parameter \
  --name "/streamsync/prod/youtube/api-key" \
  --value "your-youtube-api-key" \
  --type "SecureString" \
  --region us-east-1
```

### Store Firebase credentials:
```bash
# Firebase Project ID
aws ssm put-parameter \
  --name "/streamsync/prod/firebase/project-id" \
  --value "streamsync-dccc1" \
  --type "String" \
  --region us-east-1

# Firebase Client Email
aws ssm put-parameter \
  --name "/streamsync/prod/firebase/client-email" \
  --value "firebase-adminsdk-fbsvc@streamsync-dccc1.iam.gserviceaccount.com" \
  --type "String" \
  --region us-east-1

# Firebase Private Key (from current .env)
FIREBASE_KEY=$(grep FIREBASE_PRIVATE_KEY ~/streamsync-lite/backend/.env | cut -d '=' -f 2-)
aws ssm put-parameter \
  --name "/streamsync/prod/firebase/private-key" \
  --value "$FIREBASE_KEY" \
  --type "SecureString" \
  --region us-east-1
```

## Step 6: Update IAM Role for Parameter Store Access

### Add permission to EC2 IAM role:
1. Go to **IAM Console** → **Roles**
2. Find: `StreamSyncEC2CloudWatchRole`
3. Click **"Add permissions"** → **"Attach policies"**
4. Search for: `AmazonSSMReadOnlyAccess`
5. Attach it

**Or create custom policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:us-east-1:*:parameter/streamsync/*"
    }
  ]
}
```

## Step 7: Update Backend to Use Parameter Store

### Install AWS SDK in backend:
```bash
cd ~/streamsync-lite/backend
npm install @aws-sdk/client-ssm
```

### Create Parameter Store loader:
Create file: `backend/src/config/parameter-store.config.ts`

```typescript
import { SSMClient, GetParametersCommand } from '@aws-sdk/client-ssm';

const client = new SSMClient({ region: 'us-east-1' });

export async function loadParametersFromSSM() {
  try {
    const command = new GetParametersCommand({
      Names: [
        '/streamsync/prod/database/host',
        '/streamsync/prod/database/port',
        '/streamsync/prod/database/user',
        '/streamsync/prod/database/password',
        '/streamsync/prod/database/name',
        '/streamsync/prod/jwt/secret',
        '/streamsync/prod/youtube/api-key',
        '/streamsync/prod/firebase/project-id',
        '/streamsync/prod/firebase/client-email',
        '/streamsync/prod/firebase/private-key',
      ],
      WithDecryption: true,
    });

    const response = await client.send(command);
    const params: Record<string, string> = {};

    response.Parameters?.forEach((param) => {
      const key = param.Name?.split('/').pop();
      if (key && param.Value) {
        params[key] = param.Value;
      }
    });

    // Map to environment variables
    process.env.DATABASE_HOST = params['host'];
    process.env.DATABASE_PORT = params['port'];
    process.env.DATABASE_USER = params['user'];
    process.env.DATABASE_PASSWORD = params['password'];
    process.env.DATABASE_NAME = params['name'];
    process.env.JWT_SECRET = params['secret'];
    process.env.YOUTUBE_API_KEY = params['api-key'];
    process.env.FIREBASE_PROJECT_ID = params['project-id'];
    process.env.FIREBASE_CLIENT_EMAIL = params['client-email'];
    process.env.FIREBASE_PRIVATE_KEY = params['private-key'];

    console.log('✅ Parameters loaded from AWS Systems Manager');
    return true;
  } catch (error) {
    console.error('❌ Failed to load parameters from SSM:', error);
    return false;
  }
}
```

### Update main.ts to load parameters on startup:
```typescript
import { loadParametersFromSSM } from './config/parameter-store.config';

async function bootstrap() {
  // Load parameters from SSM first
  if (process.env.NODE_ENV === 'production') {
    await loadParametersFromSSM();
  }
  
  const app = await NestFactory.create(AppModule);
  // ... rest of bootstrap
}
```

## Step 8: Test RDS Connection

### Update .env temporarily to test RDS:
```bash
# Backup current .env
cp ~/streamsync-lite/backend/.env ~/streamsync-lite/backend/.env.backup

# Update DATABASE_HOST
sed -i 's/DATABASE_HOST=localhost/DATABASE_HOST=your-rds-endpoint.rds.amazonaws.com/' ~/streamsync-lite/backend/.env
sed -i 's/DATABASE_USER=streamsync/DATABASE_USER=postgres/' ~/streamsync-lite/backend/.env
sed -i 's/DATABASE_PASSWORD=streamsync123/DATABASE_PASSWORD=your-rds-password/' ~/streamsync-lite/backend/.env

# Restart app
pm2 restart streamsync-api

# Check logs
pm2 logs streamsync-api --lines 50
```

### Verify connection:
```bash
# Check health endpoint
curl http://localhost:3000/health

# Test database query
PGPASSWORD='your-rds-password' psql -h your-rds-endpoint.rds.amazonaws.com -U postgres -d streamsync -c "SELECT COUNT(*) FROM users;"
```

## Step 9: Cleanup and Security

### After successful migration:

1. **Stop local PostgreSQL:**
   ```bash
   sudo systemctl stop postgresql
   sudo systemctl disable postgresql
   ```

2. **Restrict RDS public access** (optional):
   - RDS Console → Modify database
   - Public access: **No**
   - Use VPC peering or VPN for external access

3. **Remove sensitive data from .env:**
   ```bash
   # Keep .env minimal, use Parameter Store for secrets
   cat > ~/streamsync-lite/backend/.env << 'EOF'
   NODE_ENV=production
   PORT=3000
   # All other configs loaded from AWS Systems Manager Parameter Store
   EOF
   ```

4. **Delete backup files:**
   ```bash
   rm /tmp/streamsync-backup.sql
   rm /tmp/streamsync-schema.sql
   ```

5. **Update security group:**
   - Remove any 0.0.0.0/0 rules
   - Keep only EC2 security group access

## Step 10: Set up Automated Backups

### RDS Automated Backups (Already configured if enabled):
- Backups run daily during maintenance window
- Retention: 7 days
- Point-in-time recovery available

### Manual snapshot:
```bash
# Create manual snapshot via AWS CLI
aws rds create-db-snapshot \
  --db-instance-identifier streamsync-db \
  --db-snapshot-identifier streamsync-snapshot-$(date +%Y%m%d) \
  --region us-east-1
```

## Verification Checklist

- [ ] RDS instance created and available
- [ ] Database migrated successfully
- [ ] All tables and data present
- [ ] Application connects to RDS
- [ ] Health endpoint responds
- [ ] API endpoints work correctly
- [ ] Push notifications work
- [ ] Secrets stored in Parameter Store
- [ ] IAM role has SSM read permissions
- [ ] Local PostgreSQL stopped
- [ ] Backup files deleted
- [ ] Security groups configured correctly
- [ ] RDS automated backups enabled

## Rollback Plan

If something goes wrong:

```bash
# Restore .env
cp ~/streamsync-lite/backend/.env.backup ~/streamsync-lite/backend/.env

# Start local PostgreSQL
sudo systemctl start postgresql

# Restart app
pm2 restart streamsync-api
```

## Cost Monitoring

### RDS Free Tier Limits:
- 750 hours/month of db.t3.micro (single-AZ)
- 20 GB storage
- 20 GB backup storage
- Will NOT exceed free tier if:
  - Only 1 instance running
  - Less than 20GB data
  - Instance runs continuously (stop/start counts as separate hours)

### Monitor usage:
- AWS Billing Console
- Set up billing alerts for $1 threshold

## Support

If you encounter issues:
1. Check CloudWatch logs: `/aws/ec2/streamsync/app`
2. Check RDS logs in RDS Console
3. Verify security group rules
4. Test connection from EC2: `psql -h endpoint -U postgres -d streamsync`
