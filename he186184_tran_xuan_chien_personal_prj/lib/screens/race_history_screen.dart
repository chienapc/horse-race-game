import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/race_history_provider.dart';

class RaceHistoryScreen extends StatelessWidget {
  const RaceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<RaceHistoryProvider>().history;

    return Scaffold(
      backgroundColor: const Color(0xFF8B0000), // Đỏ sậm Tết
      appBar: AppBar(
        title: const Text("📜 LỊCH SỬ CHIẾN TRẬN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: history.isEmpty
          ? const Center(child: Text("Chưa có trận nào khai xuân!", style: TextStyle(color: Colors.white70)))
          : ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          final bool isWin = item.winAmount > 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isWin ? Colors.yellowAccent : Colors.white24, width: 1.5),
            ),
            child: ExpansionTile(
              iconColor: Colors.yellowAccent,
              collapsedIconColor: Colors.white,
              title: Row(
                children: [
                  Text(isWin ? "🏆" : "💀", style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('HH:mm - dd/MM').format(item.date),
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Đặt Ngựa Số ${item.selectedHorse + 1}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    "${isWin ? '+' : ''}${item.winAmount} 🧧",
                    style: TextStyle(
                      color: isWin ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              children: [
                const Divider(color: Colors.white24),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("THỨ TỰ VỀ ĐÍCH:", style: TextStyle(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) {
                          int horseIdx = item.finishOrder[i];
                          bool isMyHorse = horseIdx == item.selectedHorse;
                          return Column(
                            children: [
                              Text("Hạng ${i + 1}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isMyHorse ? Colors.yellowAccent : Colors.transparent, width: 2),
                                ),
                                child: const Text("🏇", style: TextStyle(fontSize: 20)),
                              ),
                              Text("Số ${horseIdx + 1}", style: TextStyle(color: isMyHorse ? Colors.yellowAccent : Colors.white, fontWeight: isMyHorse ? FontWeight.bold : FontWeight.bold, fontSize: 12)),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}