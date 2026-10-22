const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, updateDoc, writeBatch, serverTimestamp, getDocs, collection, increment, runTransaction,
} = require('firebase/firestore');
const h = require('./helpers');

describe('watch sessions & task completion', () => {
  let env;
  before(async () => { env = await h.setupEnv(); });
  after(async () => { await env.cleanup(); });

  // A 60s video watched for 70s of server time.
  async function seedReady({ user = {}, task = {}, session = {}, startedSecondsAgo = 70 } = {}) {
    await h.seed(env, {
      'users/alice': h.userDoc('alice', { subscriptionActive: true, balance: 100, totalEarned: 100, ...user }),
      'tasks/t1': h.taskDoc(task),
      'watchSessions/alice_t1': {
        uid: 'alice', taskId: 't1', status: 'started', startedAt: h.secondsAgo(startedSecondsAgo), ...session,
      },
    });
  }

  beforeEach(async () => {
    await env.clearFirestore();
    await h.seed(env, { 'settings/app': h.SETTINGS });
  });

  describe('sessions', () => {
    beforeEach(async () => {
      await h.seed(env, { 'users/alice': h.userDoc('alice', { subscriptionActive: true }), 'tasks/t1': h.taskDoc() });
    });

    const start = (db, data = {}) => setDoc(doc(db, 'watchSessions/alice_t1'), {
      uid: 'alice', taskId: 't1', status: 'started', startedAt: serverTimestamp(), ...data,
    });

    it('subscribed user can start a session with server time', async () => {
      await assertSucceeds(start(h.as(env, 'alice')));
    });

    it('session start cannot be back-dated', async () => {
      await assertFails(start(h.as(env, 'alice'), { startedAt: h.secondsAgo(3600) }));
    });

    it('session cannot be created as completed', async () => {
      await assertFails(start(h.as(env, 'alice'), { status: 'completed' }));
    });

    it('session id must be {uid}_{taskId}', async () => {
      await assertFails(setDoc(doc(h.as(env, 'alice'), 'watchSessions/whatever'), {
        uid: 'alice', taskId: 't1', status: 'started', startedAt: serverTimestamp(),
      }));
    });

    it('unsubscribed user cannot start a session', async () => {
      await h.seed(env, { 'users/alice': h.userDoc('alice') });
      await assertFails(start(h.as(env, 'alice')));
    });

    it('blocked user cannot start a session', async () => {
      await h.seed(env, { 'users/alice': h.userDoc('alice', { subscriptionActive: true, isBlocked: true }) });
      await assertFails(start(h.as(env, 'alice')));
    });

    it('restart moves startedAt to now only', async () => {
      await h.seed(env, { 'watchSessions/alice_t1': { uid: 'alice', taskId: 't1', status: 'started', startedAt: h.secondsAgo(500) } });
      await assertSucceeds(start(h.as(env, 'alice')));
      await assertFails(updateDoc(doc(h.as(env, 'alice'), 'watchSessions/alice_t1'), { startedAt: h.secondsAgo(1000) }));
    });

    it('cannot mark a session completed without a completion', async () => {
      await h.seed(env, { 'watchSessions/alice_t1': { uid: 'alice', taskId: 't1', status: 'started', startedAt: h.secondsAgo(500) } });
      await assertFails(updateDoc(doc(h.as(env, 'alice'), 'watchSessions/alice_t1'), {
        status: 'completed', completedAt: serverTimestamp(), reportedWatchedSeconds: 60,
      }));
    });

    it("cannot touch another user's session", async () => {
      await h.seed(env, {
        'users/bob': h.userDoc('bob', { subscriptionActive: true }),
        'watchSessions/alice_t1': { uid: 'alice', taskId: 't1', status: 'started', startedAt: h.secondsAgo(500) },
      });
      await assertFails(updateDoc(doc(h.as(env, 'bob'), 'watchSessions/alice_t1'), { startedAt: serverTimestamp() }));
    });
  });

  describe('completion', () => {
    it('accepts the exact completion transaction', async () => {
      await seedReady();
      await assertSucceeds(h.completeTask(h.as(env, 'alice'), 'alice', 't1'));
    });

    it('rejects completion before minWatchPercent of server time', async () => {
      await seedReady({ startedSecondsAgo: 30 });
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1'));
    });

    it('rejects completion after 3x the duration', async () => {
      await seedReady({ startedSecondsAgo: 200 });
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1'));
    });

    it('rejects a replay (one completion per task)', async () => {
      await seedReady();
      const db = h.as(env, 'alice');
      await assertSucceeds(h.completeTask(db, 'alice', 't1'));
      // Even with a fresh "started" session, the completion doc already exists.
      await h.seed(env, { 'watchSessions/alice_t1': { uid: 'alice', taskId: 't1', status: 'started', startedAt: h.secondsAgo(70) } });
      await assertFails(h.completeTask(db, 'alice', 't1'));
    });

    it('rejects a reward different from videoReward', async () => {
      await seedReady();
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1', { reward: 500 }));
    });

    it('rejects a balance credit larger than the reward', async () => {
      await seedReady();
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1', { creditDelta: 1000 }));
    });

    it('rejects a credit without a new completion', async () => {
      await seedReady();
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1', { skipCompletion: true }));
    });

    it('rejects a completion without the credit', async () => {
      await seedReady();
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1', { skipCredit: true }));
    });

    it('rejects a completion without the ledger row', async () => {
      await seedReady();
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1', { skipLedger: true }));
    });

    it('rejects when not subscribed', async () => {
      await seedReady({ user: { subscriptionActive: false } });
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1'));
    });

    it('rejects when blocked', async () => {
      await seedReady({ user: { isBlocked: true } });
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1'));
    });

    it('rejects an expired task', async () => {
      await seedReady({ task: { expiresAt: h.secondsAgo(1) } });
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1'));
    });

    it('rejects an inactive task', async () => {
      await seedReady({ task: { isActive: false } });
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1'));
    });

    it("rejects earning from one's own promoted video", async () => {
      await seedReady({ task: { source: 'promote', ownerUid: 'alice' } });
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1'));
    });

    it('rejects without a session', async () => {
      await h.seed(env, {
        'users/alice': h.userDoc('alice', { subscriptionActive: true }),
        'tasks/t1': h.taskDoc(),
      });
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1', { skipSession: true }));
    });

    it('rejects a session already completed', async () => {
      await seedReady({ session: { status: 'completed' } });
      await assertFails(h.completeTask(h.as(env, 'alice'), 'alice', 't1', { skipSession: true }));
    });

    it("rejects using another user's session", async () => {
      await seedReady();
      await h.seed(env, { 'users/bob': h.userDoc('bob', { subscriptionActive: true }) });
      // bob has no session of his own for t1
      await assertFails(h.completeTask(h.as(env, 'bob'), 'bob', 't1', { skipSession: true }));
    });

    it('rejects double-credit via two increments in one batch', async () => {
      await seedReady();
      const db = h.as(env, 'alice');
      const b = writeBatch(db);
      b.set(doc(db, 'users/alice/completions/t1'), { taskId: 't1', reward: 10, completedAt: serverTimestamp() });
      b.update(doc(db, 'users/alice'), {
        balance: increment(10), totalEarned: increment(10), completedTasksCount: increment(1), lastCompletionTaskId: 't1',
      });
      b.update(doc(db, 'users/alice'), { balance: increment(10), totalEarned: increment(10) });
      b.set(doc(db, 'users/alice/transactions/task_t1'), {
        type: 'task_reward', amount: 10, balanceAfter: 120, refId: 't1', title: 'Video reward', createdAt: serverTimestamp(),
      });
      b.update(doc(db, 'watchSessions/alice_t1'), { status: 'completed', completedAt: serverTimestamp(), reportedWatchedSeconds: 60 });
      await assertFails(b.commit());
    });

    it('rejects crediting task B while creating completion for task A', async () => {
      await seedReady();
      await h.seed(env, { 'tasks/t2': h.taskDoc() });
      const db = h.as(env, 'alice');
      await assertFails(runTransaction(db, async (tx) => {
        tx.set(doc(db, 'users/alice/completions/t1'), { taskId: 't1', reward: 10, completedAt: serverTimestamp() });
        tx.update(doc(db, 'users/alice'), { balance: 110, totalEarned: 110, completedTasksCount: 1, lastCompletionTaskId: 't2' });
        tx.set(doc(db, 'users/alice/transactions/task_t1'), {
          type: 'task_reward', amount: 10, balanceAfter: 110, refId: 't1', title: 'Video reward', createdAt: serverTimestamp(),
        });
      }));
    });

    it('completions are create-only and private', async () => {
      await seedReady();
      const db = h.as(env, 'alice');
      await assertSucceeds(h.completeTask(db, 'alice', 't1'));
      await assertFails(updateDoc(doc(db, 'users/alice/completions/t1'), { reward: 999 }));
      await assertSucceeds(getDocs(collection(db, 'users/alice/completions')));
      await h.seed(env, { 'users/bob': h.userDoc('bob') });
      await assertFails(getDocs(collection(h.as(env, 'bob'), 'users/alice/completions')));
    });
  });

  describe('ledger', () => {
    beforeEach(async () => { await seedReady(); });

    it('users cannot create arbitrary ledger rows', async () => {
      const db = h.as(env, 'alice');
      await assertFails(setDoc(doc(db, 'users/alice/transactions/ref_bob'), {
        type: 'referral_bonus', amount: 300, balanceAfter: 400, refId: 'bob', title: 'x', createdAt: serverTimestamp(),
      }));
      await assertFails(setDoc(doc(db, 'users/alice/transactions/task_t1'), {
        type: 'task_reward', amount: 10, balanceAfter: 100, refId: 't1', title: 'x', createdAt: serverTimestamp(),
      }));
    });

    it('ledger rows are immutable', async () => {
      const db = h.as(env, 'alice');
      await assertSucceeds(h.completeTask(db, 'alice', 't1'));
      await assertFails(updateDoc(doc(db, 'users/alice/transactions/task_t1'), { amount: 9999 }));
    });
  });
});
