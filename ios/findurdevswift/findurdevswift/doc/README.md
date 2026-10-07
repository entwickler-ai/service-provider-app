# FindurDev - Service Provider App (iOS)

Eine iOS-App zur Vermittlung von Dienstleistungen zwischen Anbietern (Provider) und Kunden (Customer).  
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

##  Technologie-Stack

| Komponente               | Technologie                                               |
|--------------------------|-----------------------------------------------------------|
| **Frontend**             | SwiftUI (iOS 15+)                                         |
| **Backend**              | Firebase (Firestore, Authentication, Storage)             |
| **AI-Integration**       | OpenAI API (GPT-4.1-nano)                                 |
| **Architektur**          | MVVM                                                      |
| **Dependency Injection** | ServiceContainer Pattern mit @StateObject/@ObservedObject |
| **Asynchronität**        | Swift Concurrency (async/await) & Combine Framework       |
| **Navigation**           | SwiftUI NavigationStack & NavigationLink                  |
| **Bildverwaltung**       | PhotosUI, AsyncImage                                      |
| **Testing**              | Xcode Simulator & physisches Gerät                        |

---

## Voraussetzungen

- Xcode 15.0 oder höher  
- iOS 15.0 oder höher  
- CocoaPods oder Swift Package Manager  
- Firebase-Projekt (bereits eingerichtet)
- OpenAI API-Key *(optional für KI-Features)*  (bereits hinterlegt)

---

## Installation

### 1. Projekt herunterladen

#### Der Download-Link zum Projekt ist in der Bachelorarbeit angegeben.  
Dieser befindet sich in **Kapitel 4 (Praxisprojekt), Abschnitt „Screenshots“**.  
Über den dort bereitgestellten Link kann das Projekt heruntergeladen und lokal entpackt werden.

### 2. Dependencies installieren

#### Option A: Swift Package Manager (empfohlen)

Öffne das Projekt bzw. die datei namens `findurdevswift.xcodeproj` in Xcode und Xcode lädt die bereits konfigurierten Dependencies automatisch.

- Die Firebase-Pakete (Auth, Firestore, Storage) sind über Swift Package Manager eingebunden.

#### Option B: CocoaPods
```bash
pod install
```

### 3. Firebase konfigurieren *(bereits eingerichtet, dient nur als Übersicht)*

1. Erstelle ein Firebase-Projekt unter [console.firebase.google.com](https://console.firebase.google.com)
2. Aktiviere folgende Services:
   * Authentication (Email/Password)
   * Cloud Firestore
   * Cloud Storage
3. Lade die `GoogleService-Info.plist` herunter
4. Ersetze die vorhandene `GoogleService-Info.plist` im Projekt
5. Firestore-Regeln konfigurieren *(siehe unten)*

### 4. OpenAI API konfigurieren *(optional – bereits hinterlegt, dient nur als Übersicht)*

Öffne `OpenAIService.swift` und ersetze den API-Key:

```swift
private let apiKey = "DEIN-OPENAI-API-KEY"
```

### 5. App bauen, ausführen und testen (Entwicklungsmodus / Debug)

### Via Xcode
Run → Run 'app'

### Via Terminal

```bash
# Öffne das Projekt
open findurdevswift.xcodeproj

# Oder bei CocoaPods
open findurdevswift.xcworkspace
```

---

## 6. iOS-App per Terminal aufs iPhone installieren (ohne Developer Account)

### Voraussetzungen

Du hast:

- Dein iPhone per USB mit dem Mac verbunden  
- In **Xcode > Settings > Apple Accounts** dein Apple-ID-Konto hinzugefügt  
- In **Signing & Capabilities** dein **Personal Team** ausgewählt  
- Deine App einmal **erfolgreich über Xcode gestartet** (wichtig, damit iOS dir vertraut)  

---
### Schritt 1: Terminal öffnen

Öffne dein Terminal und wechsle in dein Projekt:

```bash
cd ~/Xcode/findurdevswift
````

---
### Schritt 2: App mit Xcodebuild kompilieren
Baue deine App im Debug-Modus:

```bash
xcodebuild -scheme findurdevswift -configuration Debug -sdk iphoneos -derivedDataPath build
```

Das erzeugt die Datei:
```
build/Build/Products/Debug-iphoneos/findurdevswift.app
```

---
### Schritt 3: Tool `ios-deploy` installieren
Dieses Tool brauchst du, um Apps direkt auf dein Gerät zu pushen (ähnlich wie `adb install` bei Android):
```bash
npm install -g ios-deploy
```
> Wenn du kein npm hast:
>
> ```bash
> brew install node
> ```

---
### Schritt 4: App auf iPhone installieren
Wenn dein iPhone angeschlossen ist, führe Folgendes aus:

```bash
ios-deploy --bundle build/Build/Products/Debug-iphoneos/findurdevswift.app
```
Danach wird die App automatisch auf deinem iPhone installiert und gestartet.

---

## 7. Firestore-Struktur

### Collections
```
users/
  {userId}/
    - name: String
    - email: String
    - role: String (customer | provider)
    - profileImage: String
    - description: String
    - location: String

services/
  {serviceId}/
    - providerId: String
    - title: String
    - description: String
    - price: Double
    - tags: [String]
    - portfolioImages: [String]
    - location: String
    - rating: Double
    - reviewCount: Int

requests/
  {requestId}/
    - serviceId: String
    - providerId: String
    - customerId: String
    - title: String
    - description: String
    - budget: Double
    - status: String
    - timeline: String

chats/
  {chatId}/
    - participants: [String]
    - participantNames: {String: String}
    - lastMessage: String
    - unreadCount: {String: Int}

messages/
  {messageId}/
    - chatId: String
    - senderId: String
    - content: String
    - type: String
    - timestamp: Int64

reviews/
  {reviewId}/
    - serviceId: String
    - providerId: String
    - customerId: String
    - rating: Int
    - comment: String
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
findurdevswift/
├── Assets/                   # Bilder
├── doc/                      # README & Dokumentation
├── Models/                   # Datenmodelle
├── Services/                 # Backend-Services
├── ViewModels/               # MVVM ViewModels
├── Views/                    # UI-Komponenten nach Feature
│   ├── components/           # Wiederverwendbare UI-Komponenten (Buttons, Cards, Modals)
└── Persistence.swift         # Datenpersistenz
└── findurdevswiftApp.swift   # Application Entry Point
└── GoogleService-Info.plist  # Firebase-Konfiguration
```

---

## 10. Wichtige Konfigurationen

### iOS Deployment
```
iOS Deployment Target = 15.0
```
