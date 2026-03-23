import 'package:flutter/material.dart';
import 'package:he186184_tran_xuan_chien_personal_prj/providers/race_history_provider.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();

  runApp(
    MultiProvider(
      providers: [
        // Khai báo GameProvider đã có của bạn
        ChangeNotifierProvider(create: (_) => GameProvider()),

        // QUAN TRỌNG: Thêm khai báo RaceHistoryProvider ở đây
        ChangeNotifierProvider(create: (_) => RaceHistoryProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}