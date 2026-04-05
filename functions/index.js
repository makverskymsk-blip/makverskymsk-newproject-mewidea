const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Scheduled function: runs on the 25th of every month at 10:00 UTC.
 * Calculates subscription cost per player and creates transactions.
 */
exports.calculateSubscriptions = functions.pubsub
  .schedule("0 10 25 * *")
  .timeZone("Europe/Moscow")
  .onRun(async (context) => {
    console.log("Calculating subscriptions...");

    const communitiesSnap = await db.collection("communities").get();

    for (const communityDoc of communitiesSnap.docs) {
      const community = communityDoc.data();
      const communityId = communityDoc.id;
      const monthlyRent = community.monthlyRent || 100000;

      const now = new Date();
      const month = now.getMonth() + 1;
      const year = now.getFullYear();

      // Find current month subscription
      const subsSnap = await db
        .collection("communities")
        .doc(communityId)
        .collection("subscriptions")
        .where("month", "==", month)
        .where("year", "==", year)
        .limit(1)
        .get();

      if (subsSnap.empty) {
        console.log(`No subscription found for ${communityId} ${month}/${year}`);
        continue;
      }

      const subDoc = subsSnap.docs[0];
      const sub = subDoc.data();
      const entries = sub.entries || [];

      if (entries.length === 0) {
        console.log(`No entries for ${communityId}`);
        continue;
      }

      const perPlayer = monthlyRent / entries.length;
      console.log(
        `${communityId}: ${entries.length} players, ${perPlayer} per player`
      );

      // Update each entry with calculated amount
      const updatedEntries = entries.map((entry) => ({
        ...entry,
        calculatedAmount: perPlayer,
        paymentStatus: "pending",
      }));

      await subDoc.ref.update({
        entries: updatedEntries,
        isCalculated: true,
        calculationDate: admin.firestore.FieldValue.serverTimestamp(),
        paymentDeadline: new Date(year, month - 1, 30), // 30th of the month
      });

      // Create transactions for each player
      const batch = db.batch();
      for (const entry of entries) {
        const txRef = db
          .collection("communities")
          .doc(communityId)
          .collection("transactions")
          .doc();

        batch.set(txRef, {
          userId: entry.userId,
          type: 2, // subscriptionPayment
          amount: perPlayer,
          status: 0, // pending
          description: `Абонемент ${month}/${year} — ${perPlayer.toFixed(0)} ₽`,
          dateTime: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Send push notification to community
      try {
        await admin.messaging().sendToTopic(`community_${communityId}`, {
          notification: {
            title: "Расчёт абонемента",
            body: `Сумма: ${perPlayer.toFixed(0)} ₽. Оплатите до 30-го числа.`,
          },
          data: {
            type: "subscription_calculated",
            communityId: communityId,
            amount: perPlayer.toString(),
          },
        });
      } catch (err) {
        console.error("FCM Send Error:", err);
      }
    }

    console.log("Subscription calculation complete.");
    return null;
  });

/**
 * Trigger: when a new match is created, notify community members.
 */
exports.onMatchCreated = functions.firestore
  .document("communities/{communityId}/matches/{matchId}")
  .onCreate(async (snap, context) => {
    const match = snap.data();
    const communityId = context.params.communityId;

    const communityDoc = await db
      .collection("communities")
      .doc(communityId)
      .get();
    const communityName = communityDoc.data()?.name || "Сообщество";

    try {
      await admin.messaging().sendToTopic(`community_${communityId}`, {
        notification: {
          title: `${communityName}: Новая игра!`,
          body: `${match.format} — ${match.location}`,
        },
        data: {
          type: "new_match",
          communityId: communityId,
          matchId: context.params.matchId,
        },
      });
    } catch (err) {
      console.error("FCM Error:", err);
    }
  });

/**
 * Trigger: remind about unpaid subscriptions on the 28th.
 */
exports.remindSubscriptions = functions.pubsub
  .schedule("0 10 28 * *")
  .timeZone("Europe/Moscow")
  .onRun(async (context) => {
    console.log("Sending subscription reminders...");

    const communitiesSnap = await db.collection("communities").get();
    const now = new Date();
    const month = now.getMonth() + 1;
    const year = now.getFullYear();

    for (const communityDoc of communitiesSnap.docs) {
      const communityId = communityDoc.id;

      const subsSnap = await db
        .collection("communities")
        .doc(communityId)
        .collection("subscriptions")
        .where("month", "==", month)
        .where("year", "==", year)
        .where("isCalculated", "==", true)
        .limit(1)
        .get();

      if (subsSnap.empty) continue;

      const sub = subsSnap.docs[0].data();
      const unpaid = (sub.entries || []).filter(
        (e) => e.paymentStatus === "pending" || e.paymentStatus === "notPaid"
      );

      if (unpaid.length === 0) continue;

      try {
        await admin.messaging().sendToTopic(`community_${communityId}`, {
          notification: {
            title: "Напоминание об оплате!",
            body: `${unpaid.length} чел. ещё не оплатили абонемент. Дедлайн — 30-е число.`,
          },
        });
      } catch (err) {
        console.error("FCM Error:", err);
      }
    }

    return null;
  });
