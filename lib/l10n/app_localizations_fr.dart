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
  String get enterAgencyName => 'Entrez le nom de l\'agence';

  @override
  String get enterBusinessRegistrationId =>
      'Entrez le numéro d\'enregistrement commercial';

  @override
  String get agencyNameRequired => 'Le nom de l\'agence est requis';

  @override
  String get businessIdRequired =>
      'Le numéro d\'enregistrement commercial est requis';

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
  String get noActiveListings => 'Aucune annonce active pour le moment.';

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
  String get addToTeam => 'Ajouter à l\'équipe';

  @override
  String get invalidProfile => 'Profil invalide';

  @override
  String get cleanerAlreadyInTeam => 'Ce nettoyeur est déjà dans votre équipe';

  @override
  String get cleanerAddedSuccessfully => 'Nettoyeur ajouté avec succès!';

  @override
  String get errorAddingCleaner => 'Erreur lors de l\'ajout du nettoyeur';

  @override
  String get remove => 'Retirer';

  @override
  String get removeCleaner => 'Retirer le nettoyeur';

  @override
  String get areYouSureRemoveCleaner =>
      'Êtes-vous sûr de vouloir retirer ce nettoyeur de votre équipe?';

  @override
  String get cleanerRemovedSuccessfully => 'Nettoyeur retiré avec succès!';

  @override
  String get errorRemovingCleaner => 'Erreur lors du retrait du nettoyeur';

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
  String daysAgo(int days) {
    return 'Il y a $days j';
  }

  @override
  String get posted => 'Publié';

  @override
  String get weeks => 'Semaines';

  @override
  String get homeCleaning => 'Nettoyage résidentiel';

  @override
  String get officeCleaning => 'Nettoyage de bureau';

  @override
  String get specialtyCleaning => 'Nettoyage spécialisé';

  @override
  String get industrialCleaning => 'Nettoyage industriel';

  @override
  String get clickToUpload => 'Cliquez pour télécharger';

  @override
  String get dragAndDrop => ' ou glisser-déposer';

  @override
  String get maximumPhotosReached => 'Maximum de 5 photos atteint';

  @override
  String get egPlaceholder => 'ex: 3';

  @override
  String fromDzdPerHr(String hourlyRate) {
    return 'À partir de $hourlyRate DZD/h';
  }

  @override
  String get available => 'Disponible';

  @override
  String get noActiveListingsYet => 'Aucune annonce active pour le moment.';

  @override
  String get errorLoadingProfile => 'Erreur lors du chargement du profil';

  @override
  String get noUserDataAvailable => 'Aucune donnée utilisateur disponible';

  @override
  String get unknown => 'Inconnu';

  @override
  String get anErrorOccurred => 'Une erreur s\'est produite';

  @override
  String get justNow => 'À l\'instant';

  @override
  String get budgetNegotiable => 'Budget négociable';

  @override
  String get untitledJob => 'Travail sans titre';

  @override
  String areYouSureDeleteJob(String title) {
    return 'Êtes-vous sûr de vouloir supprimer \"$title\" ?';
  }

  @override
  String get verified => 'Vérifié';

  @override
  String partOfAgency(String agency) {
    return 'Fait partie de $agency';
  }

  @override
  String get experience => 'Expérience';

  @override
  String get age => 'Âge';

  @override
  String get languages => 'Langues';

  @override
  String get servicesOffered => 'Services offerts';

  @override
  String get noCleaningHistoryYet =>
      'Aucun historique de nettoyage pour le moment.';

  @override
  String get jobDetails => 'Détails du travail';

  @override
  String get postedBy => 'Publié par';

  @override
  String get description => 'Description';

  @override
  String estimatedHours(int hours) {
    return 'Est. $hours heures';
  }

  @override
  String get submitBid => 'Soumettre une offre';

  @override
  String get yourBidPrice => 'Votre prix d\'offre (DZD)';

  @override
  String get enterBidPrice => 'Entrez votre prix d\'offre';

  @override
  String get messageToClient => 'Message au client (optionnel)';

  @override
  String get enterMessage => 'Entrez votre message';

  @override
  String get pleaseLoginToSubmitBid =>
      'Veuillez vous connecter pour soumettre une offre';

  @override
  String get unableToGetUserId => 'Impossible d\'obtenir l\'ID utilisateur';

  @override
  String get pleaseEnterValidBidPrice =>
      'Veuillez entrer un prix d\'offre valide';

  @override
  String get bidSubmittedSuccessfully => 'Offre soumise avec succès !';

  @override
  String get errorSubmittingBid => 'Erreur lors de la soumission de l\'offre';

  @override
  String get errorSubmittingBidInvalidData =>
      'Erreur lors de la soumission de l\'offre : format de données invalide. Veuillez réessayer.';

  @override
  String get errorSubmittingBidUnexpected =>
      'Erreur lors de la soumission de l\'offre : une erreur inattendue s\'est produite';

  @override
  String get removePhoto => 'Supprimer la photo';

  @override
  String get profilePictureUpdatedSuccessfully =>
      'Photo de profil mise à jour avec succès !';

  @override
  String get profilePictureRemovedSuccessfully =>
      'Photo de profil supprimée avec succès !';

  @override
  String get failedToRemoveProfilePicture =>
      'Échec de la suppression de la photo de profil';

  @override
  String get servicesOfferedLabel => 'Services offerts';

  @override
  String get experienceLevel => 'Niveau d\'expérience';

  @override
  String get selectExperienceLevel => 'Sélectionner le niveau d\'expérience';

  @override
  String get entry => 'Débutant';

  @override
  String get mid => 'Intermédiaire';

  @override
  String get senior => 'Senior';

  @override
  String get hourlyRateDzd => 'Tarif horaire (DZD)';

  @override
  String get pleaseSelectAtLeastOneService =>
      'Veuillez sélectionner au moins un service';

  @override
  String get wilayaRequired => 'La wilaya est requise';

  @override
  String get baladiyaMunicipality => 'Baladiya (Municipalité)';

  @override
  String get streetAddressOptional => 'Adresse de rue (optionnel)';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get areYouSureDeleteAccount =>
      'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et tous vos messages seront supprimés.';

  @override
  String get yesDeleteAccount => 'Oui, supprimer le compte';

  @override
  String get accountDeletedSuccessfully => 'Compte supprimé avec succès';

  @override
  String get settings => 'Paramètres';

  @override
  String get cleaner => 'Nettoyeur';

  @override
  String get individual => 'Individuel';

  @override
  String get agencyProfileComingSoon => 'Profil d\'agence à venir bientôt';

  @override
  String get noPastBookingsYet => 'Aucune réservation passée pour le moment.';

  @override
  String get noCleanersInTeamYet =>
      'Aucun nettoyeur dans votre équipe pour le moment.';

  @override
  String get errorLoadingCleanerProfile =>
      'Erreur lors du chargement du profil du nettoyeur';

  @override
  String get addCleaner => 'Ajouter un nettoyeur';

  @override
  String get requiredServices => 'Services requis';

  @override
  String get yourBid => 'Votre offre';

  @override
  String get yourPriceDa => 'Votre prix (DA)';

  @override
  String get enterYourBidPrice => 'Entrez votre prix d\'offre';

  @override
  String get pleaseEnterBidPrice => 'Veuillez entrer un prix d\'offre';

  @override
  String get pleaseEnterValidPrice => 'Veuillez entrer un prix valide';

  @override
  String get messageOptional => 'Message (optionnel)';

  @override
  String get addShortMessageToClient => 'Ajoutez un court message au client...';

  @override
  String estimatedHoursFormat(int hours) {
    return 'Est. $hours heures';
  }

  @override
  String get noReviewsYet => 'Aucun avis pour le moment.';

  @override
  String get bid => 'Offre';

  @override
  String minutesAgo(int minutes) {
    return 'Il y a $minutes min';
  }

  @override
  String hoursAgo(int hours) {
    return 'Il y a $hours h';
  }

  @override
  String get phone => 'Téléphone';

  @override
  String get partOf => 'Fait partie de';

  @override
  String get allReviews => 'Tous les avis';

  @override
  String get cleaningHistory => 'Historique de nettoyage';

  @override
  String get noCleaningHistoryAvailable =>
      'Aucun historique de nettoyage disponible';

  @override
  String get cleanerIdNotFound => 'ID du nettoyeur introuvable';

  @override
  String get cleaningJob => 'Tâche de nettoyage';

  @override
  String get activePosts => 'Publications actives';

  @override
  String get noPostsYet => 'Aucune publication pour le moment.';

  @override
  String get noActivePosts => 'Aucune publication active pour le moment.';

  @override
  String get myPostsOnlyForClients =>
      'Mes publications ne sont disponibles que pour les clients.';

  @override
  String get activePostsOnlyForClients =>
      'Les publications actives ne sont disponibles que pour les clients.';

  @override
  String reviewsCount(int count) {
    return '$count Avis';
  }

  @override
  String get cleanSpaceFeatures => 'Fonctionnalités CleanSpace';

  @override
  String get everythingYouNeed =>
      'Tout ce dont vous avez besoin dans une seule application';

  @override
  String get findVerifiedCleaners => 'Trouver des nettoyeurs vérifiés';

  @override
  String get browseTrustedProfessionals =>
      'Parcourez des professionnels de confiance avec des profils et des évaluations vérifiés';

  @override
  String get easyBooking => 'Réservation facile';

  @override
  String get postYourJob =>
      'Publiez votre travail et recevez des offres de nettoyeurs qualifiés';

  @override
  String get jobOpportunities => 'Opportunités d\'emploi';

  @override
  String get findStableWork =>
      'Trouvez un travail stable et développez votre entreprise de nettoyage';

  @override
  String get cleaspaceExperience => 'EXPÉRIENCE CLEASPACE';

  @override
  String get allInOnePlatform =>
      'Plateforme tout-en-un pour des services de nettoyage de confiance.';

  @override
  String get verifiedProfessionals => 'Professionnels vérifiés';

  @override
  String get everyCleanerPasses =>
      'Chaque nettoyeur et agence passe des vérifications d\'identité et de qualité pour une confiance totale.';

  @override
  String get smartMatching => 'Correspondance intelligente';

  @override
  String get browseCuratedLists =>
      'Parcourez des listes sélectionnées ou laissez CleanSpace suggérer les meilleurs nettoyeurs adaptés.';

  @override
  String get transparentPricing => 'Tarification transparente';

  @override
  String get seeClearHourlyRates =>
      'Consultez des tarifs horaires clairs avant de réserver. Pas de surprises cachées.';

  @override
  String get cleaspaceAlgeria => 'CLEASPACE ALGÉRIE';

  @override
  String get readyToLaunch => 'Prêt à lancer votre prochain espace propre ?';

  @override
  String get createAccountDescription =>
      'Créez un compte pour réserver des nettoyeurs de confiance, gérer des agences ou offrir vos services de nettoyage au marché croissant de l\'Algérie.';

  @override
  String get next => 'Suivant';

  @override
  String get skipToLogin => 'Passer à la connexion';

  @override
  String get iAlreadyHaveAccount => 'J\'ai déjà un compte';

  @override
  String get createAccountPage => 'Page de création de compte';

  @override
  String get uploadProfilePicture => 'Télécharger la photo de profil';

  @override
  String get uploadAClearPhoto => 'Téléchargez une photo claire';

  @override
  String get photoSelected => 'Photo sélectionnée';
}
