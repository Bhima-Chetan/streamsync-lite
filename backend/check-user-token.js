require('dotenv').config();
const { Client } = require('pg');

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

async function checkUser() {
  try {
    await client.connect();
    
    // Find user by email
    const userResult = await client.query(`
      SELECT id, email, name, created_at
      FROM users
      WHERE email = $1
    `, ['chetan@gmail.com']);

    if (userResult.rows.length === 0) {
      console.log('❌ User chetan1@gmail.com not found in database!');
      console.log('\n📋 Available users:');
      const allUsers = await client.query('SELECT id, email, name FROM users ORDER BY created_at DESC');
      allUsers.rows.forEach(u => console.log(`  - ${u.email} (${u.name})`));
      return;
    }

    const user = userResult.rows[0];
    console.log('✅ User found:');
    console.log(`  ID: ${user.id}`);
    console.log(`  Email: ${user.email}`);
    console.log(`  Name: ${user.name}`);
    console.log(`  Created: ${user.created_at}\n`);

    // Check for FCM tokens
    const tokenResult = await client.query(`
      SELECT token, platform, created_at
      FROM fcm_tokens
      WHERE user_id = $1
      ORDER BY created_at DESC
    `, [user.id]);

    console.log(`📱 FCM Tokens for this user: ${tokenResult.rows.length}`);
    if (tokenResult.rows.length > 0) {
      tokenResult.rows.forEach((t, idx) => {
        console.log(`\nToken #${idx + 1}:`);
        console.log(`  Platform: ${t.platform}`);
        console.log(`  Created: ${t.created_at}`);
        console.log(`  Token: ${t.token}`);
      });
    } else {
      console.log('  ⚠️  No FCM tokens registered for this user yet!');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

checkUser();
