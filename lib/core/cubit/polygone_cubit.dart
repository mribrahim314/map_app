import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:map_app/core/networking/polygone_and_points_repo.dart';
import 'package:maplibre/maplibre.dart';

class PolygonState {
  final List<Polygon> mainPolygons;
  final List<Polygon> secondaryPolygons;

  PolygonState({
    this.mainPolygons = const [],
    this.secondaryPolygons = const [],
  });
}

// class PolygonCubit extends Cubit<List<Polygon>> {
//   final repo = PolygonRepository();
//   PolygonCubit() : super([]);

//   Future<void> addPolygon(String type) async {
//     clear();
//     try {
//       final polygons = await repo.fetchPolygonCoordinatesByType(
//         type,
//         "polygones",
//       );
//       emit(polygons);
//     } catch (e) {
//       print(e);
//     }
//   }

//   Future<void> drawOnePolygon(List<dynamic> coords) async {
//     clear();
//     try {
//       final Polygon polygon = Polygon(
//         coordinates: [
//           coords
//               .map((point) => Position(point.longitude, point.latitude))
//               .toList(),
//         ],
//       );
//       emit([polygon]);
//     } catch (e) {
//       print(e);
//     }
//   }

//   void clear() => emit([]);
// }

class PolygonCubit extends Cubit<PolygonState> {
  final repo = PolygonRepository();

  PolygonCubit() : super(PolygonState());

  Future<void> addMainPolygons(String type, {bool CurrentUser = false}) async {
    try {
      final polygons;
      if (CurrentUser == false) {
        print("////////////////////////////////////////////");
        polygons = await repo.fetchPolygonCoordinatesByType(type, "polygones");
        print("start                         hi");
        print(polygons);
        print("end                         hi");
      } else {
        polygons = await repo.fetchPolygonCoordinatesByTypeForCurrentUser(
          type,
          "polygones",
        );
        print(polygons);
      }
      emit(
        PolygonState(
          mainPolygons: polygons,
          secondaryPolygons: state.secondaryPolygons, // preserve existing
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> addSecondaryPolygon(List<dynamic> coords) async {
    try {
      final polygon = Polygon(
        coordinates: [
          coords
              .map((point) => Position(point.longitude, point.latitude))
              .toList(),
        ],
      );
      emit(
        PolygonState(
          mainPolygons: state.mainPolygons,
          secondaryPolygons: [polygon], // or add to existing list if needed
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  void setCoord(List<dynamic> coords) {
    try {
      final polygon = Polygon(
        coordinates: [
          coords
              .map((point) => Position(
                    point['lng'] as double,
                    point['lat'] as double,
                  ))
              .toList(),
        ],
      );
      emit(
        PolygonState(
          mainPolygons: state.mainPolygons,
          secondaryPolygons: [polygon],
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  void clearAll() => emit(PolygonState());

  void clearMain() =>
      emit(PolygonState(secondaryPolygons: state.secondaryPolygons));

  void clearSecondary() => emit(PolygonState(mainPolygons: state.mainPolygons));
}
