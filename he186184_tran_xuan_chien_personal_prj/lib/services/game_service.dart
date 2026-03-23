import 'dart:math';
import '../models/envelope.dart';

class GameService {
  final Random _random = Random();

  List<Envelope> generateGame() {
    List<int> rewards = [100, 50, 50, 10, 10, 0, 0, 20, 30];
    rewards.shuffle();

    return List.generate(
      rewards.length,
          (index) => Envelope(id: index, value: rewards[index]),
    );
  }

  int calculateOffer(List<Envelope> envelopes) {
    final remaining =
    envelopes.where((e) => !e.isOpened).map((e) => e.value).toList();

    final avg =
        remaining.reduce((a, b) => a + b) ~/ remaining.length;

    final factor = 0.8 + _random.nextDouble() * 0.2;

    return (avg * factor).toInt();
  }
}