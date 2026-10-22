// Shared helpers for Firestore rules tests. The write helpers mirror the exact
// batches/transactions the Flutter repositories perform, so a passing "valid"
// test proves the app's real writes are accepted.
const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, writeBatch, runTransaction, serverTimestamp, Timestamp, Bytes, setLogLevel,
} = require('firebase/firestore');

// Expected PERMISSION_DENIED errors are noisy; keep test output readable.
setLogLevel('silent');

const PROJECT_ID = 'demo-taskearn';

const SETTINGS = {
  subscriptionPrice: 1500,
  videoReward: 10,
  referralBonus: 300,
  minWithdraw: 1500,
  withdrawCooldownDays: 7,
  minWatchPercent: 95,
  maxVideoMinutes: 20,
  bank: { bankName: 'HBL', accountTitle: 'TaskEarn', accountNumber: '12345678901', iban: '' },
  supportWhatsapp: '', supportEmail: '', aboutUs: '', termsAndConditions: '',
  contactUs: { phone: '', email: '', address: '', whatsapp: '' },
  maintenanceMode: false,
  minAppVersion: '1.0.0',
};

async function setupEnv() {
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
}

const secondsAgo = (s) => Timestamp.fromMillis(Date.now() - s * 1000);
const daysAgo = (d) => secondsAgo(d * 86400);

function userDoc(uid, overrides = {}) {
  return {
    name: `User ${uid}`,
    nameLower: `user ${uid}`.toLowerCase(),
    email: `${uid}@test.com`,
    phone: '03001234567',
    photoUrl: null,
    isBlocked: false,
    subscriptionActive: false,
    subscriptionActivatedAt: null,
    hasPendingSubscription: false,
    balance: 0,
    totalEarned: 0,
    totalReferralEarned: 0,
    totalWithdrawn: 0,
    pendingWithdraw: 0,
    completedTasksCount: 0,
    referralCode: codeFor(uid),
    referredBy: null,
    referredByCode: null,
    referralBonusPaid: false,
    referralCount: 0,
    lastWithdrawAt: null,
    lastWithdrawRequestId: null,
    lastCompletionTaskId: null,
    createdAt: Timestamp.now(),
    ...overrides,
  };
}

/** Deterministic 8-char code for a uid (test-only). */
function codeFor(uid) {
  return (uid.toUpperCase().replace(/[^A-Z0-9]/g, '') + 'XXXXXXXX').slice(0, 8);
}

function taskDoc(overrides = {}) {
  return {
    title: 'Video', description: '', youtubeVideoId: 'dQw4w9WgXcQ',
    youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
    durationSeconds: 60, source: 'admin', ownerUid: null, promoteOrderId: null,
    isActive: true, expiresAt: Timestamp.fromDate(new Date('2099-12-31')), order: 0,
    createdAt: Timestamp.now(),
    ...overrides,
  };
}

/** Seeds documents with rules disabled. `docs` maps path → data. */
async function seed(env, docs) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [p, data] of Object.entries(docs)) await setDoc(doc(db, p), data);
  });
}

const as = (env, uid) => env.authenticatedContext(uid, { email: `${uid}@test.com` }).firestore();

// ---------------------------------------------------------------- app writes

/** Signup batch: user + referral code (+ referral entry). */
function signupBatch(db, uid, { code = codeFor(uid), referredBy = null, referredByCode = null, user = {}, extra } = {}) {
  const b = writeBatch(db);
  b.set(doc(db, `users/${uid}`), userDoc(uid, {
    referralCode: code, referredBy, referredByCode, createdAt: serverTimestamp(), ...user,
  }));
  b.set(doc(db, `referralCodes/${code}`), { uid });
  if (referredBy) {
    b.set(doc(db, `referrals/${referredBy}/referred/${uid}`), {
      refereeName: `User ${uid}`, status: 'pending', bonus: 0, createdAt: serverTimestamp(),
    });
  }
  if (extra) extra(b);
  return b.commit();
}

/** Completion transaction exactly as WatchRepository.completeTask performs it. */
function completeTask(db, uid, taskId, opts = {}) {
  const { reward = 10, skipCredit = false, skipLedger = false, skipCompletion = false, skipSession = false, creditDelta } = opts;
  return runTransaction(db, async (tx) => {
    const userRef = doc(db, `users/${uid}`);
    const snap = await tx.get(userRef);
    const u = snap.data();
    const delta = creditDelta ?? reward;
    if (!skipCompletion) {
      tx.set(doc(db, `users/${uid}/completions/${taskId}`), {
        taskId, reward, completedAt: serverTimestamp(),
      });
    }
    if (!skipCredit) {
      tx.update(userRef, {
        balance: u.balance + delta,
        totalEarned: u.totalEarned + delta,
        completedTasksCount: u.completedTasksCount + 1,
        lastCompletionTaskId: taskId,
      });
    }
    if (!skipLedger) {
      tx.set(doc(db, `users/${uid}/transactions/task_${taskId}`), {
        type: 'task_reward', amount: reward, balanceAfter: u.balance + delta,
        refId: taskId, title: 'Video reward', createdAt: serverTimestamp(),
      });
    }
    if (!skipSession) {
      tx.update(doc(db, `watchSessions/${uid}_${taskId}`), {
        status: 'completed', completedAt: serverTimestamp(), reportedWatchedSeconds: 60,
      });
    }
  });
}

/** Withdraw transaction exactly as WithdrawRepository.submit performs it. */
function withdraw(db, uid, reqId, amount, opts = {}) {
  const { holdDelta, prevOverride, accountNumber = '12345678901' } = opts;
  return runTransaction(db, async (tx) => {
    const userRef = doc(db, `users/${uid}`);
    const u = (await tx.get(userRef)).data();
    const hold = holdDelta ?? amount;
    tx.set(doc(db, `withdrawRequests/${reqId}`), {
      uid, userName: u.name, amount, accountHolderName: 'Ali Khan', bankName: 'HBL',
      accountNumber, status: 'pending',
      prevLastWithdrawAt: prevOverride !== undefined ? prevOverride : u.lastWithdrawAt,
      createdAt: serverTimestamp(),
    });
    tx.update(userRef, {
      balance: u.balance - hold,
      pendingWithdraw: u.pendingWithdraw + hold,
      lastWithdrawAt: serverTimestamp(),
      lastWithdrawRequestId: reqId,
    });
    tx.set(doc(db, `users/${uid}/transactions/wd_${reqId}`), {
      type: 'withdraw_hold', amount: -amount, balanceAfter: u.balance - hold,
      refId: reqId, title: 'Withdrawal request', createdAt: serverTimestamp(),
    });
  });
}

const smallJpeg = () => Bytes.fromUint8Array(new Uint8Array(1000).fill(7));

/** Subscription submit batch: proof + order + pending flag. */
function submitSubscription(db, uid, orderId, opts = {}) {
  const { amount = 1500, price = amount, skipFlag = false, skipProof = false, bytes = smallJpeg() } = opts;
  const b = writeBatch(db);
  if (!skipProof) {
    b.set(doc(db, `paymentProofs/${orderId}`), {
      uid, bytes, mimeType: 'image/jpeg', sizeBytes: bytes.toUint8Array().length,
      createdAt: serverTimestamp(),
    });
  }
  b.set(doc(db, `subscriptionOrders/${orderId}`), {
    uid, userName: `User ${uid}`, userEmail: `${uid}@test.com`, amount, priceAtSubmission: price,
    transactionId: 'TXN123456', proofId: orderId, status: 'pending', createdAt: serverTimestamp(),
  });
  if (!skipFlag) b.update(doc(db, `users/${uid}`), { hasPendingSubscription: true });
  return b.commit();
}

/** Promote submit batch: proof + order. */
function submitPromote(db, uid, orderId, opts = {}) {
  const { packageId = 'p1', price = 500, durationDays = 1, packageName = '1 Day' } = opts;
  const b = writeBatch(db);
  const bytes = smallJpeg();
  b.set(doc(db, `paymentProofs/${orderId}`), {
    uid, bytes, mimeType: 'image/jpeg', sizeBytes: bytes.toUint8Array().length,
    createdAt: serverTimestamp(),
  });
  b.set(doc(db, `promoteOrders/${orderId}`), {
    uid, userName: `User ${uid}`, videoUrl: 'https://youtu.be/dQw4w9WgXcQ',
    youtubeVideoId: 'dQw4w9WgXcQ', videoTitle: 'My video', videoDescription: '',
    packageId, packageName, price, durationDays, transactionId: 'TXN654321',
    proofId: orderId, status: 'pending', createdAt: serverTimestamp(),
  });
  return b.commit();
}

module.exports = {
  PROJECT_ID, SETTINGS, setupEnv, seed, as, userDoc, taskDoc, codeFor, secondsAgo, daysAgo,
  signupBatch, completeTask, withdraw, submitSubscription, submitPromote, smallJpeg,
};
