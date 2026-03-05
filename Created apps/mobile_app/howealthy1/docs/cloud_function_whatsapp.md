# WhatsApp Business API — Cloud Function Integrations

> **File:** `docs/cloud_function_whatsapp.md`
> **Owner:** VP Engineering / VP Growth

## Overview
The client-side `WhatsAppBotService` in the Flutter app format messages and generates URLs for the user to send messages *from their own phone* (`https://wa.me/...`). 

To fully automate the daily 9 PM summaries from a central bot number, a Firebase Cloud Function must act as the backend to the WhatsApp Business API (Meta Graph API).

## Why not put the API keys in the app?
Putting a WhatsApp Business API Bearer Token in the Flutter app would allow malicious users to extract the token and send spam messages on behalf of the company, resulting in immediate suspension from Meta.

## Implementation Steps (Backend)

1. **Set up Meta Developer Account:**
   - Create an app, add the WhatsApp product
   - Register a business phone number
   - Create a message template (`daily_summary_text`) and get it approved by Meta

2. **Cloud Function Setup (`functions/index.js`):**
   ```javascript
   const functions = require('firebase-functions');
   const admin = require('firebase-admin');
   const axios = require('axios');
   admin.initializeApp();

   const WHATSAPP_TOKEN = functions.config().whatsapp.token;
   const PHONE_NUMBER_ID = functions.config().whatsapp.phone_id;

   exports.sendDailyWhatsAppSummaries = functions.pubsub
     .schedule('0 21 * * *') // 9:00 PM Daily
     .timeZone('Asia/Kolkata')
     .onRun(async (context) => {
       const usersRef = admin.firestore().collection('users');
       const snapshot = await usersRef.where('whatsappOptIn.enabled', '==', true).get();

       for (const doc of snapshot.docs) {
         const uid = doc.id;
         const userData = doc.data();
         const phone = userData.whatsappOptIn.phoneNumber;

         // Generate summary (Server-side equivalent of WhatsAppBotService.generateDailySummary)
         const summary = await generateSummaryForUser(uid);
         
         // Send via WhatsApp API
         await axios.post(
           `https://graph.facebook.com/v17.0/${PHONE_NUMBER_ID}/messages`,
           {
             messaging_product: "whatsapp",
             to: phone,
             type: "text",
             text: {
               body: summary
             }
           },
           {
             headers: { Authorization: `Bearer ${WHATSAPP_TOKEN}` }
           }
         );
       }
     });
   ```

3. **Required Environment Config:**
   ```bash
   firebase functions:config:set whatsapp.token="EAAX..." whatsapp.phone_id="123456789"
   ```

## Next Steps
This backend integration will be prioritized in **Sprint 4** after core Q1 features (Net Worth, Mutual Funds, FIRE Calculator) are released to production. Currently, the app relies on the client-side `wa.me` deep link share action which works effectively for the MVP.
