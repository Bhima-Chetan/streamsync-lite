require('dotenv').config();
const { Client } = require('pg');

// Connect to RDS PostgreSQL
const client = new Client({
  host: process.env.DATABASE_HOST,
  port: parseInt(process.env.DATABASE_PORT || '5432'),
  user: process.env.DATABASE_USER,
  password: process.env.DATABASE_PASSWORD,
  database: process.env.DATABASE_NAME,
  ssl: process.env.DATABASE_HOST?.includes('rds.amazonaws.com')
    ? { rejectUnauthorized: false }
    : false,
});

async function getAllFcmTokensFromRDS() {
  try {
    console.log('🔌 Connecting to RDS PostgreSQL...');
    console.log(`   Host: ${process.env.DATABASE_HOST}`);
    console.log(`   Database: ${process.env.DATABASE_NAME}\n`);
    
    await client.connect();
    console.log('✅ Connected to RDS successfully!\n');

    // Get all FCM tokens with user details
    console.log('📱 Fetching all FCM tokens from database...\n');
    
    const result = await client.query(`
      SELECT 
        ft.id as token_id,
        ft.user_id,
        ft.token,
        ft.platform,
        ft.created_at as token_created,
        ft.updated_at as token_updated,
        u.email,
        u.name,
        u.created_at as user_created
      FROM fcm_tokens ft
      LEFT JOIN users u ON ft.user_id = u.id
      ORDER BY ft.created_at DESC
    `);

    console.log('═══════════════════════════════════════════════════════════');
    console.log(`   TOTAL FCM TOKENS IN RDS: ${result.rows.length}`);
    console.log('═══════════════════════════════════════════════════════════\n');

    if (result.rows.length === 0) {
      console.log('⚠️  No FCM tokens found in database!');
      console.log('   Users need to login to the app to register their tokens.\n');
    } else {
      result.rows.forEach((row, idx) => {
        console.log(`┌─────────────────────────────────────────────────────────┐`);
        console.log(`│ TOKEN #${idx + 1}`.padEnd(59) + '│');
        console.log(`├─────────────────────────────────────────────────────────┤`);
        console.log(`│ User:     ${(row.name || 'Unknown').padEnd(45)}│`);
        console.log(`│ Email:    ${(row.email || 'Unknown').padEnd(45)}│`);
        console.log(`│ User ID:  ${row.user_id.padEnd(45)}│`);
        console.log(`│ Platform: ${row.platform.padEnd(45)}│`);
        console.log(`│ Created:  ${new Date(row.token_created).toLocaleString().padEnd(45)}│`);
        console.log(`├─────────────────────────────────────────────────────────┤`);
        console.log(`│ FCM TOKEN:`.padEnd(59) + '│');
        
        // Split token into multiple lines for readability
        const token = row.token;
        const chunkSize = 54;
        for (let i = 0; i < token.length; i += chunkSize) {
          const chunk = token.substring(i, i + chunkSize);
          console.log(`│ ${chunk.padEnd(57)}│`);
        }
        
        console.log(`└─────────────────────────────────────────────────────────┘\n`);
      });
    }

    // Show user statistics
    console.log('\n📊 USER STATISTICS:');
    console.log('───────────────────────────────────────────────────────────\n');
    
    const userStats = await client.query(`
      SELECT 
        u.id,
        u.name,
        u.email,
        u.created_at,
        COUNT(ft.id) as token_count
      FROM users u
      LEFT JOIN fcm_tokens ft ON u.id = ft.user_id
      GROUP BY u.id, u.name, u.email, u.created_at
      ORDER BY u.created_at DESC
    `);

    userStats.rows.forEach(user => {
      const tokenStatus = user.token_count > 0 
        ? `✅ ${user.token_count} token(s)` 
        : '❌ No tokens';
      
      console.log(`${user.name} (${user.email})`);
      console.log(`  ID: ${user.id}`);
      console.log(`  Tokens: ${tokenStatus}`);
      console.log(`  Created: ${new Date(user.created_at).toLocaleString()}\n`);
    });

  } catch (error) {
    console.error('\n❌ ERROR connecting to RDS:');
    console.error(`   ${error.message}\n`);
    console.error('Stack trace:', error.stack);
  } finally {
    await client.end();
    console.log('\n🔌 Database connection closed');
  }
}

// Run the function
getAllFcmTokensFromRDS();
