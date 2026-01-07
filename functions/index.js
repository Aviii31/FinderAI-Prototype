// Modified: functions/index.js
import { onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore"; // <--- ADDED THIS
import { defineSecret } from "firebase-functions/params";
import admin from "firebase-admin";
import { GoogleGenerativeAI } from "@google/generative-ai";

admin.initializeApp();
const bucket = admin.storage().bucket();
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

async function downloadImageBuffer(imageUrl) {
  const decodedUrl = decodeURIComponent(imageUrl);
  const match = decodedUrl.match(/\/o\/(.*?)\?/);
  if (!match) throw new Error("Invalid imageUrl format");
  
  const filePath = decodeURIComponent(match[1]);
  const file = bucket.file(filePath);
  const [buffer] = await file.download();
  return buffer;
}

// ================== IMAGE → DESCRIPTION ==================
export const getImageDescription = onRequest(
  { cors: true, timeoutSeconds: 120, secrets: [GEMINI_API_KEY] },
  async (req, res) => {
    try {
      const { imageUrl } = req.body;
      if (!imageUrl) return res.status(400).json({ error: "imageUrl is required" });

      const buffer = await downloadImageBuffer(imageUrl);
      const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
      
      const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" }); 

      const result = await model.generateContent([
        { inlineData: { mimeType: "image/jpeg", data: buffer.toString("base64") } },
        "Describe this item in detail for a lost-and-found database. Include color, type, brand, unique features, and condition.",
      ]);

      return res.json({ description: result.response.text() });
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  }
);

// ================== TEXT → EMBEDDING ==================
export const getTextEmbedding = onRequest(
  { cors: true, timeoutSeconds: 60, secrets: [GEMINI_API_KEY] },
  async (req, res) => {
    try {
      const { text } = req.body;
      if (!text) return res.status(400).json({ error: "text is required" });

      const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
      const model = genAI.getGenerativeModel({ model: "text-embedding-004" });
      
      const result = await model.embedContent(text);
      return res.json({ embedding: result.embedding.values });
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  }
);

// ================== IMAGE → EMBEDDING ==================
export const getImageEmbedding = onRequest(
  { cors: true, timeoutSeconds: 120, secrets: [GEMINI_API_KEY] },
  async (req, res) => {
    try {
      const { imageUrl } = req.body;
      if (!imageUrl) return res.status(400).json({ error: "imageUrl is required" });

      const buffer = await downloadImageBuffer(imageUrl);
      const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());

      // Step 1: Get Description
      const visionModel = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
      const visionResult = await visionModel.generateContent([
        { inlineData: { mimeType: "image/jpeg", data: buffer.toString("base64") } },
        "Detailed description of this object for visual search matching. Focus on visual traits: color, shape, materials, text.",
      ]);
      const description = visionResult.response.text();

      // Step 2: Get Embedding
      const embeddingModel = genAI.getGenerativeModel({ model: "text-embedding-004" });
      const embeddingResult = await embeddingModel.embedContent(description);

      return res.json({ 
        embedding: embeddingResult.embedding.values,
        generatedDescription: description 
      });
    } catch (error) {
      console.error("Image embedding error:", error);
      return res.status(500).json({ error: error.message });
    }
  }
);

// ================== MATH HELPER ==================
function cosineSimilarity(vecA, vecB) {
  if (!vecA || !vecB || vecA.length !== vecB.length) return 0.0;
  
  let dot = 0.0;
  let normA = 0.0;
  let normB = 0.0;
  
  for (let i = 0; i < vecA.length; i++) {
    dot += vecA[i] * vecB[i];
    normA += vecA[i] * vecA[i];
    normB += vecB[i] * vecB[i];
  }
  
  if (normA === 0 || normB === 0) return 0.0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

// ================== DB TRIGGER: MATCH ALERTS ==================
// This runs whenever a NEW document is created in 'found_items'
export const checkMatchesOnUpload = onDocumentCreated("found_items/{itemId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    
    const foundItem = snapshot.data();
    const foundEmbedding = foundItem.embedding; 

    if (!foundEmbedding) return;

    const db = admin.firestore();
    
    try {
        // 1. Get all alerts
        const alertsSnap = await db.collection('lost_alerts').get();
        
        if (alertsSnap.empty) {
            console.log("No lost alerts to check.");
            return;
        }

        const emailsToSend = [];

        // 2. Check each alert
        alertsSnap.docs.forEach(doc => {
            const alert = doc.data();
            const lostEmbedding = alert.embedding;

            if (lostEmbedding) {
                const similarity = cosineSimilarity(foundEmbedding, lostEmbedding);
                
                // 3. Match Threshold (> 60%)
                if (similarity > 0.60) {
                    console.log(`Match found for ${alert.email}: ${(similarity * 100).toFixed(1)}%`);
                    
                    // 4. Queue Email (Trigger Email Extension)
                    const emailPromise = db.collection('mail').add({
                        to: alert.email,
                        message: {
                            subject: 'We found a potential match for your lost item!',
                            html: `
                                <div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f9f9f9; border-radius: 10px;">
                                    <h2 style="color: #2563EB;">Finder AI Match Alert</h2>
                                    <p>Good news! An item was just uploaded that matches the description of what you lost.</p>
                                    
                                    <div style="background-color: white; padding: 15px; border-radius: 8px; border: 1px solid #ddd; margin: 20px 0;">
                                        <p><strong>Your Search:</strong> "${alert.description}"</p>
                                        <p><strong>Match Confidence:</strong> <span style="color: #10B981; font-weight: bold;">${(similarity * 100).toFixed(0)}%</span></p>
                                    </div>

                                    <p><strong>Item Description:</strong> ${foundItem.description}</p>
                                    
                                    ${foundItem.imageUrl ? `<img src="${foundItem.imageUrl}" width="300" style="border-radius: 8px; margin-top: 10px;" />` : ''}
                                    
                                    <br/><br/>
                                    <p>Check the App for more details.</p>
                                </div>
                            `
                        }
                    });
                    
                    emailsToSend.push(emailPromise);
                }
            }
        });

        await Promise.all(emailsToSend);
        console.log(`Processed matches. Queued ${emailsToSend.length} emails.`);

    } catch (error) {
        console.error("Error checking matches:", error);
    }
});