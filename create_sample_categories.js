// Sample script to create categories for testing
// Run this in Firebase Console or as a Cloud Function

const admin = require('firebase-admin');

// Initialize Firebase Admin (if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function createSampleCategories() {
  const categories = [
    // Fiqh categories
    { section: 'fiqh', name: 'أحكام الصلاة', description: 'فقه الصلاة وأحكامها', order: 1 },
    { section: 'fiqh', name: 'أحكام الزكاة', description: 'فقه الزكاة وأحكامها', order: 2 },
    { section: 'fiqh', name: 'أحكام الصيام', description: 'فقه الصيام وأحكامه', order: 3 },
    { section: 'fiqh', name: 'أحكام الحج', description: 'فقه الحج وأحكامه', order: 4 },
    
    // Hadith categories
    { section: 'hadith', name: 'صحيح البخاري', description: 'أحاديث صحيح البخاري', order: 1 },
    { section: 'hadith', name: 'صحيح مسلم', description: 'أحاديث صحيح مسلم', order: 2 },
    { section: 'hadith', name: 'سنن الترمذي', description: 'أحاديث سنن الترمذي', order: 3 },
    { section: 'hadith', name: 'سنن أبي داود', description: 'أحاديث سنن أبي داود', order: 4 },
    
    // Seerah categories
    { section: 'seerah', name: 'ميلاد النبي', description: 'قصة ميلاد النبي صلى الله عليه وسلم', order: 1 },
    { section: 'seerah', name: 'نشأة النبي', description: 'نشأة النبي صلى الله عليه وسلم', order: 2 },
    { section: 'seerah', name: 'البعثة النبوية', description: 'قصة البعثة النبوية', order: 3 },
    { section: 'seerah', name: 'الهجرة النبوية', description: 'قصة الهجرة النبوية', order: 4 },
    
    // Tafsir categories
    { section: 'tafsir', name: 'تفسير سورة الفاتحة', description: 'تفسير سورة الفاتحة', order: 1 },
    { section: 'tafsir', name: 'تفسير سورة البقرة', description: 'تفسير سورة البقرة', order: 2 },
    { section: 'tafsir', name: 'تفسير سورة آل عمران', description: 'تفسير سورة آل عمران', order: 3 },
    { section: 'tafsir', name: 'تفسير سورة النساء', description: 'تفسير سورة النساء', order: 4 },
  ];

  for (const category of categories) {
    try {
      await db.collection('categories').add({
        ...category,
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: 'system', // or the actual sheikh ID
      });
      console.log(`Created category: ${category.name} for section: ${category.section}`);
    } catch (error) {
      console.error(`Error creating category ${category.name}:`, error);
    }
  }
  
  console.log('Sample categories created successfully!');
}

// Run the function
createSampleCategories().catch(console.error);
