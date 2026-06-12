<div align="center">

# 🔍 Lost & Found Social
### Application mobile Flutter — Retrouver les objets perdus de ta ville

![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-3.9+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)

</div>

---

## 📱 Présentation

**Lost & Found Social** est une application mobile communautaire permettant aux habitants d'une ville de **signaler des objets perdus ou trouvés**, de les localiser sur une carte interactive, et de contacter directement la personne concernée via une messagerie interne. Un algorithme de **matching automatique** analyse chaque nouvelle publication et alerte les utilisateurs si une correspondance existe.

> 🇲🇷 Application conçue pour Nouakchott, Mauritanie — supporte le **Français** et l'**Arabe**

---

## ✅ Respect des consignes du projet

| # | Consigne | Statut | Preuve |
|---|---|---|---|
| 1 | Travail en groupe | ✅ | Répartition des modules entre membres |
| 2 | Fonctionnalités interactives | ✅ | Formulaires, navigation, boutons, CRUD |
| 3 | Provider (gestion d'état) | ✅ | `providers/` — 4 providers complets |
| 4 | Architecture MVC | ✅ | `models/` + `screens/` + `controllers/` |
| 5 | Base de données + API | ✅ | Firestore (BDD) + Cloudinary (API) |
| 6 | Internationalisation | ✅ | Français + Arabe, changement à la volée |
| 7 | Qualité du code | ✅ | Code structuré, commenté, séparation claire |
| 8 | Présentation finale | ⏳ | Projet prêt à être présenté |
| 9 | Originalité | ✅ | Algorithme de matching unique + score |

---

## 🛠️ Stack Technique complète

### Framework
| Technologie | Version | Rôle |
|---|---|---|
| **Flutter** | ≥ 3.27.0 | Framework mobile multiplateforme (Android / iOS) |
| **Dart** | ≥ 3.9.0 | Langage de programmation |

---

### 🔥 Firebase — Backend principal

| Service | Package | Version | Ce qu'on fait |
|---|---|---|---|
| **Firebase Core** | `firebase_core` | 4.6.0 | Initialisation Firebase au démarrage |
| **Firebase Auth** | `firebase_auth` | 6.3.0 | Inscription / Connexion par email+mot de passe |
| **Cloud Firestore** | `cloud_firestore` | 6.2.0 | Base de données NoSQL temps réel |
| **Firebase Storage** | `firebase_storage` | 13.2.0 | Stockage fichiers (backup, remplacé par Cloudinary) |

**Collections Firestore utilisées :**
```
users/          → Profils utilisateurs (nom, email, score de réputation)
items/          → Objets perdus/trouvés (titre, GPS, photo, statut)
chats/          → Conversations entre utilisateurs
messages/       → Messages de chaque conversation
notifications/  → Alertes de matching, messages reçus, résolutions
matches/        → Correspondances détectées entre objets
```

---

### ☁️ Cloudinary — API d'hébergement d'images

| | Détail |
|---|---|
| **Package** | `cloudinary_public: ^0.23.1` |
| **Type** | API REST externe (cloud d'images) |
| **Cloud Name** | `dzxhiyrpi` |
| **Upload Preset** | `lost_found_preset` |
| **Dossier** | `lost_and_found/` |

**Flux d'utilisation :**
```
Utilisateur prend photo → image_picker → File local
→ CloudinaryService.uploadImage(file)
→ cloudinary.uploadFile() [appel API REST]
→ retourne response.secureUrl (URL HTTPS publique)
→ URL stockée dans Firestore avec l'objet
```

---

### 🗺️ Carte interactive — OpenStreetMap (GRATUIT, sans clé API)

| | Détail |
|---|---|
| **Package carte** | `flutter_map: ^6.2.1` |
| **Package coordonnées** | `latlong2: ^0.9.1` |
| **Fournisseur de tuiles** | CartoDB Positron (OpenStreetMap) |
| **URL des tuiles** | `https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png` |

**Fonctionnalités carte :**
- Affichage de tous les objets actifs sous forme de marqueurs colorés
- 🔴 Rouge = objet perdu / 🟢 Vert = objet trouvé
- Clic sur un marqueur → ouvre le détail de l'objet
- Bouton "centrer" → recentre sur Nouakchott (18.0735, -15.9582)
- Auto-fit des bounds pour afficher tous les objets

---

### 📍 Géolocalisation GPS

| | Détail |
|---|---|
| **Package** | `geolocator: ^10.1.1` |
| **Précision** | `LocationAccuracy.high` |
| **Timeout** | 10 secondes |
| **Option spéciale** | `forceAndroidLocationManager: true` (contourne le cache Android) |

**Flux GPS :**
```
Vérifier si GPS activé → Demander permission → Lire position réelle
→ Position(latitude, longitude) → Envoyée au service de géocodage
→ Stockée dans Firestore avec chaque objet publié
```

---

### 🏠 Géocodage — Coordonnées → Adresse lisible

| | Détail |
|---|---|
| **Package** | `geocoding: ^2.2.2` |
| **Locale** | `fr_FR` (noms en français) |
| **Format retourné** | `"Ville, Pays"` (ex: "Nouakchott, Mauritanie") |

```dart
// Exemple d'utilisation dans LocationService
List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng, localeIdentifier: 'fr_FR');
String address = "${placemarks.first.locality}, ${placemarks.first.country}";
```

---

### 🌍 Internationalisation (i18n)

| | Détail |
|---|---|
| **Package** | `flutter_localizations` (SDK Flutter) + `intl: ^0.20.2` |
| **Langues supportées** | 🇫🇷 Français + 🇲🇷 Arabe |
| **Fichiers de traduction** | `lib/l10n/app_fr.arb` + `lib/l10n/app_ar.arb` |
| **Fichiers générés** | `app_localizations.dart`, `app_localizations_fr.dart`, `app_localizations_ar.dart` |
| **Changement de langue** | À la volée, sans redémarrer l'application |
| **Support RTL** | ✅ Automatique pour l'arabe |

**Exemple de traduction dans un écran :**
```dart
final loc = AppLocalizations.of(context)!;
Text(loc.login)        // "Connexion" en FR  /  "تسجيل الدخول" en AR
Text(loc.publishItem)  // "Publier un objet" / "نشر غرض"
Text(loc.messages)     // "Messages"         / "الرسائل"
```

---

### 🧠 Gestion d'état — Provider

| | Détail |
|---|---|
| **Package** | `provider: ^6.1.5` |
| **Pattern** | `ChangeNotifier` + `MultiProvider` + `context.watch` / `context.read` |

**4 Providers créés :**

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AppAuthProvider()),      // État connexion
    ChangeNotifierProvider(create: (_) => ItemProvider()),         // Liste des objets
    ChangeNotifierProvider(create: (_) => NotificationProvider()), // Notifications
    ChangeNotifierProvider(create: (_) => LanguageProvider()),     // Langue active
  ],
)
```

**Utilisation dans les écrans :**
```dart
// Lire l'utilisateur connecté
final auth = context.watch<AppAuthProvider>();
final userId = auth.currentUserId;

// Changer la langue
context.read<LanguageProvider>().toggleLanguage();

// Badge notifications
final unread = context.watch<NotificationProvider>().unreadCount;
```

---

### 🖼️ Autres packages UI et utilitaires

| Package | Version | Rôle |
|---|---|---|
| `cached_network_image` | 3.4.1 | Chargement et cache des images Cloudinary |
| `image_picker` | 1.2.0 | Sélection photo depuis galerie ou appareil photo |
| `shared_preferences` | 2.5.3 | Stockage local des préférences utilisateur |
| `http` | 1.6.0 | Requêtes HTTP vers APIs externes |
| `cupertino_icons` | 1.0.8 | Icônes style iOS |

---

## 🤖 Algorithme de Matching — Fonctionnement

Quand un utilisateur publie un objet, le `MatchingService` cherche automatiquement des correspondances dans Firestore :

```
Objet A publié (PERDU) :  catégorie=sac, couleur=noir, keywords=[Nike, tissu]
Objet B existant (TROUVÉ): catégorie=sac, couleur=noir, keywords=[Nike, sport]

Calcul du score :
  ✅ Même catégorie        → +40 points
  ✅ Même couleur          → +20 points
  ✅ Mot-clé "Nike" commun → +10 points
  ─────────────────────────────────────
  Total                    → 70% → Correspondance "Forte" ✅
```

**Niveaux de correspondance :**
| Score | Label | Couleur |
|---|---|---|
| ≥ 80% | 🔥 Très forte | Vert |
| ≥ 60% | ✅ Forte | Orange |
| ≥ 40% | ⚠️ Possible | Gris |
| < 40% | 🔎 Faible | Gris clair |

Si score ≥ 40 : une **notification automatique** est envoyée aux deux utilisateurs.

---

## 🏗️ Architecture MVC du projet

```
lib/
│
├── main.dart                      ← Point d'entrée, MultiProvider, MaterialApp
├── theme.dart                     ← Thème dark (couleurs, styles globaux)
├── firebase_options.dart          ← Clés Firebase (auto-généré)
│
├── models/           ← M — MODÈLES (structure des données)
│   ├── item_model.dart            ← Objet perdu/trouvé
│   ├── user_model.dart            ← Utilisateur
│   └── message_model.dart         ← Message de chat
│
├── services/         ← ACCÈS AUX DONNÉES (Firebase, GPS, APIs)
│   ├── auth_service.dart          ← Inscription / Connexion Firebase Auth
│   ├── item_service.dart          ← CRUD objets + Cloudinary upload
│   ├── matching_service.dart      ← Algorithme de matching avec score
│   ├── chat_service.dart          ← Messagerie temps réel Firestore
│   ├── notification_service.dart  ← Notifications Firestore
│   ├── location_service.dart      ← GPS + géocodage
│   ├── search_service.dart        ← Recherche intelligente (détection catégorie/couleur)
│   └── cloudinary_service.dart    ← Upload images vers Cloudinary
│
├── providers/        ← GESTION D'ÉTAT (Provider pattern)
│   ├── auth_provider.dart         ← État de connexion utilisateur
│   ├── item_provider.dart         ← Liste objets, filtres, publication
│   ├── notification_provider.dart ← Notifications non lues
│   └── language_provider.dart     ← Langue active (FR / AR)
│
├── controllers/      ← C — CONTRÔLEURS (logique + validation)
│   ├── auth_controller.dart       ← Validation formulaires auth
│   ├── item_controller.dart       ← Validation + publication objet
│   └── notification_controller.dart ← Actions sur notifications
│
├── screens/          ← V — VUES (interface utilisateur)
│   ├── auth/
│   │   ├── login_screen.dart      ← Écran connexion (animation fade)
│   │   └── register_screen.dart   ← Écran inscription
│   ├── home_screen.dart           ← Feed principal (4 onglets)
│   ├── publish_screen.dart        ← Formulaire publication objet
│   ├── item_detail_screen.dart    ← Détail d'un objet
│   ├── map_screen.dart            ← Carte OpenStreetMap interactive
│   ├── match_result_screen.dart   ← Résultats du matching automatique
│   ├── chat_screen.dart           ← Messagerie en temps réel
│   ├── chats_list_screen.dart     ← Liste de toutes les conversations
│   ├── notifications_screen.dart  ← Centre de notifications
│   └── profile_screen.dart        ← Profil + statistiques + changement de langue
│
├── widgets/          ← Composants réutilisables
│   └── item_card.dart             ← Carte visuelle d'un objet
│
└── l10n/             ← Traductions (FR + AR)
    ├── app_fr.arb                 ← Fichier traduction Français
    ├── app_ar.arb                 ← Fichier traduction Arabe
    ├── app_localizations.dart     ← Classe générée (auto)
    ├── app_localizations_fr.dart  ← Traductions FR générées (auto)
    └── app_localizations_ar.dart  ← Traductions AR générées (auto)
```

---

## 🔐 Sécurité — Règles Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Profils : lecture pour tous, écriture uniquement pour son propre profil
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Objets : tout le monde peut lire, seul le propriétaire peut modifier/supprimer
    match /items/{itemId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
        && request.auth.uid == resource.data.userId;
    }

    // Chats : uniquement les participants peuvent lire/écrire
    match /chats/{chatId} {
      allow read, write: if request.auth != null
        && request.auth.uid in resource.data.participants;
    }
  }
}
```

---

## 🚀 Installation

```bash
# 1. Cloner le projet
git clone <url-du-repo>
cd lost_and_found_2

# 2. Installer les dépendances
flutter pub get

# 3. Générer les fichiers de traduction
flutter gen-l10n

# 4. Lancer l'application
flutter run
```

> ⚠️ Le fichier `google-services.json` et `firebase_options.dart` contiennent
> les vraies clés Firebase du projet et sont déjà configurés.

---

## 📦 Toutes les dépendances

```yaml
dependencies:
  flutter_localizations:          # Internationalisation
    sdk: flutter
  provider: ^6.1.5               # Gestion d'état
  intl: ^0.20.2                  # Formatage + traductions
  firebase_core: ^4.6.0          # Base Firebase
  firebase_auth: ^6.3.0          # Authentification
  cloud_firestore: ^6.2.0        # Base de données
  firebase_storage: ^13.2.0      # Stockage fichiers
  cloudinary_public: ^0.23.1     # API upload images
  flutter_map: ^6.2.1            # Carte OpenStreetMap
  latlong2: ^0.9.1               # Coordonnées GPS
  geolocator: ^10.1.1            # Position GPS
  geocoding: ^2.2.2              # Coordonnées → Adresse
  cached_network_image: ^3.4.1   # Cache images réseau
  image_picker: ^1.2.0           # Sélection photos
  shared_preferences: ^2.5.3     # Stockage local
  http: ^1.6.0                   # Requêtes HTTP
  cupertino_icons: ^1.0.8        # Icônes iOS
```

---

<div align="center">

**Développé avec ❤️ Flutter + Firebase**
*Projet universitaire — Développement Mobile*

</div>


