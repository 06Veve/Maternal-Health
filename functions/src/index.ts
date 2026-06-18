import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {setGlobalOptions} from "firebase-functions/v2";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {randomBytes} from "node:crypto";

initializeApp();
setGlobalOptions({maxInstances: 10, region: "europe-west1"});

const db = getFirestore();
const geminiApiKey = defineSecret("GEMINI_API_KEY");
const geminiEndpoint =
  "https://generativelanguage.googleapis.com/v1beta/models/" +
  "gemini-2.0-flash:generateContent";

type GeminiPayload = {
  candidates?: Array<{
    content?: {parts?: Array<{text?: string}>};
  }>;
};

export const createPartnerInvite = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Authentication required.");

  const userSnap = await db.doc(`users/${uid}`).get();
  const user = userSnap.data();
  if (user?.role !== "mother" || !user.householdId) {
    throw new HttpsError(
      "permission-denied",
      "Only a mother account can invite a partner.",
    );
  }

  const householdRef = db.doc(`households/${user.householdId}`);
  const household = (await householdRef.get()).data();
  if (household?.partnerId) {
    throw new HttpsError("already-exists", "A partner is already linked.");
  }

  const code = randomBytes(4).toString("hex").toUpperCase();
  await db.doc(`partnerInvites/${code}`).set({
    householdId: user.householdId,
    motherId: uid,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
  });
  return {code};
});

export const acceptPartnerInvite = onCall(async (request) => {
  const uid = request.auth?.uid;
  const code = String(request.data?.code ?? "").trim().toUpperCase();
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  if (!code) {
    throw new HttpsError("invalid-argument", "Invitation code required.");
  }

  const inviteRef = db.doc(`partnerInvites/${code}`);
  await db.runTransaction(async (transaction) => {
    const inviteSnap = await transaction.get(inviteRef);
    const invite = inviteSnap.data();
    if (!invite || invite.status !== "pending") {
      throw new HttpsError("not-found", "Invitation invalid or already used.");
    }
    if (invite.expiresAt.toDate().getTime() < Date.now()) {
      throw new HttpsError("deadline-exceeded", "Invitation expired.");
    }

    const householdRef = db.doc(`households/${invite.householdId}`);
    const householdSnap = await transaction.get(householdRef);
    const household = householdSnap.data();
    if (!household || household.partnerId) {
      throw new HttpsError(
        "already-exists",
        "This family already has a partner.",
      );
    }

    transaction.set(db.doc(`users/${uid}`), {
      role: "partner",
      householdId: invite.householdId,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    transaction.update(householdRef, {
      partnerId: uid,
      memberIds: FieldValue.arrayUnion(uid),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(inviteRef, {
      status: "accepted",
      partnerId: uid,
      acceptedAt: FieldValue.serverTimestamp(),
    });
  });
  return {linked: true};
});

export const askMaternalAssistant = onCall(
  {secrets: [geminiApiKey]},
  async (request) => {
    const uid = request.auth?.uid;
    const prompt = String(request.data?.prompt ?? "").trim();
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    if (!prompt || prompt.length > 2000) {
      throw new HttpsError(
        "invalid-argument",
        "Message must contain 1 to 2000 characters.",
      );
    }

    const day = new Date().toISOString().slice(0, 10);
    const usageRef = db.doc(`users/${uid}/usage/${day}`);
    const remaining = await db.runTransaction(async (transaction) => {
      const usage = (await transaction.get(usageRef)).data();
      const count = Number(usage?.count ?? 0);
      if (count >= 10) {
        throw new HttpsError(
          "resource-exhausted",
          "Daily assistant limit reached.",
        );
      }
      transaction.set(usageRef, {
        count: count + 1,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      return 9 - count;
    });

    const user = (await db.doc(`users/${uid}`).get()).data();
    let week = 0;
    if (user?.householdId) {
      const householdSnap = await db
        .doc(`households/${user.householdId}`)
        .get();
      const household = householdSnap.data();
      const pregnancy = household?.pregnancy;
      if (pregnancy?.referenceDate) {
        const elapsedMs = Date.now() -
        pregnancy.referenceDate.toDate().getTime();
        const elapsed = Math.floor(elapsedMs / 604800000);
        const initialWeek = Number(pregnancy.gestationalAgeWeeks ?? 0);
        week = Math.max(0, Math.min(42, initialWeek + elapsed));
      }
    }

    const system = [
      "You are Bebezen, a maternal-health education assistant.",
      `The user is at pregnancy week ${week}.`,
      "Give concise, compassionate, evidence-aligned information.",
      "Never diagnose or prescribe. Identify urgent warning signs and " +
      "recommend professional care.",
      "Answer in the same language as the user.",
    ].join(" ");
    const response = await fetch(
      `${geminiEndpoint}?key=${geminiApiKey.value()}`,
      {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({
          contents: [{
            role: "user",
            parts: [{text: `${system}\n\nUser: ${prompt}`}],
          }],
          generationConfig: {temperature: 0.35, maxOutputTokens: 700},
        }),
      },
    );
    if (!response.ok) {
      throw new HttpsError("internal", "Assistant service unavailable.");
    }
    const payload = await response.json() as GeminiPayload;
    const text = payload.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    if (!text) {
      throw new HttpsError(
        "internal",
        "No assistant response was generated.",
      );
    }
    return {text, remaining};
  },
);
