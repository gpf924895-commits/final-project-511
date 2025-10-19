// Sheikh Account Seeder Script
// DEMO ONLY — Creates a Sheikh account for testing
// Usage: node seeder.js UNIQUEID "Full Name" "password"
// Example: node seeder.js sheikh001 "الشيخ محمد أحمد" "demo123"

const admin = require('firebase-admin');
const bcrypt = require('bcryptjs');

// Initialize Admin SDK with service account
// You must set GOOGLE_APPLICATION_CREDENTIALS environment variable
// or pass the path to your service account key file
// DO NOT commit service account keys to version control!

try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
} catch (error) {
  console.error('Error initializing Admin SDK:', error.message);
  console.log('\nPlease set GOOGLE_APPLICATION_CREDENTIALS environment variable:');
  console.log('export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"');
  process.exit(1);
}

const db = admin.firestore();

async function createSheikhAccount(uniqueId, name, password) {
  try {
    console.log('Creating sheikh account...');
    console.log('UniqueID:', uniqueId);
    console.log('Name:', name);

    // DEMO ONLY — Hash the password (or store plaintext for simpler demo)
    // For production, always use bcrypt!
    const passwordHash = bcrypt.hashSync(password, 10);

    // Create an Auth user (no email required via Admin SDK)
    const userRecord = await admin.auth().createUser({
      displayName: name,
    });

    const uid = userRecord.uid;
    console.log('Created Auth user with UID:', uid);

    // Create Firestore document
    await db.collection('users').doc(uid).set({
      uid: uid,
      name: name,
      uniqueId: uniqueId,
      role: 'sheikh',
      passwordHash: passwordHash,
      // DEMO ONLY — Also store plaintext for easier testing
      password: password,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('\n✅ Sheikh account created successfully!');
    console.log('UID:', uid);
    console.log('UniqueID:', uniqueId);
    console.log('Password:', password);
    console.log('\nYou can now log in as this sheikh using the uniqueId and password.');
  } catch (error) {
    console.error('\n❌ Error creating sheikh account:', error.message);
    process.exit(1);
  }
}

// Parse command-line arguments
const args = process.argv.slice(2);

if (args.length < 3) {
  console.log('Usage: node seeder.js UNIQUEID "Full Name" "password"');
  console.log('Example: node seeder.js sheikh001 "الشيخ محمد أحمد" "demo123"');
  process.exit(1);
}

const [uniqueId, name, password] = args;

createSheikhAccount(uniqueId, name, password)
  .then(() => {
    console.log('\nDone!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });

