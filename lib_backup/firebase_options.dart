// Ce fichier est généré automatiquement par FlutterFire CLI
// Commande : flutterfire configure
//
// NE PAS MODIFIER MANUELLEMENT
// Remplace ce fichier par celui généré par : flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ⚠️ REMPLACE CES VALEURS PAR TES VRAIES CLÉS FIREBASE
  // Va sur : https://console.firebase.google.com
  // Crée un projet → Ajoute une app Flutter → Copie les clés ici

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TON_API_KEY_WEB',
    appId: 'TON_APP_ID_WEB',
    messagingSenderId: 'TON_SENDER_ID',
    projectId: 'TON_PROJECT_ID',
    storageBucket: 'TON_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDh-bML9TJHp_5zMaG0mtketbxiOV2GbPo',
    appId: '1:92507018209:android:d7a944321114259edc38a0',
    messagingSenderId: '92507018209',
    projectId: 'lost-found-new-c0961',
    storageBucket: 'lost-found-new-c0961.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TON_API_KEY_IOS',
    appId: 'TON_APP_ID_IOS',
    messagingSenderId: 'TON_SENDER_ID',
    projectId: 'TON_PROJECT_ID',
    storageBucket: 'TON_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.lostAndFound',
  );
}