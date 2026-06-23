import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

function getPrivateKey() {
  return process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n");
}

function getServiceAccount() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = getPrivateKey();
  const missingKeys = [
    ["FIREBASE_PROJECT_ID", projectId],
    ["FIREBASE_CLIENT_EMAIL", clientEmail],
    ["FIREBASE_PRIVATE_KEY", privateKey]
  ]
    .filter(([, value]) => !value)
    .map(([key]) => key);

  if (missingKeys.length > 0) {
    throw new Error(
      `Firebase Admin is not configured. Add ${missingKeys.join(
        ", "
      )} to Dashboard/.env.local.`
    );
  }

  return {
    projectId,
    clientEmail,
    privateKey
  };
}

export function getAdminDb() {
  if (!getApps().length) {
    const serviceAccount = getServiceAccount();

    initializeApp({
      credential: cert(serviceAccount)
    });
  }

  return getFirestore();
}
