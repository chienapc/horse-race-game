import 'package:flutter/material.dart';
import '../models/envelope.dart';
import '../services/game_service.dart';

class GameProvider extends ChangeNotifier {
  final GameService _gameService = GameService();

  List<Envelope> envelopes = [];
  int? selectedId;
  int currentOffer = 0;
  bool isGameOver = false;

  void startGame() {
    envelopes = _gameService.generateGame();
    selectedId = null;
    currentOffer = 0;
    isGameOver = false;
    notifyListeners();
  }

  void selectEnvelope(int id) {
    selectedId = id;
    notifyListeners();
  }

  void revealTwo() {
    final unopened = envelopes
        .where((e) => !e.isOpened && e.id != selectedId)
        .toList();

    unopened.shuffle();

    for (int i = 0; i < 2; i++) {
      unopened[i].isOpened = true;
    }

    currentOffer = _gameService.calculateOffer(envelopes);
    notifyListeners();
  }

  int openSelected() {
    final selected =
    envelopes.firstWhere((e) => e.id == selectedId);
    selected.isOpened = true;
    isGameOver = true;
    notifyListeners();
    return selected.value;
  }

  void sell() {
    isGameOver = true;
    notifyListeners();
  }

  void finishGame() {
    for (var e in envelopes) {
      e.isOpened = true; // Lật hết tất cả bao
    }
    isGameOver = true;
    notifyListeners();
  }
}