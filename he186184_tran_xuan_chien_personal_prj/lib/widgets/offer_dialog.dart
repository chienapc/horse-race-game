import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/storage_service.dart';

class OfferDialog extends StatelessWidget {
  final StorageService storage = StorageService();

  OfferDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();

    return AlertDialog(
      title: Text("Offer"),
      content: Text("Bán với giá ${game.currentOffer}?"),
      actions: [
        TextButton(
          onPressed: () {
            storage.savePoints(
                storage.getPoints() + game.currentOffer);
            game.sell();
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: Text("Bán"),
        ),
        TextButton(
          onPressed: () {
            final value = game.openSelected();
            storage.savePoints(
                storage.getPoints() + value);
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: Text("Giữ"),
        ),
      ],
    );
  }
}