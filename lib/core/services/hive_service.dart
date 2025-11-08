import 'package:hive/hive.dart';
import 'package:map_app/core/models/user_model.dart';


class HiveService {
  static const String userBoxName = 'userBox';

  Future<void> saveUser(AppUser user) async {
    final box = Hive.box<AppUser>(userBoxName);
    await box.put('currentUser', user);
  }

  AppUser? getUser() {
    final box = Hive.box<AppUser>(userBoxName);
    return box.get('currentUser');
  }

  Future<void> clearUser() async {
    final box = Hive.box<AppUser>(userBoxName);
    await box.clear();
  }

String getDisplayNameFromHive() {
  final box = Hive.box<AppUser>('userBox');
  final user = box.get('currentUser');

  if (user != null && user.name.isNotEmpty) {
    return user.name;
  }

  return "User";
}

}
