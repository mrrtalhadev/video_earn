const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, collection, getDocs,
} = require('firebase/firestore');
const h = require('./helpers');

describe('users, signup & referral codes', () => {
  let env;
  before(async () => { env = await h.setupEnv(); });
  after(async () => { await env.cleanup(); });
  beforeEach(async () => {
    await env.clearFirestore();
    await h.seed(env, { 'settings/app': h.SETTINGS });
  });

  describe('signup', () => {
    it('accepts the exact signup batch', async () => {
      await assertSucceeds(h.signupBatch(h.as(env, 'alice'), 'alice'));
    });

    it('accepts a referred signup with a matching code', async () => {
      await h.seed(env, {
        'users/bob': h.userDoc('bob'),
        [`referralCodes/${h.codeFor('bob')}`]: { uid: 'bob' },
      });
      await assertSucceeds(h.signupBatch(h.as(env, 'alice'), 'alice', {
        referredBy: 'bob', referredByCode: h.codeFor('bob'),
      }));
    });

    for (const [field, value] of [
      ['balance', 100], ['totalEarned', 5], ['subscriptionActive', true],
      ['referralBonusPaid', true], ['isBlocked', true], ['hasPendingSubscription', true],
      ['referralCount', 3], ['completedTasksCount', 1], ['pendingWithdraw', 1],
    ]) {
      it(`rejects signup with ${field}=${value}`, async () => {
        await assertFails(h.signupBatch(h.as(env, 'alice'), 'alice', { user: { [field]: value } }));
      });
    }

    it('rejects unknown extra fields', async () => {
      await assertFails(h.signupBatch(h.as(env, 'alice'), 'alice', { user: { isAdmin: true } }));
    });

    it('rejects a back-dated createdAt', async () => {
      await assertFails(h.signupBatch(h.as(env, 'alice'), 'alice', { user: { createdAt: h.daysAgo(30) } }));
    });

    it('rejects an email that is not the auth email', async () => {
      await assertFails(h.signupBatch(h.as(env, 'alice'), 'alice', { user: { email: 'x@y.com' } }));
    });

    it('rejects self-referral', async () => {
      await assertFails(h.signupBatch(h.as(env, 'alice'), 'alice', {
        referredBy: 'alice', referredByCode: h.codeFor('alice'),
      }));
    });

    it('rejects referredBy that does not own the code used', async () => {
      await h.seed(env, {
        'users/bob': h.userDoc('bob'),
        [`referralCodes/${h.codeFor('bob')}`]: { uid: 'bob' },
        'users/carol': h.userDoc('carol'),
      });
      await assertFails(h.signupBatch(h.as(env, 'alice'), 'alice', {
        referredBy: 'carol', referredByCode: h.codeFor('bob'),
      }));
    });

    it('rejects a user doc without its referral code doc', async () => {
      const db = h.as(env, 'alice');
      await assertFails(setDoc(doc(db, 'users/alice'), h.userDoc('alice', { createdAt: serverTimestamp() })));
    });

    it('rejects creating a doc for another uid', async () => {
      const db = h.as(env, 'alice');
      const b = writeBatch(db);
      b.set(doc(db, 'users/mallory'), h.userDoc('mallory', { email: 'alice@test.com', createdAt: serverTimestamp() }));
      b.set(doc(db, `referralCodes/${h.codeFor('mallory')}`), { uid: 'alice' });
      await assertFails(b.commit());
    });
  });

  describe('referral codes', () => {
    it('code uniqueness: a taken code cannot be reused', async () => {
      await h.seed(env, { 'referralCodes/SAMECODE': { uid: 'bob' } });
      await assertFails(h.signupBatch(h.as(env, 'alice'), 'alice', { code: 'SAMECODE' }));
    });

    it('a user cannot create a second code after signup', async () => {
      await h.seed(env, {
        'users/alice': h.userDoc('alice'),
        [`referralCodes/${h.codeFor('alice')}`]: { uid: 'alice' },
      });
      await assertFails(setDoc(doc(h.as(env, 'alice'), 'referralCodes/NEWCODE1'), { uid: 'alice' }));
    });

    it('codes can be validated by anyone but not listed', async () => {
      await h.seed(env, { 'referralCodes/ABCDEFGH': { uid: 'bob' } });
      const anon = env.unauthenticatedContext().firestore();
      await assertSucceeds(getDoc(doc(anon, 'referralCodes/ABCDEFGH')));
      await assertFails(getDocs(collection(anon, 'referralCodes')));
    });

    it('codes are immutable', async () => {
      await h.seed(env, { 'referralCodes/ABCDEFGH': { uid: 'alice' } });
      const db = h.as(env, 'alice');
      await assertFails(updateDoc(doc(db, 'referralCodes/ABCDEFGH'), { uid: 'alice' }));
      await assertFails(deleteDoc(doc(db, 'referralCodes/ABCDEFGH')));
    });
  });

  describe('referral entries', () => {
    beforeEach(async () => {
      await h.seed(env, {
        'users/bob': h.userDoc('bob'),
        'users/alice': h.userDoc('alice', { referredBy: 'bob', referredByCode: h.codeFor('bob') }),
      });
    });

    it('cannot be created after signup', async () => {
      await assertFails(setDoc(doc(h.as(env, 'alice'), 'referrals/bob/referred/alice'), {
        refereeName: 'Alice', status: 'pending', bonus: 0, createdAt: serverTimestamp(),
      }));
    });

    it('referrer can read own list, others cannot', async () => {
      await h.seed(env, { 'referrals/bob/referred/alice': { refereeName: 'A', status: 'pending', bonus: 0 } });
      await assertSucceeds(getDocs(collection(h.as(env, 'bob'), 'referrals/bob/referred')));
      await assertFails(getDocs(collection(h.as(env, 'alice'), 'referrals/bob/referred')));
    });

    it('only admin can mark bonus paid', async () => {
      await h.seed(env, {
        'referrals/bob/referred/alice': { refereeName: 'A', status: 'pending', bonus: 0 },
        'admins/root': { createdAt: h.secondsAgo(1) },
      });
      await assertFails(updateDoc(doc(h.as(env, 'bob'), 'referrals/bob/referred/alice'), { status: 'bonus_paid', bonus: 300 }));
      await assertSucceeds(updateDoc(doc(h.as(env, 'root'), 'referrals/bob/referred/alice'), { status: 'bonus_paid', bonus: 300 }));
    });
  });

  describe('user updates', () => {
    beforeEach(async () => {
      await h.seed(env, {
        'users/alice': h.userDoc('alice', { subscriptionActive: true, balance: 2000 }),
        'users/bob': h.userDoc('bob', { referredBy: 'carol', referredByCode: 'CAROLXXX' }),
        'admins/root': { createdAt: h.secondsAgo(1) },
      });
    });

    it('allows editing name/phone/photoUrl', async () => {
      await assertSucceeds(updateDoc(doc(h.as(env, 'alice'), 'users/alice'), {
        name: 'Alice Khan', nameLower: 'alice khan', phone: '+923001234567', photoUrl: 'https://x.y/p.png',
      }));
    });

    it('rejects an invalid phone', async () => {
      await assertFails(updateDoc(doc(h.as(env, 'alice'), 'users/alice'), { phone: '12345' }));
    });

    for (const [field, value] of [
      ['balance', 999999], ['totalEarned', 1], ['totalWithdrawn', 5], ['subscriptionActive', false],
      ['isBlocked', true], ['referralBonusPaid', true], ['referralCount', 9], ['referredBy', 'mallory'],
      ['referralCode', 'ZZZZZZZZ'], ['pendingWithdraw', 7], ['lastWithdrawAt', h.daysAgo(30)], ['email', 'z@z.com'],
      ['hasPendingSubscription', true], ['totalReferralEarned', 300], ['completedTasksCount', 4],
    ]) {
      it(`rejects changing ${field}`, async () => {
        await assertFails(updateDoc(doc(h.as(env, 'alice'), 'users/alice'), { [field]: value }));
      });
    }

    it('referredBy is immutable', async () => {
      await assertFails(updateDoc(doc(h.as(env, 'bob'), 'users/bob'), { referredBy: null, referredByCode: null }));
    });

    it('blocked users cannot edit their profile', async () => {
      await h.seed(env, { 'users/alice': h.userDoc('alice', { isBlocked: true }) });
      await assertFails(updateDoc(doc(h.as(env, 'alice'), 'users/alice'), { name: 'New Name', nameLower: 'new name' }));
    });

    it('users cannot read or write other users', async () => {
      await assertFails(getDoc(doc(h.as(env, 'alice'), 'users/bob')));
      await assertFails(updateDoc(doc(h.as(env, 'alice'), 'users/bob'), { name: 'Hacked', nameLower: 'hacked' }));
      await assertFails(getDocs(collection(h.as(env, 'alice'), 'users')));
    });

    it('users cannot delete their doc', async () => {
      await assertFails(deleteDoc(doc(h.as(env, 'alice'), 'users/alice')));
    });

    it('admin can read all users and block', async () => {
      await assertSucceeds(getDocs(collection(h.as(env, 'root'), 'users')));
      await assertSucceeds(updateDoc(doc(h.as(env, 'root'), 'users/alice'), { isBlocked: true }));
    });
  });

  describe('admins collection', () => {
    it('no client can create an admin doc, not even an admin', async () => {
      await h.seed(env, { 'admins/root': { createdAt: h.secondsAgo(1) } });
      await assertFails(setDoc(doc(h.as(env, 'alice'), 'admins/alice'), { createdAt: serverTimestamp() }));
      await assertFails(setDoc(doc(h.as(env, 'root'), 'admins/alice'), { createdAt: serverTimestamp() }));
      await assertFails(deleteDoc(doc(h.as(env, 'root'), 'admins/root')));
    });

    it('a user can check only their own admin marker', async () => {
      await h.seed(env, { 'admins/root': { createdAt: h.secondsAgo(1) } });
      await assertSucceeds(getDoc(doc(h.as(env, 'alice'), 'admins/alice')));
      await assertFails(getDoc(doc(h.as(env, 'alice'), 'admins/root')));
      await assertFails(getDocs(collection(h.as(env, 'root'), 'admins')));
    });
  });

  describe('content', () => {
    beforeEach(async () => {
      await h.seed(env, { 'admins/root': { createdAt: h.secondsAgo(1) }, 'users/alice': h.userDoc('alice') });
    });

    it('users can read but not write settings/tasks/packages/faqs', async () => {
      const db = h.as(env, 'alice');
      await assertSucceeds(getDoc(doc(db, 'settings/app')));
      await assertFails(updateDoc(doc(db, 'settings/app'), { videoReward: 1000 }));
      await assertFails(setDoc(doc(db, 'tasks/t1'), h.taskDoc()));
      await assertFails(setDoc(doc(db, 'promotePackages/p1'), { name: 'x', price: 1, durationDays: 1, isActive: true }));
      await assertFails(setDoc(doc(db, 'faqs/f1'), { question: 'q', answer: 'a', sortOrder: 0, isActive: true }));
    });

    it('signed-out users cannot read settings', async () => {
      await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'settings/app')));
    });

    it('admin can write content', async () => {
      const db = h.as(env, 'root');
      await assertSucceeds(updateDoc(doc(db, 'settings/app'), { videoReward: 20 }));
      await assertSucceeds(setDoc(doc(db, 'tasks/t1'), h.taskDoc()));
    });
  });
});
