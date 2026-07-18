# Nivetha123 - Job Matching Platform

A modern, high-performance Flutter mobile application that seamlessly connects **Job Providers** and **Workers** in real-time. Built with Firebase and integrated with Google Maps for location-based job discovery, this platform offers a streamlined, role-based user experience.

---

## 📌 Table of Contents
1. [Project Purpose](#-project-purpose)
2. [Key Features](#-key-features)
   - [For Workers](#for-workers)
   - [For Job Providers](#for-job-providers)
3. [Architecture & Folder Structure](#-architecture--folder-structure)
4. [Tech Stack & Dependencies](#-tech-stack--dependencies)
5. [Getting Started & Setup](#-getting-started--setup)
6. [Firestore Database Schema](#-firestore-database-schema)

---

## 🎯 Project Purpose

The primary goal of **Nivetha123** is to bridge the gap between local job providers and job seekers (workers). It simplifies:
* **Discoverability:** Workers can locate jobs in their city or surrounding areas using visual Google Map overlays and routes.
* **Onboarding:** A clean, multi-step profile builder gathers relevant experience, category/role details, contact information, and address info.
* **Streamlined Hiring:** Providers can easily post jobs with image uploads and descriptions, receive incoming applications, and accept or reject candidates with a single tap.

---

## 🛠️ Key Features

### For Workers
* **Onboarding & Profiling:** Interactive onboarding flow that builds a detailed profile (Role, Experience, Skill Area, Contact details, Profile image).
* **Job Discovery:** Filterable job feed allowing workers to view opportunities in specific cities.
* **Google Maps Integration:** Locate job providers on a map, view the real-time distance, and plot routes with polyline routing points.
* **Application Tracking:** Submit applications to jobs and track their status in real-time (Applied, Accepted, Rejected).

### For Job Providers
* **Job Posting:** Submit new job listings (Orders) with description text and photos. Photos are automatically compressed locally to optimize performance.
* **Applicant Review:** View detailed profiles of workers who have applied for posted jobs.
* **Status Updates:** Approve or decline candidates, instantly updating the worker's application status.
* **Messaging Portal:** Seamless communication dashboard to message candidates.

---

## 📂 Architecture & Folder Structure

The project follows a clean feature-based structure within the `lib/` directory:

```
lib/
├── authendication/
│   └── authentication.dart        # Core Firebase Auth operations (Sign Up, Log In, Sign Out)
├── login/
│   ├── Login.dart                 # Main User login interface & role routing logic
│   ├── signup.dart                # Account creation screen (Email & Password entry)
│   └── forgot_password.dart       # Password recovery & reset screen
├── Pages/
│   ├── Backcontroll.dart          # Back-button navigation controls & confirmation popups
│   ├── applications.dart          # Job provider dashboard to manage applications (Accept/Reject)
│   ├── form_page.dart             # Job posting wizard (image attachment, compression, description)
│   ├── job_status_page.dart       # Job status tracking dashboard for workers
│   ├── jobproviderpage.dart       # Home/Shell page for Job Providers (Drawer, Bottom Navigation)
│   ├── map_pages.dart             # Google Map display, Haversine distance, and directions polyline
│   ├── messages.dart              # Messaging/Inbox component
│   ├── order_details.dart         # Posted jobs list for the job provider
│   ├── profile_details_page.dart  # User profile view details screen
│   ├── workerpage.dart            # Home/Shell page for Workers (Feed, Drawer, City filter)
│   └── workerpagesubfolder/
│       ├── contentviewer.dart     # Sub-widget displaying the list of active job posts for workers
│       ├── workerjobprovider.dart # Data model representing a Job Provider
│       └── workerpost.dart        # Data model representing a Posted Job (Order)
├── screens/
│   ├── checkbox_animation_page.dart # Step 1: Account role selection (Worker or Job Provider)
│   ├── personal_details.dart       # Step 2: Personal details input (Gender, DOB)
│   ├── contact_details.dart        # Step 3: Contact & Address details input (City dropdown)
│   ├── name_job.dart               # Step 4: Name, job title, and experience input
│   ├── profile_details.dart        # Step 5: User profile photo upload/selection
│   ├── summary.dart                # Step 6: Registration details overview and final submit
│   └── user_data.dart              # Data model representing full user profiles (JSON serialization)
├── widgets/
│   └── step_progress.dart          # Multi-step progress indicator widget for onboarding
└── main.dart                       # App entrance, Firebase initialization, global state entry
```

---

## 📦 Tech Stack & Dependencies

The dependencies declared in `pubspec.yaml` are selected to build a robust, scalable, and responsive application. Below is a detailed breakdown of the libraries and why they are used:

| Dependency | Purpose / Why it is used |
| :--- | :--- |
| **`firebase_core`** | Initialized in `main.dart` to establish the connection with Firebase services. |
| **`firebase_auth`** | Secure user registration, authentication, login sessions, password resets, and session tokens. |
| **`cloud_firestore`** | The main database utilized to store user profiles (`users`), job listings (`jobs`), and application states (`applications`, `appliedJobs`) in real-time. |
| **`firebase_database`** | Used in tandem with Firestore for lightweight real-time database integrations. |
| **`firebase_storage`** | Stores external assets (like profile photos and job images) securely in the cloud. |
| **`google_maps_flutter`** | Displays interactive maps to show job locations and user coordinates. |
| **`geolocator`** | Requests GPS coordinates of the user's mobile device to calculate distance metrics dynamically. |
| **`geocoding`** | Resolves alphanumeric addresses (like street names) into latitude/longitude coordinates (forward geocoding) for map plotting. |
| **`flutter_polyline_points`** | Communicates with the Google Directions API to fetch route points and draw navigation lines between the worker and the job provider on the map. |
| **`get`** | A lightweight utility package used for state management, reactive routing (e.g. `Get.offAll()`), and displaying clean alert dialogues. |
| **`provider`** | Complements state management patterns by providing scoped data objects down the widget tree. |
| **`shared_preferences`** | Persists local data (like login status, role selection, and user details) across app restarts, enabling immediate auto-login. |
| **`get_storage`** | A fast, synchronous key-value store for local cache storage. |
| **`image_picker`** | Allows users to pick photos from their native gallery or directly snap pictures with their device camera. |
| **`flutter_image_compress`** | Compresses photos on the client side before encoding them to Base64/uploading, reducing bandwidth consumption and Firestore storage footprint. |
| **`google_fonts`** | Replaces default system fonts with high-quality custom typography from the Google Web Fonts library. |
| **`flutter_animate`** & **`lottie`** | Enhances UI aesthetics with premium animations, custom transition layers, and success animations. |
| **`uuid`** | Generates unique IDs for database primary keys and upload session identifiers. |
| **`country_state_city_pro`** | Displays a structured and search-enabled list of countries, states, and cities during user registration. |
| **`http`** | Enables direct external API requests (e.g. communication with the Google Maps Directions REST API). |
| **`path_provider`** | Locates paths to device temp directories for handling and compressing picked files. |

---

## 🚀 Getting Started & Setup

### 1. Prerequisites
Ensure you have the following installed on your machine:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.7.0 or higher)
* [Dart SDK](https://dart.dev/get-started)
* Android Studio / VS Code with Flutter extension
* An active Google Maps Platform account (with Maps SDK and Directions API enabled)
* A Firebase Project configured with Android and iOS apps

### 2. Project Configuration
* **Firebase Options:** Modify `lib/main.dart` or add the standard `firebase_options.dart` to specify your Firebase API keys and project IDs.
* **Google Maps API Key:** Add your Google Maps API key to:
  * Windows/Android manifest configuration.
  * In `lib/Pages/map_pages.dart` inside the `googleAPIKey` property.

### 3. Installation
Clone the repository, navigate to the project directory, and fetch the package dependencies:
```bash
flutter pub get
```

### 4. Running the Project
To launch the application on an emulator, connected physical device, or web browser:
```bash
flutter run
```

---

## 🗄️ Firestore Database Schema

Here is a quick overview of the key collections in Cloud Firestore:

* **`/users/workers/workers/{userId}`**
  * Stores details of registered workers: name, phone, role, experience, address components, profile image.
* **`/users/jobproviders/jobproviders/{userId}`**
  * Stores details of registered job providers: name, phone, role, address components, profile image.
* **`/jobs/workers/workers/{providerId}/order/{orderKey}`**
  * Posted job requirements. Contains `description`, `imageBase64`, and `orderkey`.
* **`/applications/{providerId}/posts/{postId}/workers/{workerId}`**
  * Applications sent to a job provider's specific post. Tracks worker profiles and `status` ('applied', 'accepted', 'rejected').
* **`/appliedJobs/{workerId}/jobProviders/{providerId}/posts/{postId}`**
  * Parallel path for workers to track status on their applied jobs.
