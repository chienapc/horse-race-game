import 'package:flutter/material.dart';

class RaceRecord {
  final DateTime date;
  final int selectedHorse;
  final List<int> finishOrder; // Danh sách index ngựa từ hạng 1 đến 6
  final int betAmount;
  final int winAmount;

  RaceRecord({
    required this.date,
    required this.selectedHorse,
    required this.finishOrder,
    required this.betAmount,
    required this.winAmount,
  });
}

class RaceHistoryProvider extends ChangeNotifier {
  final List<RaceRecord> _history = [];
  List<RaceRecord> get history => _history.reversed.toList();

  void addRecord(RaceRecord record) {
    _history.add(record);
    notifyListeners();
  }
}