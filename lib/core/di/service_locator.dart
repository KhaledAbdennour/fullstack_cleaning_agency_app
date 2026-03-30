import 'package:get_it/get_it.dart';
import '../../data/repositories/notifications/notifications_repo.dart';
import '../../data/repositories/notifications/notifications_repo_db.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<AbstractNotificationsRepo>(
    () => NotificationsRepoDB(),
  );
}
