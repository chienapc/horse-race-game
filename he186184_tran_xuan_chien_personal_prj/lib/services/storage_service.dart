import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const boxName = "progressBox";

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  int getPoints() {
    return Hive.box(boxName).get("points", defaultValue: 0);
  }

  void savePoints(int points) {
    Hive.box(boxName).put("points", points);
  }
}