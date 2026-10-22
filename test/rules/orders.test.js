const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, updateDoc, getDocs, collection, query, where, writeBatch, runTransaction,
  serverTimestamp, Timestamp, Bytes,
} = require('firebase/firestore');
const h = require('./helpers');

describe('subscription & promote orders, payment proofs', () => {
  let env;
  before(async () => { env = await h.setupEnv(); });
  after(async () => { await env.cleanup(); });

  beforeEach(async () => {
    await env.clearFirestore();
    await h.seed(env, {
      'settings/app': h.SETTINGS,
      'admins/root': { createdAt: h.secondsAgo(1) },
      'users/alice': h.userDoc('alice', { referredBy: 'bob', referredByCode: h.codeFor('bob') }),
      'users/bob': h.userDoc('bob', { subscriptionActive: true, balance: 50, totalEarned: 50 }),
      'referrals/bob/referred/alice': { refereeName: 'User alice', status: 'pending', bonus: 0, createdAt: h.secondsAgo(60) },
      'promotePackages/p1': { name: '1 Day', price: 500, durationDays: 1, isActive: true, sortOrder: 0 },
      'promotePackages/p2': { name: 'Old', price: 100, durationDays: 1, isActive: false, sortOrder: 1 },
    });
  });

  describe('subscription submit', () => {
    it('accepts the exact submit batch', async () => {
      await assertSucceeds(h.submitSubscription(h.as(env, 'alice'), 'alice', 'o1'));
    });

    it('rejects an amount different from subscriptionPrice', async () => {
      await assertFails(h.submitSubscription(h.as(env, 'alice'), 'alice', 'o1', { amount: 1 }));
    });

    it('rejects without flipping hasPendingSubscription', async () => {
      await assertFails(h.submitSubscription(h.as(env, 'alice'), 'alice', 'o1', { skipFlag: true }));
    });

    it('rejects without a proof in the same batch', async () => {
      await assertFails(h.submitSubscription(h.as(env, 'alice'), 'alice', 'o1', { skipProof: true }));
    });

    it('only one pending order per user', async () => {
      const db = h.as(env, 'alice');
      await assertSucceeds(h.submitSubscription(db, 'alice', 'o1'));
      await assertFails(h.submitSubscription(db, 'alice', 'o2'));
    });

    it('already subscribed users cannot submit', async () => {
      await assertFails(h.submitSubscription(h.as(env, 'bob'), 'bob', 'o1'));
    });

    it('blocked users cannot submit', async () => {
      await h.seed(env, { 'users/alice': h.userDoc('alice', { isBlocked: true }) });
      await assertFails(h.submitSubscription(h.as(env, 'alice'), 'alice', 'o1'));
    });

    it('users cannot clear their pending flag themselves', async () => {
      const db = h.as(env, 'alice');
      await assertSucceeds(h.submitSubscription(db, 'alice', 'o1'));
      await assertFails(updateDoc(doc(db, 'users/alice'), { hasPendingSubscription: false }));
    });

    it('users cannot approve their own order', async () => {
      const db = h.as(env, 'alice');
      await assertSucceeds(h.submitSubscription(db, 'alice', 'o1'));
      await assertFails(updateDoc(doc(db, 'subscriptionOrders/o1'), { status: 'approved' }));
    });
  });

  describe('payment proofs', () => {
    it('rejects a free-floating proof (no order)', async () => {
      const db = h.as(env, 'alice');
      const bytes = h.smallJpeg();
      await assertFails(setDoc(doc(db, 'paymentProofs/x1'), {
        uid: 'alice', bytes, mimeType: 'image/jpeg', sizeBytes: 1000, createdAt: serverTimestamp(),
      }));
    });

    it('rejects a proof of 600 KB or more', async () => {
      const big = Bytes.fromUint8Array(new Uint8Array(600000));
      await assertFails(h.submitSubscription(h.as(env, 'alice'), 'alice', 'o1', { bytes: big }));
    });

    it('proof readable only by owner and admin', async () => {
      await assertSucceeds(h.submitSubscription(h.as(env, 'alice'), 'alice', 'o1'));
      await assertSucceeds(getDoc(doc(h.as(env, 'alice'), 'paymentProofs/o1')));
      await assertSucceeds(getDoc(doc(h.as(env, 'root'), 'paymentProofs/o1')));
      await assertFails(getDoc(doc(h.as(env, 'bob'), 'paymentProofs/o1')));
      await assertFails(getDocs(collection(h.as(env, 'root'), 'paymentProofs')));
    });

    it('orders are readable only by owner and admin', async () => {
      await assertSucceeds(h.submitSubscription(h.as(env, 'alice'), 'alice', 'o1'));
      await assertSucceeds(getDocs(query(collection(h.as(env, 'alice'), 'subscriptionOrders'), where('uid', '==', 'alice'))));
      await assertFails(getDocs(collection(h.as(env, 'alice'), 'subscriptionOrders')));
      await assertFails(getDoc(doc(h.as(env, 'bob'), 'subscriptionOrders/o1')));
      await assertSucceeds(getDocs(query(collection(h.as(env, 'root'), 'subscriptionOrders'), where('transactionId', '==', 'TXN123456'))));
    });
  });

  describe('admin subscription approval (with referral bonus)', () => {
    beforeEach(async () => {
      await assertSucceeds(h.submitSubscription(h.as(env, 'alice'), 'alice', 'o1'));
    });

    // Mirrors SubscriptionRepository.approve.
    const approve = (db) => runTransaction(db, async (tx) => {
      const order = await tx.get(doc(db, 'subscriptionOrders/o1'));
      if (order.data().status !== 'pending') throw new Error('already reviewed');
      const u = (await tx.get(doc(db, 'users/alice'))).data();
      const bonus = 300;
      let ref = null;
      if (u.referredBy && !u.referralBonusPaid) ref = (await tx.get(doc(db, `users/${u.referredBy}`))).data();
      tx.update(doc(db, 'subscriptionOrders/o1'), { status: 'approved', reviewedAt: serverTimestamp(), reviewedBy: 'root' });
      tx.update(doc(db, 'users/alice'), {
        subscriptionActive: true, subscriptionActivatedAt: serverTimestamp(), hasPendingSubscription: false,
        ...(ref ? { referralBonusPaid: true } : {}),
      });
      tx.set(doc(db, 'users/alice/transactions/sub_o1'), {
        type: 'subscription_payment', amount: 0, balanceAfter: u.balance, refId: 'o1', title: 'Subscription', createdAt: serverTimestamp(),
      });
      if (ref) {
        tx.update(doc(db, `users/${u.referredBy}`), {
          balance: ref.balance + bonus, totalReferralEarned: ref.totalReferralEarned + bonus, referralCount: ref.referralCount + 1,
        });
        tx.set(doc(db, `users/${u.referredBy}/transactions/ref_alice`), {
          type: 'referral_bonus', amount: bonus, balanceAfter: ref.balance + bonus, refId: 'alice', title: 'Referral bonus', createdAt: serverTimestamp(),
        });
        tx.update(doc(db, `referrals/${u.referredBy}/referred/alice`), { status: 'bonus_paid', bonus, paidAt: serverTimestamp() });
      }
    });

    it('approval subscribes the user and pays the referrer exactly once', async () => {
      const db = h.as(env, 'root');
      await assertSucceeds(approve(db));
      const bob = (await getDoc(doc(db, 'users/bob'))).data();
      if (bob.balance !== 350 || bob.referralCount !== 1) throw new Error('bonus not paid correctly');
      const alice = (await getDoc(doc(db, 'users/alice'))).data();
      if (!alice.subscriptionActive || !alice.referralBonusPaid || alice.hasPendingSubscription) throw new Error('bad user');
      // A second approval is blocked by the status check in rules.
      await assertFails(updateDoc(doc(db, 'subscriptionOrders/o1'), { status: 'approved', reviewedAt: serverTimestamp() }));
    });

    it('no referral bonus can be claimed by the referrer themselves', async () => {
      const db = h.as(env, 'bob');
      await assertFails(updateDoc(doc(db, 'users/bob'), { balance: 350, totalReferralEarned: 300, referralCount: 1 }));
    });

    it('admin rejection clears the pending flag', async () => {
      const db = h.as(env, 'root');
      const b = writeBatch(db);
      b.update(doc(db, 'subscriptionOrders/o1'), { status: 'rejected', reviewedAt: serverTimestamp(), reviewedBy: 'root', rejectionReason: 'No payment found' });
      b.update(doc(db, 'users/alice'), { hasPendingSubscription: false });
      await assertSucceeds(b.commit());
      // User can now resubmit.
      await assertSucceeds(h.submitSubscription(h.as(env, 'alice'), 'alice', 'o2'));
    });
  });

  describe('promote orders', () => {
    it('accepts the exact promote batch (no subscription needed)', async () => {
      await assertSucceeds(h.submitPromote(h.as(env, 'alice'), 'alice', 'po1'));
    });

    it('rejects a price different from the package', async () => {
      await assertFails(h.submitPromote(h.as(env, 'alice'), 'alice', 'po1', { price: 1 }));
    });

    it('rejects a duration different from the package', async () => {
      await assertFails(h.submitPromote(h.as(env, 'alice'), 'alice', 'po1', { durationDays: 30 }));
    });

    it('rejects an inactive package', async () => {
      await assertFails(h.submitPromote(h.as(env, 'alice'), 'alice', 'po1', { packageId: 'p2', price: 100, packageName: 'Old' }));
    });

    it('rejects blocked users', async () => {
      await h.seed(env, { 'users/alice': h.userDoc('alice', { isBlocked: true }) });
      await assertFails(h.submitPromote(h.as(env, 'alice'), 'alice', 'po1'));
    });

    it('admin approval creates the task and records the period', async () => {
      await assertSucceeds(h.submitPromote(h.as(env, 'alice'), 'alice', 'po1'));
      const db = h.as(env, 'root');
      const start = Timestamp.now();
      const end = Timestamp.fromMillis(start.toMillis() + 86400000);
      const b = writeBatch(db);
      b.update(doc(db, 'promoteOrders/po1'), {
        status: 'approved', reviewedAt: serverTimestamp(), reviewedBy: 'root', taskId: 'pt1', startAt: start, expiresAt: end,
      });
      b.set(doc(db, 'tasks/pt1'), h.taskDoc({ source: 'promote', ownerUid: 'alice', promoteOrderId: 'po1', startAt: start, expiresAt: end }));
      b.set(doc(db, 'users/alice/transactions/promo_po1'), {
        type: 'promote_payment', amount: 0, balanceAfter: 0, refId: 'po1', title: 'Promotion', createdAt: serverTimestamp(),
      });
      await assertSucceeds(b.commit());
    });
  });
});
