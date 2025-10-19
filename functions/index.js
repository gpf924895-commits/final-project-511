const functions = require('firebase-functions');
const admin = require('firebase-admin');
const bcrypt = require('bcryptjs');

// Initialize Firebase Admin SDK
admin.initializeApp();

// Cloud Function: sheikhLogin
// Authenticates a sheikh using uniqueId and password
// Returns a custom token for Firebase Auth
exports.sheikhLogin = functions.https.onCall(async (data, context) => {
  try {
    const { uniqueId, password } = data;

    // Validate input
    if (!uniqueId || !password) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'يرجى إدخال المعرف الفريد وكلمة المرور'
      );
    }

    const db = admin.firestore();

    // Find sheikh document by uniqueId and role
    const querySnapshot = await db
      .collection('users')
      .where('uniqueId', '==', uniqueId.trim())
      .where('role', '==', 'sheikh')
      .limit(1)
      .get();

    if (querySnapshot.empty) {
      throw new functions.https.HttpsError(
        'not-found',
        'حساب الشيخ غير موجود.'
      );
    }

    const sheikhDoc = querySnapshot.docs[0];
    const sheikhData = sheikhDoc.data();
    const uid = sheikhDoc.id;

    // DEMO MODE: Support both bcrypt hash and plaintext password
    let passwordMatch = false;

    if (sheikhData.passwordHash) {
      // Compare with bcrypt hash
      passwordMatch = await bcrypt.compare(password, sheikhData.passwordHash);
    } else if (sheikhData.password) {
      // DEMO ONLY — plaintext password (not for production)
      passwordMatch = password === sheikhData.password;
    }

    if (!passwordMatch) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'كلمة المرور غير صحيحة.'
      );
    }

    // Create custom token with role claim
    const customToken = await admin.auth().createCustomToken(uid, {
      role: 'sheikh',
    });

    // Return token and uid
    return {
      token: customToken,
      uid: uid,
    };
  } catch (error) {
    // Re-throw HttpsErrors as-is
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Log unexpected errors
    console.error('Error in sheikhLogin:', error);
    throw new functions.https.HttpsError(
      'internal',
      'حدث خطأ في الخادم. يرجى المحاولة لاحقاً.'
    );
  }
});

