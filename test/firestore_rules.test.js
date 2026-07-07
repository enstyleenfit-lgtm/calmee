const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc } = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'calmee-8011c';
const USER_UID = 'user-alice';
const OTHER_UID = 'user-bob';
const TRAINER_UID = 'trainer-t1';
const OTHER_TRAINER_UID = 'trainer-t2';

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

async function linkTrainer(userUid, trainerUid) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(
      doc(ctx.firestore(), `trainers/${trainerUid}/customers/${userUid}`),
      { linked: true }
    );
  });
}

// ── C: habits ──────────────────────────────────────────────────────
describe('users/{uid}/habits', () => {
  it('C-1: 本人は read/write できる', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `users/${USER_UID}/habits/h1`), { done: true }));
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/habits/h1`)));
  });

  it('C-2: 他ユーザーは read/write できない', async () => {
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    await assertFails(setDoc(doc(db, `users/${USER_UID}/habits/h1`), { done: true }));
    await assertFails(getDoc(doc(db, `users/${USER_UID}/habits/h1`)));
  });

  it('C-3: 未認証は read/write できない', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(setDoc(doc(db, `users/${USER_UID}/habits/h1`), { done: true }));
    await assertFails(getDoc(doc(db, `users/${USER_UID}/habits/h1`)));
  });
});

// ── C: mealLogs ────────────────────────────────────────────────────
describe('users/{uid}/mealLogs', () => {
  it('C-4: 本人は read/write できる', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `users/${USER_UID}/mealLogs/m1`), { kcal: 500 }));
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/mealLogs/m1`)));
  });

  it('C-5: 紐づきトレーナーは read できる', async () => {
    await linkTrainer(USER_UID, TRAINER_UID);
    const db = testEnv.authenticatedContext(TRAINER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/mealLogs/m1`)));
  });

  it('C-6: 紐づきトレーナーは write できない', async () => {
    await linkTrainer(USER_UID, TRAINER_UID);
    const db = testEnv.authenticatedContext(TRAINER_UID).firestore();
    await assertFails(setDoc(doc(db, `users/${USER_UID}/mealLogs/m1`), { kcal: 500 }));
  });

  it('C-7: 無関係トレーナーは read できない', async () => {
    const db = testEnv.authenticatedContext(OTHER_TRAINER_UID).firestore();
    await assertFails(getDoc(doc(db, `users/${USER_UID}/mealLogs/m1`)));
  });
});

// ── U: trainerMessages ─────────────────────────────────────────────
describe('users/{uid}/trainerMessages', () => {
  it('U-1: 本人（顧客）は read できる', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/trainerMessages/msg1`)));
  });

  it('U-2: 本人（顧客）は create できない', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(setDoc(doc(db, `users/${USER_UID}/trainerMessages/msg1`), { text: 'hi' }));
  });

  it('U-3: 紐づきトレーナーは read + create できる', async () => {
    await linkTrainer(USER_UID, TRAINER_UID);
    const db = testEnv.authenticatedContext(TRAINER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `users/${USER_UID}/trainerMessages/msg1`), { text: 'hi' }));
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/trainerMessages/msg1`)));
  });

  it('U-4: 無関係トレーナーは read/write できない', async () => {
    const db = testEnv.authenticatedContext(OTHER_TRAINER_UID).firestore();
    await assertFails(getDoc(doc(db, `users/${USER_UID}/trainerMessages/msg1`)));
    await assertFails(setDoc(doc(db, `users/${USER_UID}/trainerMessages/msg1`), { text: 'hi' }));
  });
});

// ── N: sharedNotes ─────────────────────────────────────────────────
describe('users/{uid}/sharedNotes', () => {
  it('N-1: 本人（顧客）は read できる', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/sharedNotes/n1`)));
  });

  it('N-2: 本人（顧客）は write できない', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(setDoc(doc(db, `users/${USER_UID}/sharedNotes/n1`), { title: 'test', body: 'hi' }));
  });

  it('N-3: 紐づきトレーナーは read + write できる', async () => {
    await linkTrainer(USER_UID, TRAINER_UID);
    const db = testEnv.authenticatedContext(TRAINER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `users/${USER_UID}/sharedNotes/n1`), { title: 'test', body: 'hi' }));
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/sharedNotes/n1`)));
  });

  it('N-4: 無関係トレーナーは read/write できない', async () => {
    const db = testEnv.authenticatedContext(OTHER_TRAINER_UID).firestore();
    await assertFails(getDoc(doc(db, `users/${USER_UID}/sharedNotes/n1`)));
    await assertFails(setDoc(doc(db, `users/${USER_UID}/sharedNotes/n1`), { title: 'test', body: 'hi' }));
  });

  it('N-5: 未認証は read/write できない', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, `users/${USER_UID}/sharedNotes/n1`)));
    await assertFails(setDoc(doc(db, `users/${USER_UID}/sharedNotes/n1`), { title: 'test', body: 'hi' }));
  });

  it('N-6: 他の顧客は read/write できない', async () => {
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    await assertFails(getDoc(doc(db, `users/${USER_UID}/sharedNotes/n1`)));
    await assertFails(setDoc(doc(db, `users/${USER_UID}/sharedNotes/n1`), { title: 'test', body: 'hi' }));
  });
});

// ── K: karteProfile ───────────────────────────────────────────────
describe('users/{uid}/karteProfile', () => {
  it('K-1: 担当トレーナーは karteProfile を read/write できる', async () => {
    await linkTrainer(USER_UID, TRAINER_UID);
    const db = testEnv.authenticatedContext(TRAINER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `users/${USER_UID}/karteProfile/data`), { basicInfo: {} }));
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/karteProfile/data`)));
  });

  it('K-2: 顧客は karteProfile を read できる', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/karteProfile/data`)));
  });

  it('K-3: 顧客は karteProfile を write できない', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(setDoc(doc(db, `users/${USER_UID}/karteProfile/data`), { basicInfo: {} }));
  });

  it('K-4: 無関係トレーナーは karteProfile を read/write できない', async () => {
    const db = testEnv.authenticatedContext(OTHER_TRAINER_UID).firestore();
    await assertFails(getDoc(doc(db, `users/${USER_UID}/karteProfile/data`)));
    await assertFails(setDoc(doc(db, `users/${USER_UID}/karteProfile/data`), { basicInfo: {} }));
  });
});

// ── K: kartePrivate ───────────────────────────────────────────────
describe('users/{uid}/kartePrivate', () => {
  it('K-5: 担当トレーナーは kartePrivate を read/write できる', async () => {
    await linkTrainer(USER_UID, TRAINER_UID);
    const db = testEnv.authenticatedContext(TRAINER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `users/${USER_UID}/kartePrivate/data`), { currentChallenges: 'test' }));
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/kartePrivate/data`)));
  });

  it('K-6: 顧客は kartePrivate を read できない', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(getDoc(doc(db, `users/${USER_UID}/kartePrivate/data`)));
  });

  it('K-7: 無関係トレーナーは kartePrivate を read/write できない', async () => {
    const db = testEnv.authenticatedContext(OTHER_TRAINER_UID).firestore();
    await assertFails(getDoc(doc(db, `users/${USER_UID}/kartePrivate/data`)));
    await assertFails(setDoc(doc(db, `users/${USER_UID}/kartePrivate/data`), { currentChallenges: 'test' }));
  });
});

// ── T: trainers/customers ──────────────────────────────────────────
describe('trainers/{trainerUid}/customers', () => {
  it('T-1: 本人トレーナーは read/write できる', async () => {
    const db = testEnv.authenticatedContext(TRAINER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `trainers/${TRAINER_UID}/customers/${USER_UID}`), { linked: true }));
    await assertSucceeds(getDoc(doc(db, `trainers/${TRAINER_UID}/customers/${USER_UID}`)));
  });

  it('T-2: 別トレーナーは read/write できない', async () => {
    const db = testEnv.authenticatedContext(OTHER_TRAINER_UID).firestore();
    await assertFails(setDoc(doc(db, `trainers/${TRAINER_UID}/customers/${USER_UID}`), { linked: true }));
    await assertFails(getDoc(doc(db, `trainers/${TRAINER_UID}/customers/${USER_UID}`)));
  });
});

// ── X: profile ─────────────────────────────────────────────────────
describe('users/{uid}/profile', () => {
  it('X-1: 本人は read できる', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/profile/p1`)));
  });

  it('X-2: 本人は write できる（ロール自己選択）', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `users/${USER_UID}/profile/data`), { role: 'customer' }));
  });

  it('X-3: 他ユーザーは write できない', async () => {
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    await assertFails(setDoc(doc(db, `users/${USER_UID}/profile/data`), { role: 'trainer' }));
  });
});

// ── E: exerciseLogs ────────────────────────────────────────────────
describe('users/{uid}/exerciseLogs', () => {
  it('E-1: 本人は read/write できる', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `users/${USER_UID}/exerciseLogs/e1`), { minutes: 30 }));
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/exerciseLogs/e1`)));
  });

  it('E-2: 紐づきトレーナーは read できる', async () => {
    await linkTrainer(USER_UID, TRAINER_UID);
    const db = testEnv.authenticatedContext(TRAINER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/exerciseLogs/e1`)));
  });

  it('E-3: 紐づきトレーナーは write できない', async () => {
    await linkTrainer(USER_UID, TRAINER_UID);
    const db = testEnv.authenticatedContext(TRAINER_UID).firestore();
    await assertFails(setDoc(doc(db, `users/${USER_UID}/exerciseLogs/e1`), { minutes: 30 }));
  });
});

// ── W: weightLogs ──────────────────────────────────────────────────
describe('users/{uid}/weightLogs', () => {
  it('W-1: 本人は read/write できる', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `users/${USER_UID}/weightLogs/w1`), { kg: 60 }));
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/weightLogs/w1`)));
  });

  it('W-2: 紐づきトレーナーは read できる', async () => {
    await linkTrainer(USER_UID, TRAINER_UID);
    const db = testEnv.authenticatedContext(TRAINER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/weightLogs/w1`)));
  });

  it('W-3: 紐づきトレーナーは write できない', async () => {
    await linkTrainer(USER_UID, TRAINER_UID);
    const db = testEnv.authenticatedContext(TRAINER_UID).firestore();
    await assertFails(setDoc(doc(db, `users/${USER_UID}/weightLogs/w1`), { kg: 60 }));
  });
});

// ── S: settings ────────────────────────────────────────────────────
describe('users/{uid}/settings', () => {
  it('S-1: 本人は read/write できる', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `users/${USER_UID}/settings/goals`), { calories: 2000 }));
    await assertSucceeds(getDoc(doc(db, `users/${USER_UID}/settings/goals`)));
  });

  it('S-2: 他ユーザーは read できない', async () => {
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    await assertFails(getDoc(doc(db, `users/${USER_UID}/settings/goals`)));
  });

  it('S-3: 他ユーザーは write できない', async () => {
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    await assertFails(setDoc(doc(db, `users/${USER_UID}/settings/goals`), { calories: 2000 }));
  });
});
