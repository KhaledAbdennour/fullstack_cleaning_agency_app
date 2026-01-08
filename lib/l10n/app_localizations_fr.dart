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
  String get apply => 'Appliquer';

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

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'Aucune notification';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get notificationPermissionRequired =>
      'L\'autorisation de notification est requise pour recevoir les mises à jour';

  @override
  String get notificationPermissionDenied =>
      'Autorisation de notification refusée';

  @override
  String get newBooking => 'Nouvelle réservation';

  @override
  String get bookingUpdated => 'Réservation mise à jour';

  @override
  String get newJobAvailable => 'Nouveau travail disponible';

  @override
  String get settingsPage => 'Page des paramètres';

  @override
  String get account => 'Compte';

  @override
  String get language => 'Langue';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get payment => 'Paiement';

  @override
  String get paymentMethods => 'Méthodes de paiement';

  @override
  String get support => 'Support';

  @override
  String get helpSupport => 'Aide et support';

  @override
  String get logOut => 'Se déconnecter?';

  @override
  String get logOutMessage =>
      'Êtes-vous sûr de vouloir vous déconnecter de votre compte CleanSpace?';

  @override
  String get yesLogOut => 'Oui, se déconnecter';

  @override
  String get loggedOutSuccessfully => 'Déconnexion réussie';

  @override
  String get addPost => 'Ajouter une publication';

  @override
  String get postNow => 'Publier maintenant';

  @override
  String get jobTitle => 'Titre du travail';

  @override
  String get jobDescription => 'Description du travail';

  @override
  String get budget => 'Budget';

  @override
  String get estimatedDuration => 'Durée estimée';

  @override
  String get hours => 'Heures';

  @override
  String get days => 'Jours';

  @override
  String get selectServiceType => 'Sélectionner le type de service';

  @override
  String get selectProvince => 'Sélectionner la province';

  @override
  String get uploadImages => 'Télécharger des images';

  @override
  String get maxImages => 'Maximum 5 images';

  @override
  String get pleaseLogin => 'Veuillez vous connecter pour publier un travail';

  @override
  String get jobPostedSuccessfully => 'Travail publié avec succès!';

  @override
  String get searchForCleaningServices =>
      'Rechercher des services de nettoyage';

  @override
  String get location => 'Emplacement';

  @override
  String get rating => 'Note';

  @override
  String get price => 'Prix';

  @override
  String get selectWilayasMultiple => 'Sélectionner les wilayas (multiple)';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get deselectAll => 'Tout désélectionner';

  @override
  String get done => 'Terminé';

  @override
  String get ratingRange => 'Plage de notes';

  @override
  String get minRating => 'Note minimale (0-5)';

  @override
  String get maxRating => 'Note maximale (0-5)';

  @override
  String get clear => 'Effacer';

  @override
  String get priceRangeDzd => 'Plage de prix (DZD)';

  @override
  String get minPrice => 'Prix minimum';

  @override
  String get maxPrice => 'Prix maximum';

  @override
  String get noCleanersFound => 'Aucun nettoyeur trouvé';

  @override
  String get availableJobs => 'Travaux disponibles';

  @override
  String get pending => 'En attente';

  @override
  String get assigned => 'Assigné';

  @override
  String get jobDone => 'Terminé';

  @override
  String get cancelled => 'Annulé';

  @override
  String get manageJob => 'Gérer le travail';

  @override
  String get pauseJob => 'Mettre en pause le travail';

  @override
  String get activateJob => 'Activer le travail';

  @override
  String get leaveReview => 'Laisser un avis';

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String get applications => 'Candidatures';

  @override
  String get noApplications => 'Aucune candidature pour le moment';

  @override
  String get assignedWorker => 'Travailleur assigné';

  @override
  String get noWorkerAssigned => 'Aucun travailleur assigné pour le moment';

  @override
  String get overview => 'Aperçu';

  @override
  String get aboutMe => 'À propos de moi';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get personalInformation => 'Informations personnelles';

  @override
  String get enterYourFullName => 'Entrez votre nom complet';

  @override
  String get emailAddress => 'Adresse e-mail';

  @override
  String get enterYourEmail => 'Entrez votre e-mail';

  @override
  String get enterYourPhoneNumber => 'Entrez votre numéro de téléphone';

  @override
  String get profilePicture => 'Photo de profil';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get identityVerification => 'Vérification d\'identité';

  @override
  String get idVerificationMessage =>
      'Pour la sécurité de notre communauté, nous exigeons une vérification d\'identité.';

  @override
  String get uploadId => 'Télécharger la pièce d\'identité';

  @override
  String get idUploadDescription => 'Recto et verso de votre pièce d\'identité';

  @override
  String get accountDetails => 'Détails du compte';

  @override
  String get dateFormatHint => 'mm/jj/aaaa';

  @override
  String get wilayaProvince => 'Wilaya (Province)';

  @override
  String get selectYourWilaya => 'Sélectionnez votre wilaya';

  @override
  String get baladiya => 'Baladiya';

  @override
  String get selectYourBaladiya => 'Sélectionnez votre baladiya (optionnel)';

  @override
  String get enterStreetName =>
      'Entrez le nom de la rue, le numéro du bâtiment, etc.';

  @override
  String get tellUsAboutYourself => 'Parlez-nous de vous...';

  @override
  String get contactForPricing => 'Contacter pour le prix';

  @override
  String get postANewJob => 'Publier un nouveau travail';

  @override
  String get locationWilaya => 'Emplacement (Wilaya)';

  @override
  String get selectYourProvince => 'Sélectionnez votre province';

  @override
  String get yourBudgetDzd => 'Votre budget (DZD)';

  @override
  String get enterYourBudget => 'Entrez votre budget';

  @override
  String get durationExample => 'ex: 3';

  @override
  String get addPhotos => 'Ajouter des photos';

  @override
  String get maximumPhotosAllowed => 'Maximum 5 photos autorisées';

  @override
  String get pleaseSelectServiceType =>
      'Veuillez sélectionner un type de service';

  @override
  String get pleaseSelectLocation => 'Veuillez sélectionner un emplacement';

  @override
  String get pleaseEnterBudget => 'Veuillez entrer un budget';

  @override
  String get pleaseEnterJobDescription =>
      'Veuillez entrer une description du travail';

  @override
  String errorPickingImages(String error) {
    return 'Erreur lors de la sélection des images: $error';
  }

  @override
  String errorPostingJob(String error) {
    return 'Erreur lors de la publication du travail: $error';
  }

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String daysAgo(int count) {
    return 'Il y a $count jours';
  }

  @override
  String get posted => 'Publié';

  @override
  String get weeks => 'Semaines';
}
