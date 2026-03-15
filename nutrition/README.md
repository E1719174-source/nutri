# Nutrition App (iOS)

This is a comprehensive diet tracking and health management iOS application built with SwiftUI, following the requirements provided.

## Features Implemented

### 1. Daily Diet Record
- **Meal Tracking**: Breakfast, Lunch, Dinner, Snack classification.
- **Food Details**: Detailed nutritional info (Calories, Protein, Fat, Carbs).
- **Progress Tracking**: Visual progress bars for daily calorie and macro goals.
- **Water Tracker**: Quick add (+200ml) and daily goal tracking.

### 2. Food Management
- **Search**: Local database search first, falling back to Mock API (simulating Silicon Flow).
- **Add Food**: Custom amount input with unit support (gram, piece, etc.).
- **Local Storage**: Data persistence using JSON with encryption support.

### 3. AI Health Consultant
- **Chat Interface**: Interactive chat with AI context (30 days history).
- **Mock Integration**: Simulated DeepSeek LLM response via Silicon Flow API structure.

### 4. User Profile & Analysis
- **Profile Management**: Height, Weight, Gender, Activity Level, Goal.
- **TDEE Calculation**: Automatic calculation of daily calorie and macro targets based on Mifflin-St Jeor equation.
- **Data Security**: User data encryption at rest using AES.GCM (mock key for demo).

## Project Structure

- `Sources/Models`: Data models (Food, User, DailyRecord).
- `Sources/Views`: SwiftUI views (MainTabView, DailyDietView, etc.).
- `Sources/ViewModels`: Business logic (DietViewModel, UserViewModel, AIViewModel).
- `Sources/Services`: Data persistence and API services.
- `Sources/Helpers`: Security and utility helpers.

## Note on Technology Stack

The project is implemented in **SwiftUI** (native iOS) instead of Flutter, as the environment was initialized as a Swift project and a Swift file was opened. This ensures best performance and native integration with iOS features.

## Requirements Coverage

- [x] Daily Diet Record (Meals, Nutrition, Water)
- [x] Food Search & Add (Local + API Mock)
- [x] AI Consultant (Chat UI, Context)
- [x] Personal Info & TDEE (Profile, Goals)
- [x] Data Security (Encryption at rest)
- [x] Offline Availability (Local storage first)

## How to Run

1. Open the project in Xcode.
2. Build and run on Simulator or Device (iOS 15+ recommended).
