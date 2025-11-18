const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

function toEmail(input) {
  const e = String(input || '').trim().toLowerCase();
  if (!e) return null;
  const valid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e);
  return valid ? e : null;
}

exports.siteWaitlist = functions.https.onRequest(async (req, res) => {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const email = toEmail(req.body?.email);
    if (!email) {
      res.status(400).json({ error: 'Invalid email' });
      return;
    }
    console.log('📩 [Site Functions] waitlist signup:', email);
    try {
      await admin.firestore().collection('waitlist').doc(email).set(
        {
          email,
          updatedAt: Date.now(),
          createdAt: Date.now(),
          source: 'howdy-site',
        },
        { merge: true }
      );
      res.status(200).json({ ok: true, saved: true });
    } catch (err) {
      console.warn('⚠️ [Site Functions] Firestore write failed, acknowledging anyway:', err?.message);
      res.status(200).json({ ok: true, saved: false });
    }
  } catch (e) {
    console.error('❌ [Site Functions] waitlist error', e);
    res.status(200).json({ ok: true, saved: false });
  }
});


