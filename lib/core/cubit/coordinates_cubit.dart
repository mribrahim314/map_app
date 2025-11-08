import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:map_app/core/networking/polygone_and_points_repo.dart';
import 'package:maplibre/maplibre.dart';

class CoordinatesCubit extends Cubit<List<Position>> {
  final repo = PointsRepository();
  CoordinatesCubit() : super([]);

  void addPoint(Position point) {
    final updated = List<Position>.from(state)..add(point);
    emit(updated);
  }

  Future<void> getPointsFromFireBase(
    String type, {
    bool CurrentUser = false,
  }) async {
    clear();
    try {
      print("here");
      final points;
      if (CurrentUser == false) {
        points = await repo.fetchPointsByType(type, "points");
      } else {
        points = await repo.fetchPointsByTypeForCurrentUser(type, "points");
      }
      emit(points);
      for (var element in points) {
        print(element.lat);
        print(element.lng);
      }
    } catch (e) {
      print(e);
    }
  }

  bool isEmpty() {
    final list = List<Position>.from(state);
    if (list.length < 3) return true;
    return false;
  }

  void removeLastCondition() {
    final points = List<Position>.from(state);
    if (points.length > 1) {
      points.removeLast();
      emit(points);
    }
  }

  void clear() {
    if (state.isNotEmpty) {
      emit([]);
    }
  }

  void setCoordinate(List<dynamic> coords) {
    try {
      final positions = coords
          .map((point) => Position(
                point['lng'] as double,
                point['lat'] as double,
              ))
          .toList();
      emit(positions);
    } catch (e) {
      print(e);
    }
  }

  void sortClockwise() {
    final points = List<Position>.from(state);
    if (points.length < 3) return;

    // Calculate center point
    double centerX =
        points.map((p) => p.lng).reduce((a, b) => a + b) / points.length;
    double centerY =
        points.map((p) => p.lat).reduce((a, b) => a + b) / points.length;

    // Sort by angle from center
    print("1 ");
    for (var element in points) {
      print(element.lng + element.lat);
    }
    if (points.first == points.last) {
      points.removeLast();
    }
    print("2");
    for (var element in points) {
      print(element.lng + element.lat);
    }
    points.sort((a, b) {
      double angleA = atan2(a.lat - centerY, a.lng - centerX);
      double angleB = atan2(b.lat - centerY, b.lng - centerX);
      return angleA.compareTo(angleB);
    });
    // if (points.length == 6) {
    //   points.add(points[0]);
    // }
    if (points.first != points.last) {
      points.add(points.first);
    }

    print("3");
    for (var element in points) {
      print(element.lng + element.lat);
    }
    emit(points);
  }
}
