# 🔍 Finder AI

**Lost. Found. Reconnected.**

> An intelligent, AI-powered Lost & Found application that uses computer vision and semantic vector search to reconnect people with their lost belongings.

![Finder AI Banner](https://via.placeholder.com/1000x300?text=Finder+AI+Banner+Placeholder) 
---

## 🚀 Overview

Traditional Lost & Found systems rely on keyword searching (e.g., searching for "black bag"), which often fails due to vague descriptions. 

**Finder AI** solves this by using **Google Gemini (Vertex AI)** to generate **multimodal embeddings** for images and text. This allows the app to "understand" what an item looks like and match it conceptually, even if the descriptions don't match perfectly.

### 🌟 Key Features

* **🧠 AI-Powered Matching:** Uses Google Gemini embeddings to match lost items (text or image) with found items.
* **📍 Visual Map Interface:** interactive Google Map showing real-time locations of found items nearby.
* **📸 Smart Scanning:** When a user uploads a photo of a found item, the AI automatically generates a description and tags.
* **🔔 Intelligent Alerts:** If no match is found immediately, users can set a "Notify Me" alert. The system continues to search in the background and notifies the user when a similar item appears.
* **🛡️ Secure Recovery:** "I have recovered this" flow to verify ownership and clean up the database.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart) - Android, iOS, Web
* **Backend:** Firebase (Firestore, Authentication, Storage)
* **AI & ML:** * **Google Vertex AI (Gemini Pro Vision):** For image captioning and embedding generation.
    * **Vector Search:** Custom cosine similarity algorithm to match embeddings.
* **Maps:** Google Maps Flutter SDK
* **Serverless:** Firebase Cloud Functions (Node.js)

---

## 📸 Screenshots

| Home Screen | Lost Item Search | Found Item Report | AI Match Results |
|:---:|:---:|:---:|:---:|
| <img src="docs/home.png" width="200"> | <img src="docs/lost.png" width="200"> | <img src="docs/found.png" width="200"> | <img src="docs/results.png" width="200"> |

---

## ⚙️ How It Works (The AI Flow)

1.  **Reporting a Found Item:**
    * User uploads an image.
    * Gemini AI analyzes the image and generates a text description.
    * An **embedding vector (768 dimensions)** is created and stored in Firestore.

2.  **Searching for a Lost Item:**
    * User describes the lost item or uploads a reference image.
    * The app converts this query into a vector embedding.
    * We perform a **Cosine Similarity Search** against the database of found items.
    * Items with a similarity score > 75% are shown as matches.

---

## 💻 Installation & Setup

To run this project locally:

### Prerequisites
* Flutter SDK installed
* Google Cloud Project with Vertex AI enabled
* Google Maps API Key

### Steps
1.  **Clone the repo**
    ```bash
    git clone [https://github.com/Aviii31/FinderAI-Prototype.git](https://github.com/Aviii31/FinderAI-Prototype.git)
    cd FinderAI-Prototype
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    cd ios && pod install && cd ..
    ```

3.  **Configure Firebase**
    * This project uses `flutter_config`. You may need to provide your own `firebase_options.dart` if you want to connect to your own backend.

4.  **Run the App**
    ```bash
    flutter run
    ```

---

## ⚠️ Note on API Keys

For security reasons, API keys (Google Maps, Firebase) have been restricted or removed from this public repository. If you are a judge or developer trying to run this:
* Please contact the maintainer for a test build.
* Or, add your own keys in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`.
* Incase found using, you may face charger under INDIAN PENAL CODE.
---

## 👥 Contributors

* **Avanish L Gowda** - [GitHub](https://github.com/Aviii31)
* *Add your teammates here!*

---
