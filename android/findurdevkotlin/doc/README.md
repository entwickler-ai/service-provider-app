# FindurDev - Service Provider App (Android)

Eine Android-App zur Vermittlung von Dienstleistungen zwischen Anbietern (Provider) und Kunden (Customer).  
Die Anwendung ermöglicht es Dienstleistern, ihre Services anzubieten, und Kunden, diese zu finden und anzufragen.

---

## Features

### Für Dienstleister (Provider)
- Erstellung und Verwaltung von Services mit Portfolio-Bildern  
- Verwaltung von Kundenanfragen mit Status-Workflow  
- Chat-System mit Kunden inkl. Datei-Anhängen (Bilder, Dateien, Links)  
- KI-Textverbesserung und Nachrichten-Zusammenfassung im Chat
- Bewertungssystem und Statistiken  
- KI-gestützte Textverbesserung für Service-Beschreibungen  

### Für Kunden (Customer)
- Service-Suche mit Filtern (Bewertung, Tag, Standort, Preis)  
- Anfragen an Dienstleister senden  
- Chat-Kommunikation mit Anhängen (Bilder, Dateien, Links)
- KI-Textverbesserung und Nachrichten-Zusammenfassung im Chat
- Bewertungen nach Projektabschluss  
- KI-Unterstützung für Projektbeschreibungen

### Allgemein
- Authentifizierung und Benutzerverwaltung  
- Profilbearbeitung mit Bildern  
- KI-Textverbesserung und Nachrichten-Zusammenfassung im Chat
- Request-Management mit Statusverfolgung  
- Echtzeit-Benachrichtigungen für neue Nachrichten und Anfragen  

---

## Technologie-Stack

| Komponente               | Technologie                                   |
|--------------------------|-----------------------------------------------|
| **Frontend**             | Jetpack Compose (Material3)                   |
| **Backend**              | Firebase (Firestore, Authentication, Storage) |
| **AI-Integration**       | OpenAI API (GPT-4.1-nano)                     |
| **Architektur**          | MVVM                                          |
| **Dependency Injection** | Hilt                                          |
| **Asynchronität**        | Kotlin Coroutines & Flow                      |
| **Navigation**           | Navigation Compose                            |
| **Image Loading**        | Coil                                          |
| **Testing**              | Android-Emulator & physisches Gerät           |

---

## Voraussetzungen

- Android Studio Hedgehog (2023.1.1) oder höher  
- Android SDK 26 (Android 8.0) oder höher  
- Kotlin 1.9.25  
- Firebase-Projekt (bereits eingerichtet)
- OpenAI API-Key *(optional für KI-Features)*  (bereits hinterlegt)

---

## Installation

### 1. Projekt herunterladen

#### Der Download-Link zum Projekt ist in der Bachelorarbeit angegeben.  
Dieser befindet sich in **Kapitel 4 (Praxisprojekt), Abschnitt „Screenshots“**.  
Über den dort bereitgestellten Link kann das Projekt heruntergeladen und lokal entpackt werden.

### 2. Dependencies synchronisieren

Öffne das Projekt in Android Studio und lass Gradle die Dependencies synchronisieren.

### 3. Firebase konfigurieren *(bereits eingerichtet, dient nur als Übersicht)*
 
1. Erstelle ein Firebase-Projekt unter [console.firebase.google.com](https://console.firebase.google.com)
2. Aktiviere folgende Services:
   * Authentication (Email/Password)
   * Cloud Firestore
   * Cloud Storage
3. Lade die `google-services.json` herunter
4. Platziere sie im `app/` Verzeichnis des Projekts
5. Firestore-Regeln konfigurieren *(siehe unten)*

### 4. OpenAI API konfigurieren *(optional – bereits hinterlegt, dient nur als Übersicht)*

Öffne `OpenAIService.kt` und ersetze den API-Key:

```kotlin
private val apiKey = "DEIN-OPENAI-API-KEY"
```

### 5. App bauen, ausführen und testen (Entwicklungsmodus / Debug)

### Via Android Studio
Run → Run 'app'

### Via Terminal/ADB -> Projektverzeichnis

```bash
# Debug-APK bauen
./gradlew assembleDebug

# Debug-APK befindet sich dann in:
# app/build/outputs/apk/debug/app-debug.apk

# Debug-APK auf Gerät installieren
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

---

## 6. Release-Build erstellen und App produktiv testen (Fertigstellung)

### Via Android Studio (empfohlen)

1. USB-Debugging auf dem Gerät aktivieren
2. Gerät per USB verbinden
3. In Android Studio: Run → Run 'app'

### Via Terminal/ADB

### Release-Build erstellen *(Signing-Konfigurationen in `build.gradle.kts` bereits eingerichtet)*

```bash
# Release-APK bauen
./gradlew assembleRelease

# APK befindet sich dann in:
# app/build/outputs/apk/release/app-release.apk

# APK auf Gerät installieren
adb install -r app/build/outputs/apk/release/app-release.apk
```

---

## 7. Firestore-Struktur

### Collections

```
users/
  {userId}/
    - uid: String
    - name: String
    - email: String
    - role: String (customer | provider)
    - profileImage: String
    - description: String
    - location: String

services/
  {serviceId}/
    - id: String
    - providerId: String
    - providerName: String
    - title: String
    - description: String
    - price: Double
    - tags: [String]
    - portfolioImages: [String]
    - location: String
    - rating: Double
    - reviewCount: Int
    - createdAt: Long
    - updatedAt: Long

requests/
  {requestId}/
    - id: String
    - serviceId: String
    - serviceTitle: String
    - providerId: String
    - providerName: String
    - customerId: String
    - customerName: String
    - title: String
    - description: String
    - budget: Double
    - timeline: String
    - status: String (PENDING, ACCEPTED, REJECTED, IN_PROGRESS, COMPLETED, CANCELLED)
    - requirements: [String]
    - createdAt: Long
    - updatedAt: Long

chats/
  {chatId}/
    - id: String
    - participants: [String]
    - participantNames: {String: String}
    - lastMessage: String
    - lastMessageTimestamp: Long
    - lastMessageSenderId: String
    - unreadCount: {String: Int}
    - serviceId: String
    - serviceTitle: String
    - hiddenForUsers: [String]
    - temporaryEmptyForUsers: [String]
    - connectionStatus: {String: String}

messages/
  {messageId}/
    - id: String
    - chatId: String
    - senderId: String
    - senderName: String
    - content: String
    - type: String (TEXT, IMAGE, FILE, LINK)
    - timestamp: Long
    - fileUrl: String
    - fileName: String
    - fileSize: Long
    - isRead: Boolean

reviews/
  {reviewId}/
    - id: String
    - requestId: String
    - serviceId: String
    - providerId: String
    - providerName: String
    - customerId: String
    - customerName: String
    - rating: Int
    - comment: String
    - createdAt: Long

request_history/
  {historyId}/
    - id: String
    - requestId: String
    - status: String
    - timestamp: Long
    - notes: String
    - updatedBy: String
```

---

## 8. Erste Schritte (Beispielablauf für Nutzer)

1. **App starten** und Registrierung durchführen
2. **Rolle wählen**: Provider oder Customer

**Als Provider (Anbieter)**:

**Testzugang:**
- **Email:** testerp@fh.de
- **Passwort:** testerp

* Profil vervollständigen
* Ersten Service erstellen
* Auf Anfragen warten

**Als Customer (Kunde)**:

**Testzugang:**
- **Email:** testerk@fh.de
- **Passwort:** testerk

* Services durchsuchen
* Anfrage an Provider senden
* Im Chat kommunizieren

---

## 9. Projekt-Struktur

```
com.findurdevkotlin/
├── assets/                 # Bilder
├── doc/                    # README & Dokumentation
├── data/
│   ├── model/              # Datenmodelle
│   └── repository/         # Repository-Klassen
├── di/                     # Dependency Injection
├── ui/
│   ├── auth/              
│   ├── chat/              
│   ├── home/              
│   ├── navigation/        
│   ├── profile/           
│   ├── request/           
│   ├── review/            
│   ├── service/           
│   └── theme/             
├── FindurdevApp.kt        # Application Class
└── MainActivity.kt        # Main Activity
├ app/google-services.json #Firebase-Konfiguration
```

---

## 10. Wichtige Konfigurationen

### Minimum SDK

```kotlin
minSdk = 26  // Android 8.0
targetSdk = 35  // Android 15
```

### Permissions

Die App benötigt folgende Berechtigungen (bereits in `AndroidManifest.xml`):

* `INTERNET` - Netzwerkzugriff
* `ACCESS_NETWORK_STATE` - Netzwerkstatus abfragen
* `READ_EXTERNAL_STORAGE` - Dateizugriff (API < 33)
* `READ_MEDIA_IMAGES` - Bilderzugriff (API ≥ 33)
