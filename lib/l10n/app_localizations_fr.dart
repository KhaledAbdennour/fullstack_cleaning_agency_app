// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'CleanSpace';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get welcomeBack => 'Bon retour!';

  @override
  String get login => 'Connexion';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get email => 'E-mail';

  @override
  String get emailOrUsername => 'E-mail ou nom d\'utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié?';

  @override
  String get loginWithGoogle => 'Se connecter avec Google';

  @override
  String get loginWithFacebook => 'Se connecter avec Facebook';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte?';

  @override
  String get createOneNow => 'Créez-en un maintenant';

  @override
  String get fullName => 'Nom complet';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get address => 'Adresse';

  @override
  String get bio => 'Biographie';

  @override
  String get gender => 'Genre';

  @override
  String get birthdate => 'Date de naissance';

  @override
  String get male => 'Homme';

  @override
  String get female => 'Femme';

  @override
  String get iAmA => 'Je suis...';

  @override
  String get client => 'Client';

  @override
  String get agency => 'Agence';

  @override
  String get individualCleaner => 'Nettoyeur individuel';

  @override
  String get agencyName => 'Nom de l\'agence';

  @override
  String get businessId => 'Numéro d\'enregistrement commercial';

  @override
  String get services => 'Services offerts';

  @override
  String get hourlyRate => 'Tarif horaire';

  @override
  String get home => 'Accueil';

  @override
  String get search => 'Recherche';

  @override
  String get profile => 'Profil';

  @override
  String get activeListings => 'Annonces actives';

  @override
  String get pastBookings => 'Réservations passées';

  @override
  String get cleanerTeam => 'Équipe de nettoyeurs';

  @override
  String get jobsCompleted => 'Travaux terminés';

  @override
  String get addNewJob => 'Ajouter un nouveau travail';

  @override
  String get noActiveListings =>
      'Aucune annonce active pour le moment.\nAppuyez sur le bouton + pour ajouter un nouveau travail.';

  @override
  String get noPastBookings => 'Aucune réservation passée pour le moment.';

  @override
  String get noCleaners => 'Aucun nettoyeur dans votre équipe pour le moment.';

  @override
  String postedOn(String date) {
    return 'Publié le: $date';
  }

  @override
  String get edit => 'Modifier';

  @override
  String get pause => 'Pause';

  @override
  String get activate => 'Activer';

  @override
  String get delete => 'Supprimer';

  @override
  String get searchMyListings => 'Rechercher dans mes annonces...';

  @override
  String get filterByStatus => 'Filtrer par statut';

  @override
  String get sortByDate => 'Trier par date';

  @override
  String get all => 'Tout';

  @override
  String get active => 'Actif';

  @override
  String get paused => 'En pause';

  @override
  String get booked => 'Réservé';

  @override
  String get completed => 'Terminé';

  @override
  String get inProgress => 'En cours';

  @override
  String get newestFirst => 'Plus récent en premier';

  @override
  String get oldestFirst => 'Plus ancien en premier';

  @override
  String get recentListings => 'Annonces récentes';

  @override
  String get topAgencies => 'Meilleures agences';

  @override
  String get topCleaners => 'Meilleurs nettoyeurs';

  @override
  String get viewProfile => 'Voir le profil';

  @override
  String get apply => 'Postuler';

  @override
  String get bookNow => 'Réserver maintenant';

  @override
  String get myPosts => 'Mes publications';

  @override
  String get history => 'Historique';

  @override
  String get reviews => 'Avis';

  @override
  String get favorites => 'Favoris';

  @override
  String get logout => 'Déconnexion';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get cancel => 'Annuler';

  @override
  String get retry => 'Réessayer';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String accountCreated(String role) {
    return 'Compte créé en tant que $role!';
  }

  @override
  String get invalidCredentials =>
      'Nom d\'utilisateur ou mot de passe invalide';

  @override
  String get usernameExists => 'Le nom d\'utilisateur existe déjà';

  @override
  String get emailExists => 'L\'e-mail existe déjà';

  @override
  String get phoneExists => 'Le numéro de téléphone existe déjà';

  @override
  String get requiredField => 'Ce champ est obligatoire';

  @override
  String get invalidEmail => 'Veuillez entrer un e-mail valide';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String confirmDelete(String title) {
    return 'Êtes-vous sûr de vouloir supprimer \"$title\"?';
  }

  @override
  String get deleteJob => 'Supprimer le travail';

  @override
  String get jobDeleted => 'Travail supprimé avec succès';

  @override
  String get jobStatusChanged => 'Statut du travail mis à jour';

  @override
  String get profileUpdated => 'Profil mis à jour avec succès';

  @override
  String get goToHome => 'Aller à l\'accueil';

  @override
  String hello(String name) {
    return 'Bonjour $name';
  }
}
