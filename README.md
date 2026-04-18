# 🔍 Lost & Found Social

Application mobile Flutter permettant de retrouver les objets perdus de ta ville grâce à une communauté d'entraide et un système de matching intelligent.

---

## 📱 Fonctionnalités

- 🔐 Authentification (Email/Mot de passe)
- 📸 Publication d'objets perdus/trouvés avec photo
- 📍 Géolocalisation automatique
- 🗺️ Carte interactive des objets
- 🤖 Matching par mots-clés et catégorie
- 💬 Chat en temps réel entre utilisateurs
- ✅ Marquage comme résolu
- 👤 Profil avec statistiques et réputation

---

## 🛠️ Stack Technique

| Technologie | Utilité |
|---|---|
| Flutter | Framework mobile |
| Firebase Auth | Authentification |
| Cloud Firestore | Base de données temps réel |
| Firebase Storage | Stockage des photos |
| Google Maps Flutter | Carte interactive |
| Geolocator | GPS |

---

## 🚀 Installation & Setup

### Étape 1 — Cloner / Créer le projet Flutter

```bash
flutter create lost_and_found
cd lost_and_found
# Remplace les fichiers par ceux du projet
```

### Étape 2 — Créer un projet Firebase

1. Va sur [https://console.firebase.google.com](https://console.firebase.google.com)
2. Clique sur **"Ajouter un projet"**
3. Donne un nom : `lost-and-found-social`
4. Désactive Google Analytics (optionnel)
5. Clique **"Créer le projet"**

### Étape 3 — Activer les services Firebase

Dans la console Firebase :

**Authentication :**
- Va dans `Authentication` → `Sign-in method`
- Active **Email/Password**

**Firestore Database :**
- Va dans `Firestore Database` → `Créer une base de données`
- Choisis le mode **Test** (pour commencer)
- Copie les règles du fichier `firestore.rules`

**Storage :**
- Va dans `Storage` → `Commencer`
- Garde les règles par défaut

### Étape 4 — Connecter Flutter à Firebase

```bash
# Installe FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure ton projet
flutterfire configure
```

Cette commande génère automatiquement le fichier `firebase_options.dart` avec tes vraies clés.

### Étape 5 — Obtenir une clé Google Maps

1. Va sur [https://console.cloud.google.com](https://console.cloud.google.com)
2. Crée un projet ou utilise le même que Firebase
3. Active **"Maps SDK for Android"** et **"Maps SDK for iOS"**
4. Crée une clé API

**Android** — Dans `android/app/src/main/AndroidManifest.xml` :
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TA_CLE_GOOGLE_MAPS"/>
```

**iOS** — Dans `ios/Runner/AppDelegate.swift` :
```swift
GMSServices.provideAPIKey("TA_CLE_GOOGLE_MAPS")
```

### Étape 6 — Installer les dépendances

```bash
flutter pub get
```

### Étape 7 — Lancer l'app

```bash
flutter run
```

---

## 📁 Structure du projet

```
lib/
├── main.dart                    # Point d'entrée
├── firebase_options.dart        # Config Firebase (généré)
├── theme.dart                   # Thème dark moderne
├── models/
│   ├── item_model.dart          # Modèle objet
│   ├── user_model.dart          # Modèle utilisateur
│   └── message_model.dart       # Modèle message
├── services/
│   ├── auth_service.dart        # Login/Register
│   ├── item_service.dart        # CRUD objets + matching
│   ├── chat_service.dart        # Messagerie temps réel
│   └── location_service.dart    # GPS
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home_screen.dart         # Feed principal
│   ├── map_screen.dart          # Carte Google Maps
│   ├── publish_screen.dart      # Publier un objet
│   ├── item_detail_screen.dart  # Détail d'un objet
│   ├── chat_screen.dart         # Messagerie
│   ├── chats_list_screen.dart   # Liste des conversations
│   └── profile_screen.dart      # Profil utilisateur
└── widgets/
    └── item_card.dart           # Carte d'un objet
```

---

## 🤖 Algorithme de Matching

```
Objet A (perdu)  : catégorie=sac, couleur=noir, keywords=[Nike, tissu]
Objet B (trouvé) : catégorie=sac, couleur=noir, keywords=[Nike, sport]

Score :
- Même catégorie → +40 points
- Même couleur   → +20 points
- "Nike" commun  → +10 points
Total            → 70% de correspondance ✅ ALERTE !
```

---

## 🔐 Règles Firestore

Copie le contenu de `firestore.rules` dans la console Firebase.

---

## 📝 Notes importantes

- Remplace `TON_API_KEY` dans `firebase_options.dart` par tes vraies clés Firebase
- Remplace `TA_CLE_GOOGLE_MAPS` dans `AndroidManifest.xml` par ta vraie clé Google Maps
- Le fichier `firebase_options.dart` final est généré automatiquement par `flutterfire configure`

---

**Développé avec ❤️ Flutter + Firebase**
