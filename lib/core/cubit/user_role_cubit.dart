import 'package:flutter_bloc/flutter_bloc.dart';

class UserRoleCubit extends Cubit<String?> {
  UserRoleCubit() : super(null); // initial role is null (unknown)

  String? get role => state;

  void setRole(String? newRole) {
    emit(newRole);
  }
}