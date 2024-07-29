/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import fetch from "node-fetch";
import cors from "cors";
//const cors = require("cors");

admin.initializeApp();

const corsHandler = cors({ origin: true });

export const proxyLeetCode = functions.https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    const { username } = req.body;
    const url = "https://leetcode.com/graphql";
    const headers = { "Content-Type": "application/json" };
    const query = {
      query: `
        {
          recentAcSubmissionList(username: "${username}", limit: 100) {
            id
            title
            titleSlug
            timestamp
          }
        }
      `,
    };

    try {
      const body = JSON.stringify(query);
      const response = await fetch(url, {
        method: "POST",
        headers: headers,
        body: body,
      });
      const data = await response.json();
      return res.json(data); // Ensure only one response is sent
    } catch (error) {
      return res.status(500).json({ error: error }); // Ensure only one response is sent
    }
  });
});