# 🧠 ScanIt – Minimal & Smart Grocery Tracker

ScanIt is a **Flutter-based** mobile and web application that helps users track pantry items, monitor expiry dates, reduce food waste, and manage grocery refills. It features a **clean monotone UI**, secure user authentication, usage stats, and smart suggestions – all backed by a **Node.js + MongoDB backend**.

---

## ✨ Features

### 🧾 Pantry & Item Tracking
- Add pantry items with name, quantity, and expiry date.
- Color-coded expiry tracking (green, orange, red).
- Mark items as **used** or **wasted**.

### 🕓 Expiry Management
- Auto-detect expired items and log them to history.
- Show dialog before removal with option to add to grocery list.

### 🛒 Grocery Refill System
- Smart refill prompts when quantity hits zero.
- Manual and automatic addition to grocery list.
- View/edit/delete grocery items easily.

### 📈 Usage Insights
- Track waste percentage.
- View items wasted recently or frequently.
- Visual breakdown by category & usage trends.

### 🤖 AI Chatbot
- Ask pantry-related questions (e.g. "What’s expiring soon?")
- Get refill suggestions when stock is low
- Minimal floating chat UI, theme-aware

### 🔐 User Authentication
- Secure registration & login (JWT-based).
- User info persisted with local session tokens.

### 🧑 Profile Management
- View and edit user name and email.
- Change password securely with old password confirmation.

### 🎨 Global Dark/Light Theme
- Toggle between clean light and dark modes.
- Fully consistent monotone UI across all screens.

---

## 🛠️ Tech Stack

| Layer     | Technology                          |
|-----------|-------------------------------------|
| Frontend  | Flutter (mobile/web), Provider      |
| Backend   | Node.js, Express.js, MongoDB        |
| Auth      | JWT Token                           |
| State     | Provider                            |
| Storage   | Shared Preferences (Flutter)        |

---

## 📦 Folder Structure

lib/

├── screens/

├── services/

├── providers/

├── widgets/

├── models/

└── main.dart 

---

## 🚀 Getting Started

### 🧩 Prerequisites
- Flutter 3.x
- Node.js 18+
- MongoDB instance (Atlas/local)

---

### 🔧 Backend Setup

 - git clone https://github.com/AnshX01/ScanIt-App.git

 - cd ScanIt-App/scanit-backend

 - npm install

 - npm start

 - Create a .env file:
     - PORT=5000
     - MONGO_URI=your_mongodb_connection_string
     - JWT_SECRET=your_secret_key


### 📱 Flutter Setup
cd ../

flutter pub get

flutter run


Update API base URL in lib/services/api_service.dart if needed:

const String baseUrl = 'http://localhost:5000';


### 🔐 User Flow
 - Register/Login with email & password.

 - Add items to your pantry and set expiry dates.

 - Track and manage items as they approach expiry.

 - View smart suggestions and history of used/wasted items.

 - Use grocery list to plan refills easily.

 - View insights in the Stats screen.

 - Edit your profile and change your password securely.

