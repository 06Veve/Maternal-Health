# Bebezen — application de suivi de grossesse

Bebezen est une application Flutter destinée à accompagner une femme enceinte et son partenaire pendant la grossesse. Elle centralise le suivi de grossesse, les symptômes, les mouvements du bébé, les tâches familiales, les rappels, les discussions et un assistant éducatif basé sur Gemini.

Ce document est volontairement pédagogique. Il explique le fonctionnement fonctionnel de l’application, l’organisation du code, la base de données Firestore et le rôle des principales technologies.

> Important : Bebezen fournit des informations éducatives. L’application ne remplace pas un médecin, une sage-femme ou les services d’urgence.

## 1. Objectif du projet

L’application répond à quatre besoins principaux :

1. suivre l’évolution de la grossesse ;
2. enregistrer des informations de santé et de bien-être ;
3. faire collaborer la mère et son partenaire avec deux comptes séparés ;
4. donner accès à un assistant éducatif et à une communauté.

Une famille est représentée par un `household`, c’est-à-dire un foyer. Le compte mère et le compte partenaire ont chacun leur propre connexion Firebase Auth, mais ils partagent les données du même foyer.

## 2. Fonctionnalités disponibles

### Compte mère

La mère dispose de quatre onglets principaux :

- **Today** : résumé de la grossesse et raccourcis importants ;
- **Insights** : grossesse, symptômes, mouvements du bébé, bien-être, rappels et accès partenaire ;
- **Assistant** : conversation privée avec Gemini et accès au chat familial ;
- **Profile** : identité du compte, email, semaine de grossesse, état de la liaison familiale et déconnexion.

Elle peut notamment :

- consulter la semaine de grossesse et la date prévue d’accouchement ;
- enregistrer ses symptômes ;
- compter les mouvements du bébé ;
- suivre l’eau, les repas et l’activité ;
- créer des rappels ;
- générer un code d’invitation pour le partenaire ;
- discuter avec le partenaire ;
- créer et suivre des tâches familiales ;
- utiliser le forum communautaire ;
- poser des questions à l’assistant Gemini.

### Compte partenaire

Le partenaire est un véritable utilisateur, pas un simple mode activé dans la session de la mère. Il possède :

- sa propre adresse email ;
- son propre mot de passe ;
- son propre document `users/{uid}` ;
- une navigation adaptée à son rôle.

Ses quatre onglets sont :

- **Home** : résumé du foyer et informations utiles ;
- **Tasks** : gestion des tâches familiales ;
- **Family** : discussion privée avec la mère et badge de messages non lus ;
- **Profile** : informations du compte et déconnexion.

Le partenaire peut consulter les informations partagées du foyer, gérer les tâches et participer au chat familial. Les données de santé sensibles restent modifiables par la mère selon les règles Firestore.

### Communauté

Le forum permet de :

- publier dans une catégorie ;
- afficher le nom de l’auteur ;
- liker ou retirer son like ;
- garantir un seul like par utilisateur et par publication ;
- répondre à une publication ;
- afficher les réponses et leurs auteurs en temps réel.

### Assistant Gemini

L’assistant répond dans la langue de l’utilisateur. Son instruction système lui demande de :

- fournir une information concise et éducative ;
- prendre en compte la semaine de grossesse ;
- ne pas poser de diagnostic ;
- ne pas prescrire de traitement ;
- signaler les signes nécessitant une consultation urgente.

Une limite applicative de dix réponses quotidiennes par utilisateur est enregistrée dans Firestore.

## 3. Technologies utilisées

| Technologie | Rôle dans le projet |
|---|---|
| Flutter | Construction de l’interface Android, iOS, web et desktop avec un seul code source |
| Dart | Langage utilisé par Flutter |
| Firebase Authentication | Création des comptes, connexion, session et déconnexion |
| Cloud Firestore | Base de données NoSQL temps réel |
| Firebase AI Logic | Solution de secours pour Gemini lorsque la clé directe n’est pas utilisée |
| Gemini REST API | Génération des réponses de l’assistant avec `generateContent` |
| `flutter_dotenv` | Chargement de `GEMINI_API_KEY` depuis `.env` |
| `http` | Envoi des requêtes HTTPS à Gemini |
| `flutter_local_notifications` | Notifications et rappels locaux |
| `table_calendar` | Affichage et manipulation du calendrier |
| `intl` | Formatage des dates et heures |
| `pdf` et `printing` | Création et partage de rapports PDF |
| `shared_preferences` | Petites données locales simples |
| `image_picker` | Sélection d’images depuis l’appareil |

Le projet reste compatible avec le forfait Firebase **Spark** : il n’utilise pas de Cloud Functions pour son fonctionnement principal.

## 4. Prérequis

Avant de lancer le projet, il faut installer :

- Flutter avec une version compatible avec Dart `^3.8.1` ;
- Android Studio ou Xcode selon la plateforme ;
- un appareil, un émulateur ou Chrome ;
- Firebase CLI uniquement pour déployer les règles ;
- un projet Firebase configuré.

Vérifier l’installation :

```bash
flutter doctor
firebase --version
```

## 5. Installation et lancement

### Récupérer les dépendances

À la racine du projet :

```bash
flutter pub get
```

### Configurer Gemini

Créer ou compléter le fichier `.env` à la racine :

```env
GEMINI_API_KEY=VOTRE_CLE_GEMINI
```

Ne jamais ajouter d’espace autour du signe `=`.

Le fichier est déclaré comme ressource dans `pubspec.yaml` :

```yaml
flutter:
  assets:
    - assets/images/
    - .env
```

Il est ensuite chargé avant le démarrage de l’application dans `lib/main.dart` :

```dart
WidgetsFlutterBinding.ensureInitialized();
await dotenv.load(fileName: '.env');
await Firebase.initializeApp(...);
runApp(const MyApp());
```

Après une modification de `.env`, effectuer un redémarrage complet. Un simple hot reload peut conserver l’ancienne valeur.

### Lancer l’application

```bash
flutter run
```

Si plusieurs appareils sont disponibles, Flutter demande lequel utiliser.

### Déployer les règles Firestore

```bash
firebase deploy --only firestore:rules
```

Les règles locales sont dans `firestore.rules`. Une modification de ce fichier n’affecte pas Firebase tant qu’elle n’est pas déployée.

## 6. Organisation du code

```text
lib/
├── main.dart                         point d’entrée
├── login.dart                        connexion
├── signup2.dart                      inscription mère/partenaire
├── manage_navigation.dart            navigation selon le rôle
├── home.dart                         accueil mère
├── insights.dart                     tableau de bord de suivi
├── messages.dart                     interface de l’assistant Gemini
├── profile.dart                      profil et déconnexion
├── core/
│   ├── services/
│   │   ├── account_service.dart      foyers, comptes et invitations
│   │   └── notification_service.dart notifications
│   ├── theme/bebezen_theme.dart      couleurs et thème
│   └── utils/pdf_generator.dart      création de PDF
├── services/
│   ├── gemini_service.dart           appel Gemini et quota
│   ├── authentication.dart           opérations d’authentification
│   └── input_validator.dart          validation des formulaires
├── features/
│   ├── health/                       symptômes, bien-être, kicks, rappels
│   └── partner/
│       ├── partner_mode.dart         invitations, dashboard et tâches
│       └── couple_chat.dart          chat familial et badge non lu
├── home_nav_pages/
│   ├── Comm_forum.dart               publications, likes et réponses
│   ├── preg_tracker.dart             progression de grossesse
│   └── Emerg_services.dart           services d’urgence
└── shared/widgets/bz_components.dart composants visuels réutilisables
```

### Pourquoi séparer les fichiers ?

Une classe ne doit pas tout faire. Le projet sépare donc :

- les **écrans**, responsables de l’affichage ;
- les **services**, responsables des opérations Firebase ou réseau ;
- les **widgets partagés**, responsables des composants réutilisables ;
- le **thème**, responsable de l’identité visuelle.

Cette séparation rend le code plus simple à tester et à modifier.

## 7. Démarrage de l’application

Le flux commence dans `lib/main.dart` :

```text
main()
  ├── initialise Flutter
  ├── charge .env
  ├── initialise Firebase
  ├── initialise les notifications
  └── affiche MyApp
```

Firebase Authentication conserve la session sur l’appareil. Si un utilisateur est déjà connecté, l’application peut le rediriger vers sa navigation. Sinon, elle affiche les écrans d’accueil ou de connexion.

## 8. Authentification et création des comptes

### Inscription de la mère

Dans `signup2.dart` :

1. le formulaire valide le nom, l’email, l’âge gestationnel et les deux mots de passe ;
2. `createUserWithEmailAndPassword` crée le compte Firebase Auth ;
3. `AccountService.createMotherProfile` crée le profil Firestore ;
4. le service crée également un foyer ;
5. l’UID de la mère devient `motherId` et le premier élément de `memberIds`.

Deux écritures sont effectuées ensemble dans un **batch** :

```text
users/{uid de la mère}
households/{nouvel identifiant}
```

Un batch garantit que les deux écritures sont envoyées comme une seule opération logique.

### Inscription du partenaire

Le partenaire choisit le rôle `partner` et saisit le code reçu de la mère :

1. Firebase Auth crée son compte ;
2. un document utilisateur temporairement sans foyer est créé ;
3. `acceptPartnerInvite` vérifie le code et sa date d’expiration ;
4. une transaction lie le partenaire au foyer ;
5. le partenaire reçoit `householdId` ;
6. son UID est ajouté dans `memberIds` ;
7. l’invitation passe à l’état `accepted`.

Une **transaction** relit les documents avant de les modifier. Elle évite, par exemple, que deux partenaires utilisent le même code simultanément.

### Pourquoi Auth et Firestore sont-ils séparés ?

Firebase Auth conserve les données d’identité nécessaires à la connexion :

- UID ;
- email ;
- mot de passe chiffré et géré par Firebase ;
- état de la session.

Firestore conserve les données métier :

- nom affiché ;
- rôle ;
- foyer ;
- données de grossesse ;
- messages, tâches et suivis.

Le mot de passe n’est jamais enregistré dans Firestore.

## 9. Navigation selon le rôle

`manage_navigation.dart` écoute le document de l’utilisateur :

```dart
FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .snapshots();
```

Le champ `role` décide de la liste des pages :

```text
role == mother  → Today, Insights, Assistant, Profile
role == partner → Home, Tasks, Family, Profile
```

La navigation utilise un `IndexedStack`. Contrairement à une reconstruction complète, il garde les pages en mémoire lorsque l’utilisateur change d’onglet. Les champs et les positions de défilement sont donc mieux conservés.

Avant un changement d’onglet :

```dart
FocusManager.instance.primaryFocus?.unfocus();
```

Cette instruction retire le focus du champ actif et ferme le clavier.

## 10. Structure de la base Firestore

Firestore est une base **NoSQL orientée documents** :

- une collection contient des documents ;
- un document contient des champs ;
- un document peut contenir des sous-collections.

Schéma principal :

```text
users/{uid}
├── name
├── email
├── role: "mother" | "partner"
├── householdId
├── createdAt
├── updatedAt
├── chatState/family
│   └── lastReadAt
├── usage/{YYYY-MM-DD}
│   ├── assistantCount
│   └── updatedAt
└── aiChats/main/messages/{messageId}
    ├── text
    ├── role: "user" | "assistant"
    └── createdAt

households/{householdId}
├── motherId
├── partnerId
├── memberIds: [uidMere, uidPartenaire]
├── pregnancy
│   ├── gestationalAgeWeeks
│   ├── referenceDate
│   ├── lmpEstimated
│   └── dueDate
├── tasks/{taskId}
├── messages/{messageId}
├── healthLogs/{logId}
├── kickSessions/{sessionId}
├── events/{eventId}
└── emergencyContacts/{contactId}

partnerInvites/{code}
├── householdId
├── motherId
├── status: "pending" | "accepted"
├── expiresAt
└── partnerId

posts/{postId}
├── authorId
├── username
├── content
├── category
├── timestamp
├── likes/{uid}
│   ├── userId
│   └── createdAt
└── replies/{replyId}
    ├── authorId
    ├── username
    ├── text
    └── createdAt
```

### Pourquoi les données familiales sont-elles dans `households` ?

Si les tâches étaient rangées sous `users/{uid}`, la mère et le partenaire auraient deux copies différentes. En les rangeant sous le foyer, les deux comptes lisent la même source :

```dart
households/{householdId}/tasks/{taskId}
```

Cela évite la duplication et les problèmes de synchronisation.

### Pourquoi le nom est-il aussi enregistré dans les messages et posts ?

`senderName` ou `username` est une donnée dénormalisée. Firestore ne réalise pas de jointure SQL automatique. Conserver le nom dans le contenu permet d’afficher rapidement l’auteur.

Dans le chat familial, l’application essaie aussi de lire le nom actuel du profil à partir de `senderId`. Le nom stocké dans le message sert de valeur de secours.

### Pourquoi un like est-il un document ?

Chaque like utilise l’UID comme identifiant :

```text
posts/{postId}/likes/{uid}
```

Un utilisateur ne peut donc avoir qu’un document de like pour une publication. Cliquer une première fois crée le document ; cliquer une seconde fois le supprime. Cette structure est plus fiable qu’un compteur modifiable librement par tous les clients.

## 11. Temps réel avec `StreamBuilder`

Firestore fournit des flux avec `.snapshots()` :

```dart
StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: collection.snapshots(),
  builder: (context, snapshot) {
    // reconstruire l'interface avec snapshot.data
  },
)
```

Lorsqu’un message, une tâche, un like ou une réponse change dans Firestore, le flux émet une nouvelle valeur. Flutter reconstruit alors seulement la partie concernée.

États importants à traiter :

```dart
if (snapshot.hasError) {
  return const Text('Une erreur est survenue');
}
if (!snapshot.hasData) {
  return const CircularProgressIndicator();
}
```

`FutureBuilder` est utilisé pour une opération ponctuelle. `StreamBuilder` est utilisé lorsqu’on veut continuer à écouter les changements.

## 12. Fonctionnement du chat familial

Les messages sont stockés ici :

```text
households/{householdId}/messages/{messageId}
```

Un message possède :

```dart
{
  'text': texte,
  'senderId': uid,
  'senderName': nom,
  'createdAt': FieldValue.serverTimestamp(),
  'type': 'text',
}
```

Le `senderId` est utilisé pour savoir si la bulle appartient à l’utilisateur courant. `senderName` sert à afficher le nom.

Le badge non lu compare :

- la date du dernier message envoyé par l’autre membre ;
- `users/{uid}/chatState/family.lastReadAt`.

Quand l’utilisateur ouvre le chat, `lastReadAt` est mis à jour.

## 13. Fonctionnement de la communauté

Les publications sont filtrées par catégorie et limitées à 50 documents. La limite protège les performances et correspond aux règles Firestore.

### Ajouter ou retirer un like

Pseudo-code :

```text
si likes/{monUid} existe
    supprimer le document
sinon
    créer le document
```

Le compteur affiché correspond au nombre de documents reçus dans la sous-collection `likes`.

### Répondre

Une réponse est ajoutée dans :

```text
posts/{postId}/replies/{replyId}
```

Elle contient le texte, l’UID de l’auteur, son nom et l’heure du serveur. Les réponses sont limitées à 2 000 caractères par l’interface et par les règles Firestore.

## 14. Calcul de la semaine de grossesse

Le foyer conserve :

- `gestationalAgeWeeks` : semaine connue au moment de l’inscription ;
- `referenceDate` : date de cette mesure.

La semaine actuelle est calculée ainsi :

```dart
semaineActuelle = semaineInitiale
    + nombreDeJoursDepuisLaReference ~/ 7;
```

L’opérateur `~/` effectue une division entière. Le résultat est limité entre 0 et 42 avec `clamp(0, 42)`.

La date des dernières règles est estimée en retirant le nombre de semaines à la date de référence. La date prévue d’accouchement est estimée 280 jours après cette date.

## 15. Fonctionnement de Gemini

L’écran se trouve dans `lib/messages.dart`. La logique réseau est dans `lib/services/gemini_service.dart`.

Lorsqu’une question est envoyée :

```text
1. le message utilisateur est enregistré dans Firestore
2. le service lit la semaine de grossesse
3. il lit GEMINI_API_KEY
4. il envoie une requête POST à generateContent
5. il extrait le texte de la réponse JSON
6. il enregistre la réponse dans Firestore
7. il met à jour le quota quotidien
```

Endpoint utilisé :

```text
POST https://generativelanguage.googleapis.com/v1beta/models/
     gemini-2.5-flash:generateContent
```

La clé est envoyée dans l’en-tête :

```text
x-goog-api-key: GEMINI_API_KEY
```

Le service transforme les codes HTTP en messages compréhensibles :

- `400` : requête ou clé invalide ;
- `401/403` : clé refusée ou API non autorisée ;
- `404` : modèle indisponible ;
- `429` : quota Gemini épuisé ;
- `500+` : service temporairement indisponible.

### Limite de sécurité importante

Une clé incluse dans `.env` est intégrée dans l’application compilée. Elle convient pour une démonstration ou une soutenance, mais elle peut être extraite d’un APK. Pour une mise en production, l’appel Gemini devrait passer par un serveur contrôlé ou par Firebase AI Logic avec App Check.

## 16. Règles de sécurité Firestore

Les règles sont dans `firestore.rules`. Elles sont aussi importantes que le code Flutter : un utilisateur peut modifier une application cliente, mais il ne peut pas contourner des règles correctement déployées.

Fonctions principales :

```text
signedIn()                   utilisateur connecté
own(uid)                     utilisateur propriétaire du document
householdMember(householdId) utilisateur membre du foyer
motherOf(householdId)        utilisateur mère de ce foyer
sameHousehold(profile)       deux profils du même foyer
```

Exemples de permissions :

| Donnée | Lecture | Écriture |
|---|---|---|
| Profil utilisateur | propriétaire ou membre du même foyer | propriétaire |
| Foyer | membre du foyer | selon rôle et opération |
| Tâches | membres du foyer | membres du foyer |
| Chat familial | membres du foyer | auteur du message pour modification/suppression |
| Données de santé | membres du foyer | mère |
| Publications | utilisateurs connectés | auteur |
| Likes | utilisateurs connectés | uniquement le document portant son UID |
| Réponses | utilisateurs connectés | auteur de la réponse |

La dernière règle refuse tout ce qui n’a pas été explicitement autorisé :

```javascript
match /{document=**} {
  allow read, write: if false;
}
```

C’est le principe de sécurité appelé **deny by default**.

## 17. Gestion de l’état Flutter

Le projet utilise principalement l’état local natif de Flutter :

- `StatefulWidget` pour une valeur qui change dans un écran ;
- `setState` pour demander une reconstruction ;
- `StreamBuilder` pour l’état Firestore temps réel ;
- `FutureBuilder` pour une opération asynchrone ponctuelle ;
- `TextEditingController` pour lire et vider les champs.

Exemple :

```dart
setState(() => _sending = true);
try {
  await envoyerLeMessage();
} finally {
  if (mounted) setState(() => _sending = false);
}
```

`mounted` vérifie que le widget existe encore après un `await`. Sans cette vérification, un `setState` pourrait être appelé après la fermeture de l’écran.

## 18. Composants visuels

`lib/shared/widgets/bz_components.dart` contient les éléments réutilisables comme :

- `BZButton` ;
- `BZInput` ;
- `BZCard` ;
- `BZLoading`.

`lib/core/theme/bebezen_theme.dart` centralise les couleurs, dégradés et styles. Utiliser ces composants évite de recopier le même design dans chaque page.

## 19. Gestion des erreurs

Les appels asynchrones pouvant échouer sont placés dans `try/catch` :

```dart
try {
  await operationFirebase();
} on FirebaseException catch (error) {
  // afficher une information lisible
}
```

Les causes fréquentes sont :

- absence de connexion Internet ;
- règle Firestore refusant l’opération ;
- clé Gemini incorrecte ;
- quota Gemini dépassé ;
- utilisateur déconnecté ;
- document Firebase manquant.

Il ne faut pas masquer toutes les erreurs avec un message unique. Le service Gemini, par exemple, distingue les problèmes de clé, de quota et de réseau.

## 20. Tests et qualité

Lancer les tests :

```bash
flutter test
```

Lancer l’analyse statique :

```bash
flutter analyze
```

Construire un APK de démonstration :

```bash
flutter build apk --debug
```

Construire un APK de production :

```bash
flutter build apk --release
```

Le dossier `test/` contient notamment des tests de calcul de grossesse et de composants visuels.

Pour une fonctionnalité Firebase, il faut idéalement tester au minimum :

1. le cas normal ;
2. le cas sans connexion ;
3. le cas sans autorisation ;
4. le cas avec un document absent ;
5. le comportement avec deux comptes différents.

## 21. Administration web et desktop

Le même `main.dart` choisit automatiquement l’interface selon la plateforme :

```text
Android ou iOS                    → application mère/partenaire
Chrome, web, macOS, Windows, Linux → administration
```

La détection repose sur `kIsWeb` et `defaultTargetPlatform`. Les initialisations réservées au mobile, comme les notifications locales, ne sont pas lancées dans l’administration.

### Fonctions administratives disponibles

- connexion Firebase réservée aux administrateurs ;
- tableau de bord avec comptages Firestore réels ;
- consultation et recherche des mères, partenaires et administrateurs ;
- consultation technique des foyers et des liaisons partenaire ;
- consultation et filtrage des publications communautaires ;
- suppression d’une publication avec ses likes et réponses ;
- consultation et suppression des réponses ;
- motif obligatoire pour chaque suppression ;
- journal d’audit immuable ;
- déconnexion ;
- interface responsive pour navigateur et ordinateur.

L’admin ne peut pas consulter les chats privés, conversations Gemini, symptômes, mouvements du bébé ou journaux de santé. Cette limitation protège la confidentialité des familles.

### Créer le premier administrateur

L’application ne permet volontairement pas de créer un administrateur. Cela empêcherait un utilisateur de s’attribuer lui-même des privilèges.

#### Méthode automatisée recommandée

Le script local `scripts/create-admin.js` crée le compte Firebase Authentication et le document `admins/{uid}` en une seule commande. Il utilise Firebase Admin SDK et ne déploie aucune Cloud Function : il reste donc compatible avec Spark.

Préparation unique :

1. ouvrir **Firebase Console > Paramètres du projet > Comptes de service** ;
2. générer une nouvelle clé privée ;
3. conserver le fichier JSON hors du dépôt Git ;
4. installer les dépendances avec `npm install` si nécessaire.

Sur macOS ou Linux :

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/chemin/absolu/service-account.json"
npm run create-admin
```

Le script demande ensuite l’email, le nom et le mot de passe sans afficher le mot de passe dans le terminal. Si l’adresse existe déjà dans Firebase Auth, il active simplement ses droits administrateur sans remplacer son mot de passe.

La clé de compte de service donne des privilèges élevés. Elle ne doit jamais être ajoutée à Git, envoyée avec l’APK ou intégrée à Flutter. Les noms `service-account*.json` sont ignorés par `.gitignore`.

#### Méthode manuelle

Dans Firebase Console :

1. ouvrir **Authentication > Users** ;
2. créer l’utilisateur avec son email et son mot de passe ;
3. copier son UID ;
4. ouvrir **Firestore Database** ;
5. créer la collection `admins` ;
6. créer un document dont l’identifiant est exactement l’UID ;
7. ajouter les champs suivants :

```text
admins/{uidFirebaseAuth}
├── active: true                 booléen
├── name: "Nom administrateur"  texte facultatif
└── email: "admin@example.com"  texte facultatif
```

Seul `active: true` est indispensable pour l’autorisation. Mettre `active` à `false` bloque la prochaine ouverture de l’administration.

Les anciens profils ayant `users/{uid}.role == "admin"` restent acceptés pour compatibilité, mais la collection `admins` est la structure recommandée.

### Lancer l’administration

Dans Chrome :

```bash
flutter run -d chrome
```

Sur macOS :

```bash
flutter run -d macos
```

Pour produire la version web :

```bash
flutter build web
```

### Données administratives ajoutées

```text
admins/{uid}
└── active

auditLogs/{logId}
├── adminId
├── adminEmail
├── action: "delete_post" | "delete_reply"
├── targetType
├── targetId
├── reason
├── metadata
└── createdAt
```

Un journal d’audit peut être créé et lu par un administrateur, mais il ne peut plus être modifié ou supprimé depuis l’application.

### Fonctions volontairement exclues

Les fonctions suivantes n’ont pas été ajoutées, car elles nécessiteraient un backend ou une modification fonctionnelle de l’application mobile :

- suppression d’un compte Firebase Auth par un administrateur ;
- suspension complète d’un compte mobile ;
- notifications push globales ;
- annonces consommées par l’accueil mobile ;
- modification dynamique des conseils actuellement intégrés au mobile.

Cette limite conserve le forfait Firebase Spark et garantit que l’administration ne présente pas de boutons sans effet réel.

## 22. Scénario conseillé pour la soutenance

### Préparation

1. vérifier `.env` ;
2. exécuter `flutter pub get` ;
3. vérifier que les règles Firestore sont déployées ;
4. préparer un compte mère et un compte partenaire ;
5. utiliser deux appareils ou un appareil et Chrome.

### Démonstration

1. se connecter avec la mère ;
2. montrer la semaine de grossesse et Insights ;
3. enregistrer un symptôme ou une session de mouvements ;
4. créer une invitation partenaire ;
5. créer ou connecter le compte partenaire ;
6. créer une tâche et montrer sa synchronisation ;
7. envoyer un message familial et montrer le badge ;
8. publier dans la communauté ;
9. liker et répondre depuis l’autre compte ;
10. poser une question à Gemini ;
11. expliquer les règles de sécurité et la séparation des sessions.

## 23. Dépannage

### Écran blanc au démarrage

Vérifier que `.env` existe et qu’il est déclaré dans `pubspec.yaml`, puis lancer :

```bash
flutter clean
flutter pub get
flutter run
```

### Gemini ne répond pas

Vérifier :

- `GEMINI_API_KEY=...` dans `.env` ;
- l’absence d’espaces autour de `=` ;
- l’accès Internet ;
- l’activation de Gemini API pour la clé ;
- le quota Google AI Studio ;
- le message exact affiché dans la SnackBar.

### `permission-denied` avec Firestore

1. identifier le chemin du document ;
2. vérifier le rôle et le `householdId` de l’utilisateur ;
3. vérifier la règle correspondante ;
4. redéployer les règles.

```bash
firebase deploy --only firestore:rules
```

### Une requête demande un index

Firestore affiche généralement un lien permettant de créer l’index. Cela arrive lorsqu’une requête combine plusieurs filtres ou un filtre et un tri. Avant de créer l’index, vérifier que la requête est réellement nécessaire.

### Une modification de `.env` n’est pas prise en compte

Arrêter complètement `flutter run`, puis relancer. Les assets ne sont pas toujours rechargés par hot reload.

## 24. Améliorations possibles

Pour poursuivre le projet :

- déplacer la clé Gemini derrière un backend sécurisé ;
- ajouter Firebase App Check ;
- ajouter des tests de règles Firestore avec l’émulateur ;
- ajouter des notifications push avec Firebase Cloud Messaging ;
- paginer les publications et les messages ;
- permettre le signalement et la modération des contenus ;
- internationaliser tous les textes avec `flutter_localizations` ;
- adopter Riverpod ou Bloc si la gestion d’état devient plus complexe ;
- améliorer l’accessibilité et les tests sur petites tailles d’écran.

## 25. Résumé à retenir

- Firebase Auth gère l’identité et la session.
- Firestore gère les données métier en temps réel.
- `users` représente les personnes.
- `households` représente la famille et ses données partagées.
- la mère et le partenaire sont deux utilisateurs indépendants.
- les règles Firestore protègent les données côté serveur.
- `StreamBuilder` synchronise l’interface avec Firestore.
- Gemini est appelé par HTTPS depuis un service séparé de l’interface.
- les widgets partagés et le thème assurent un design cohérent.

Cette architecture reste simple pour un projet étudiant tout en séparant correctement l’interface, la logique métier, l’authentification, les données et les services externes.
