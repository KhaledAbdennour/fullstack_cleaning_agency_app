import 'package:get_it/get_it.dart';
import '../../data/repositories/notifications/notifications_repo.dart';
import '../../data/repositories/notifications/notifications_repo_db.dart';

final getIt = GetIt.instance;

/// Setup service locator (GetIt)
/// Follows teacher's pattern: register all repos/services here
void setupServiceLocator() {
  // Register notifications repository
  getIt.registerLazySingleton<AbstractNotificationsRepo>(
    () => NotificationsRepoDB(),
  );
  
  // Add other repositories here if needed in the future
  // Example:
  // getIt.registerLazySingleton<AbstractProfileRepo>(() => ProfileDB());
}

