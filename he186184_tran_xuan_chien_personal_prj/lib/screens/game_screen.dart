import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/game_provider.dart';
import '../widgets/envelope_widget.dart';
import '../services/storage_service.dart';

class GameScreen extends StatelessWidget {
  final StorageService storage = StorageService();

  GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Scaffold(
      // Thay đổi 1: Dùng Container làm nền thay vì Scaffold backgroundColor
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade900,
              Colors.red.shade700,
              Colors.orange.shade900
            ],
          ),
        ),
        child: Stack(
          children: [
            // Lớp nền mây bay cho bớt tĩnh (Giống HomeScreen)
            const _MovingCloudBackground(),

            SafeArea(
              child: Column(
                children: [
                  // Thay đổi 2: Tự tạo AppBar để tiệp màu với nền
                  _buildCustomAppBar(context),

                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Hãy chọn 1 bao may mắn nhất!",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellowAccent // Màu vàng cho nổi trên nền đỏ
                      ),
                    ),
                  ),

                  // --- GIỮ NGUYÊN PHẦN HIỂN THỊ MỆNH GIÁ CỦA BẠN ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [100, 50, 20, 10, 0].map((value) {
                        final count = game.envelopes.where((e) => e.value == value && !e.isOpened).length;
                        final isAvailable = count > 0;

                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: isAvailable ? 1.0 : 0.3,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isAvailable ? Colors.yellow[700] : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isAvailable ? Colors.orange : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  "${value}k",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isAvailable ? Colors.black87 : Colors.grey[600],
                                    decoration: isAvailable ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              if (isAvailable)
                                Positioned(
                                  right: -5,
                                  top: -8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                    child: Text(
                                      "$count",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Thay đổi 3: Bọc RepaintBoundary để giảm lag khi xoay lì xì
                  Expanded(
                    child: RepaintBoundary(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: game.envelopes.length,
                        itemBuilder: (context, index) => EnvelopeWidget(index: index),
                      ),
                    ),
                  ),

                  // --- GIỮ NGUYÊN LOGIC NÚT BẤM CỦA BẠN ---
                  if (game.isGameOver)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: BounceInUp(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          onPressed: () => game.startGame(),
                          child: const Text("CHƠI VÁN MỚI",
                              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),

                  if (game.selectedId != null && game.currentOffer == 0 && !game.isGameOver)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: BounceInUp(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          onPressed: () {
                            game.revealTwo();
                            _showOffer(context);
                          },
                          child: const Text("MỞ 2 BAO PHỤ",
                              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET AppBar Tùy Chỉnh ---
  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "THỬ THÁCH BAO LÌ XÌ",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 48), // Giữ cân bằng cho tiêu đề
        ],
      ),
    );
  }

  // --- GIỮ NGUYÊN HÀM _showOffer VÀ _showFinalResult CỦA BẠN ---
  void _showOffer(BuildContext context) {
    final game = context.read<GameProvider>();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9C4),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.amber.shade700, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FadeInLeft(child: const Text("🧨", style: TextStyle(fontSize: 22))),
                  const Text(
                      "💰 NHÀ CÁI ĐỀ NGHỊ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB71C1C),
                          fontSize: 14,
                          letterSpacing: 1.1
                      )
                  ),
                  FadeInRight(child: const Text("🌸", style: TextStyle(fontSize: 22))),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${game.currentOffer}k",
                  style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                      shadows: [Shadow(color: Colors.white, blurRadius: 8)]
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        side: BorderSide(color: Colors.amber.shade800),
                      ),
                      onPressed: () {
                        final val = game.openSelected();
                        storage.savePoints(storage.getPoints() + val);
                        Navigator.pop(context);
                        _showFinalResult(context, val, "Bao của bạn có:");
                      },
                      child: Text("GIỮ LẠI", style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        storage.savePoints(storage.getPoints() + game.currentOffer);
                        game.sell();
                        Navigator.pop(context);
                        _showFinalResult(context, game.currentOffer, "Chốt deal thành công!");
                      },
                      child: const Text("BÁN NGAY", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinalResult(BuildContext context, int finalAmount, String message) {
    final game = context.read<GameProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
          game.finishGame();
        });

        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -50,
                child: Lottie.network(
                  'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json',
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Pulse(
                    duration: const Duration(seconds: 1),
                    child: Text(
                      "${finalAmount}k",
                      style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 15)]
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Đang lật các bao còn lại...",
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              Positioned(
                bottom: -20, left: -20,
                child: FadeInLeft(child: const Text("🌸", style: TextStyle(fontSize: 30))),
              ),
              Positioned(
                bottom: -20, right: -20,
                child: FadeInRight(child: const Text("🧧", style: TextStyle(fontSize: 30))),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Lớp mây trôi nhẹ nhàng
class _MovingCloudBackground extends StatefulWidget {
  const _MovingCloudBackground();

  @override
  State<_MovingCloudBackground> createState() => _MovingCloudBackgroundState();
}

class _MovingCloudBackgroundState extends State<_MovingCloudBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double width = MediaQuery.of(context).size.width;
        return Stack(
          children: [
            Positioned(
              top: 100,
              left: -150 + (_controller.value * (width + 300)),
              child: Opacity(opacity: 0.1, child: const Text("☁️☁️☁️", style: TextStyle(fontSize: 60))),
            ),
            Positioned(
              bottom: 150,
              right: -150 + (_controller.value * (width + 300)),
              child: Opacity(opacity: 0.1, child: const Text("☁️☁️", style: TextStyle(fontSize: 40))),
            ),
          ],
        );
      },
    );
  }
}