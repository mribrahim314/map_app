import 'package:flutter_bloc/flutter_bloc.dart';

class DrawModeCubit extends Cubit<int> {
  DrawModeCubit() : super(0);

  // void toggle() => emit(!state);
  void enablePoint() => emit(1);
  void enablePolygon() => emit(2);
  void disable() => emit(0);
}
