# Service Provider App (FindUrDev)

Eine plattformübergreifende Anwendung für Dienstleister und Kunden, entwickelt für **Android** (Kotlin) und **iOS** (Swift).

---

## Projektstruktur & Submodule

Das Repository ist in zwei native Projekte unterteilt:

| Plattform | Technologie / Sprache | Projekt-Pfad | Dokumentation |
| :--- | :--- | :--- | :--- |
| **Android** | Kotlin / Jetpack Compose | [`/android/findurdevkotlin`](./android/findurdevkotlin) | [Android Dokumentation](./android/findurdevkotlin/doc/Android_Dokumentation.pdf) |
| **iOS** | Swift / SwiftUI | [`/ios/findurdevswift`](./ios/findurdevswift) | [iOS Dokumentation](./ios/findurdevswift/findurdevswift/doc/iOS_Dokumentation.pdf) |

---

## Features & Funktionsumfang

- **Rollenbasierter Zugriff:** Getrennte Ansichten und Funktionen für Kunden (Customer) und Dienstleister (Provider).
- **Service- & Anfragenverwaltung:** Erstellung, Bearbeitung und Verwaltung von Dienstleistungen sowie Kundenanfragen.
- **Echtzeit-Chat:** Integrierte Kommunikation zwischen Anbietern und Kunden.
- **KI-Unterstützung:** OpenAI-Integration zur Textverbesserung und Optimierung von Inhalten.
- **Bewertungssystem:** Rezensionen und Bewertungen für erbrachte Services.
- **Firebase Backend:** Authentifizierung, Firestore Datenhaltung und Cloud Storage.

---

## Einrichten & Starten

### Android (Kotlin)
1. Navigiere in das Verzeichnis [`android/findurdevkotlin`](./android/findurdevkotlin).
2. Öffne das Projekt in **Android Studio**.
3. Vergewissere dich, dass eine gültige `google-services.json` vorliegt.
4. Führe das Projekt auf einem Emulator oder physischen Gerät aus.

### iOS (Swift)
1. Navigiere in das Verzeichnis [`ios/findurdevswift`](./ios/findurdevswift).
2. Öffne die Datei `findurdevswift.xcodeproj` in **Xcode**.
3. Stelle sicher, dass die `GoogleService-Info.plist` korrekt eingebunden ist.
4. Wähle ein Zielgerät/Simulator aus und starte die App (`Cmd + R`).

---

## Dokumentation
Ausführliche technische Beschreibungen, Architekturübersichten und Handbücher befinden sich direkt in den Dokumentationsordnern der jeweiligen Plattform:

- Android: [Detaillierte README](./android/findurdevkotlin/doc/README.md) \| [PDF-Dokumentation](./android/findurdevkotlin/doc/Android_Dokumentation.pdf)
- iOS: [Detaillierte README](./ios/findurdevswift/findurdevswift/doc/README.md) \| [PDF-Dokumentation](./ios/findurdevswift/findurdevswift/doc/iOS_Dokumentation.pdf)
