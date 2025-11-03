require('dotenv').config();
const { Client } = require('pg');

// Database connection config from environment
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

async function getFcmTokens() {
  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected to database\n');

    // Query all FCM tokens
    const result = await client.query(`
      SELECT 
        ft.id,
        ft.user_id,
        ft.token,
        ft.platform,
        ft.created_at,
        u.email,
        u.name
      FROM fcm_tokens ft
      LEFT JOIN users u ON ft.user_id = u.id
      ORDER BY ft.created_at DESC
    `);

    console.log(`📱 Found ${result.rows.length} FCM token(s):\n`);

    result.rows.forEach((row, idx) => {
      console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      console.log(`Token #${idx + 1}:`);
      console.log(`  User: ${row.name} (${row.email})`);
      console.log(`  User ID: ${row.user_id}`);
      console.log(`  Platform: ${row.platform}`);
      console.log(`  Created: ${row.created_at}`);
      console.log(`  Token: ${row.token}`);
      console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);
    });

    // Also show token count per user
    const userStats = await client.query(`
      SELECT 
        u.email,
        u.name,
        COUNT(ft.id) as token_count
      FROM users u
      LEFT JOIN fcm_tokens ft ON u.id = ft.user_id
      GROUP BY u.id, u.email, u.name
      ORDER BY token_count DESC
    `);

    console.log('\n📊 Tokens per user:');
    userStats.rows.forEach(row => {
      console.log(`  ${row.name} (${row.email}): ${row.token_count} token(s)`);
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
  } finally {
    await client.end();
    console.log('\n🔌 Database connection closed');
  }
}

getFcmTokens();
