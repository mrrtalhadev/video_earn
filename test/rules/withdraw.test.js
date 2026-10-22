const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, updateDoc, getDoc, setDoc, serverTimestamp, runTransaction } = require('firebase/firestore');
const h = require('./helpers');

describe('withdrawals', () => {
  let env;
  before(async () => { env = await h.setupEnv(); });
  after(async () => { await env.cleanup(); });

  async function seedUser(overrides = {}) {
    await h.seed(env, {
      'users/alice': h.userDoc('alice', { subscriptionActive: true, balance: 3000, totalEarned: 3000, ...overrides }),
    });
  }

  beforeEach(async () => {
    await env.clearFirestore();
    await h.seed(env, { 'settings/app': h.SETTINGS, 'admins/root': { createdAt: h.secondsAgo(1) } });
  });

  it('accepts the exact withdraw transaction', async () => {
    await seedUser();
    await assertSucceeds(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 1500));
  });

  it('accepts an IBAN account', async () => {
    await seedUser();
    await assertSucceeds(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 1500, { accountNumber: 'PK36SCBL0000001123456702' }));
  });

  it('rejects below minWithdraw', async () => {
    await seedUser();
    await assertFails(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 1499));
  });

  it('rejects above balance', async () => {
    await seedUser({ balance: 2000 });
    await assertFails(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 2001));
  });

  it('rejects when not subscribed', async () => {
    await seedUser({ subscriptionActive: false });
    await assertFails(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 1500));
  });

  it('rejects when blocked', async () => {
    await seedUser({ isBlocked: true });
    await assertFails(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 1500));
  });

  it('rejects within the cooldown (server time)', async () => {
    await seedUser({ lastWithdrawAt: h.daysAgo(6) });
    await assertFails(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 1500));
  });

  it('accepts after the cooldown', async () => {
    await seedUser({ lastWithdrawAt: h.daysAgo(7.01) });
    await assertSucceeds(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 1500));
  });

  it('rejects a second request right after the first', async () => {
    await seedUser();
    const db = h.as(env, 'alice');
    await assertSucceeds(h.withdraw(db, 'alice', 'w1', 1500));
    await assertFails(h.withdraw(db, 'alice', 'w2', 1500));
  });

  it('rejects holding less than the requested amount', async () => {
    await seedUser();
    await assertFails(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 1500, { holdDelta: 1 }));
  });

  it('rejects a faked prevLastWithdrawAt', async () => {
    await seedUser({ lastWithdrawAt: h.daysAgo(10) });
    await assertFails(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 1500, { prevOverride: null }));
  });

  it('rejects an invalid account number', async () => {
    await seedUser();
    await assertFails(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 1500, { accountNumber: 'abc' }));
  });

  it('rejects a request for another uid', async () => {
    await seedUser();
    await h.seed(env, { 'users/bob': h.userDoc('bob', { subscriptionActive: true, balance: 5000 }) });
    const db = h.as(env, 'alice');
    await assertFails(setDoc(doc(db, 'withdrawRequests/w1'), {
      uid: 'bob', userName: 'Bob', amount: 1500, accountHolderName: 'Ali Khan', bankName: 'HBL',
      accountNumber: '12345678901', status: 'pending', prevLastWithdrawAt: null, createdAt: serverTimestamp(),
    }));
  });

  it('users cannot edit or approve their request', async () => {
    await seedUser();
    const db = h.as(env, 'alice');
    await assertSucceeds(h.withdraw(db, 'alice', 'w1', 1500));
    await assertFails(updateDoc(doc(db, 'withdrawRequests/w1'), { status: 'approved' }));
    await assertFails(updateDoc(doc(db, 'withdrawRequests/w1'), { amount: 1 }));
  });

  describe('admin review', () => {
    beforeEach(async () => {
      await seedUser();
      await assertSucceeds(h.withdraw(h.as(env, 'alice'), 'alice', 'w1', 1500));
    });

    const approve = (db) => runTransaction(db, async (tx) => {
      const r = await tx.get(doc(db, 'withdrawRequests/w1'));
      if (r.data().status !== 'pending') throw new Error('already reviewed');
      const u = (await tx.get(doc(db, 'users/alice'))).data();
      tx.update(doc(db, 'withdrawRequests/w1'), {
        status: 'approved', reviewedAt: serverTimestamp(), reviewedBy: 'root', adminTransferRef: 'REF1',
      });
      tx.update(doc(db, 'users/alice'), {
        pendingWithdraw: u.pendingWithdraw - r.data().amount,
        totalWithdrawn: u.totalWithdrawn + r.data().amount,
      });
    });

    const reject = (db) => runTransaction(db, async (tx) => {
      const r = (await tx.get(doc(db, 'withdrawRequests/w1'))).data();
      const u = (await tx.get(doc(db, 'users/alice'))).data();
      tx.update(doc(db, 'withdrawRequests/w1'), {
        status: 'rejected', reviewedAt: serverTimestamp(), reviewedBy: 'root', rejectionReason: 'Wrong account',
      });
      tx.update(doc(db, 'users/alice'), {
        balance: u.balance + r.amount, pendingWithdraw: u.pendingWithdraw - r.amount,
        lastWithdrawAt: r.prevLastWithdrawAt,
      });
      tx.set(doc(db, 'users/alice/transactions/refund_w1'), {
        type: 'withdraw_refund', amount: r.amount, balanceAfter: u.balance + r.amount,
        refId: 'w1', title: 'Withdrawal refunded', createdAt: serverTimestamp(),
      });
    });

    it('admin approves once; second review is rejected by rules', async () => {
      const db = h.as(env, 'root');
      await assertSucceeds(approve(db));
      await assertFails(updateDoc(doc(db, 'withdrawRequests/w1'), { status: 'rejected', reviewedAt: serverTimestamp() }));
    });

    it('admin reject refunds and restores the cooldown slot', async () => {
      const db = h.as(env, 'root');
      await assertSucceeds(reject(db));
      const u = (await getDoc(doc(db, 'users/alice'))).data();
      if (u.balance !== 3000 || u.pendingWithdraw !== 0 || u.lastWithdrawAt !== null) {
        throw new Error(`unexpected user state ${JSON.stringify(u)}`);
      }
      // Refunded user can withdraw again immediately.
      await assertSucceeds(h.withdraw(h.as(env, 'alice'), 'alice', 'w2', 1500));
    });

    it('admin cannot change status to an unknown value or edit amounts', async () => {
      const db = h.as(env, 'root');
      await assertFails(updateDoc(doc(db, 'withdrawRequests/w1'), { status: 'paid' }));
      await assertFails(updateDoc(doc(db, 'withdrawRequests/w1'), { status: 'approved', amount: 1 }));
    });
  });
});
