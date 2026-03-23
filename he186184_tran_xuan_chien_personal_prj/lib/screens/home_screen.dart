  import 'package:flutter/material.dart';
  import 'package:he186184_tran_xuan_chien_personal_prj/screens/lobby_screen.dart';
import 'package:he186184_tran_xuan_chien_personal_prj/screens/race_history_screen.dart';
  import 'package:lottie/lottie.dart';
  import 'package:provider/provider.dart';
  import 'package:animate_do/animate_do.dart';
  import '../providers/game_provider.dart';
  import 'game_screen.dart';

  class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});

    @override
    State<HomeScreen> createState() => _HomeScreenState();
  }

  class _HomeScreenState extends State<HomeScreen> {
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Stack(
          children: [
            // 1. NỀN GRADIENT & HỌA TIẾT
            const _BackgroundLayer(),

            // 2. HIỆU ỨNG ĐỘNG (Mây & Hoa)
            const _MovingCloud(top: 100, duration: 20, size: 50),
            const _MovingCloud(top: 250, duration: 35, size: 30),
            const _FallingFlowers(),


            // 3. NỘI DUNG CHÍNH
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Tiêu đề bùng nổ
                  FadeInDown(
                    child: const _ModernTitle(),
                  ),

                  const Spacer(),

                  // KHU VỰC NÚT BẤM
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        _buildMenuButton(
                          context,
                          title: "LÌ XÌ MAY MẮN",
                          icon: "🧧",
                          color: Colors.red.shade700,
                          onTap: () {
                            context.read<GameProvider>().startGame();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen()));
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildMenuButton(
                          context,
                          title: "ĐUA NGỰA CHIẾN",
                          icon: "🏇",
                          color: Colors.amber.shade900,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LobbyScreen()));
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildMenuButton(
                          context,
                          title: "LỊCH SỬ TRẬN",
                          icon: "📜",
                          color: Colors.blueGrey.shade800,
                          isSmall: true,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const RaceHistoryScreen()));
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // WIDGET NÚT BẤM (Đã sửa các thuộc tính lỗi)
    Widget _buildMenuButton(BuildContext context, {
      required String title,
      required String icon,
      required Color color,
      required VoidCallback onTap,
      bool isSmall = false,
    }) {
      return FadeInRight(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: isSmall ? 65 : 85,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.yellowAccent.withOpacity(0.6), width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 6)),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 15),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmall ? 18 : 22,
                      fontWeight: FontWeight.w900, // Black font
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  // --- CÁC COMPONENT PHỤ TRỢ (Dùng code thuần để tránh lỗi thư viện) ---

  class _BackgroundLayer extends StatelessWidget {
    const _BackgroundLayer();
    @override
    Widget build(BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.0,
            colors: [Colors.red.shade600, Colors.red.shade900, Colors.black],
          ),
        ),
      );
    }
  }

  class _ModernTitle extends StatelessWidget {
    const _ModernTitle();
    @override
    Widget build(BuildContext context) {
      return Column(
        children: [
          const Text("NEW YEAR 2026",
              style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, letterSpacing: 5)),
          const SizedBox(height: 10),
          Text(
            "HỘI XUÂN",
            style: TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.w900,
              color: Colors.yellow.shade100,
              shadows: [Shadow(color: Colors.orange.shade900, offset: const Offset(4, 4))],
            ),
          ),
          const Text("BÍNH NGỌ - ĐẠI CÁT",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 3)),
        ],
      );
    }
  }

  class _MovingCloud extends StatefulWidget {
    final double top;
    final int duration;
    final double size;
    const _MovingCloud({required this.top, required this.duration, required this.size});

    @override
    State<_MovingCloud> createState() => _MovingCloudState();
  }

  class _MovingCloudState extends State<_MovingCloud> with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    @override
    void initState() {
      super.initState();
      _controller = AnimationController(vsync: this, duration: Duration(seconds: widget.duration))..repeat();
    }
    @override
    void dispose() { _controller.dispose(); super.dispose(); }
    @override
    Widget build(BuildContext context) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double screenWidth = MediaQuery.of(context).size.width;
          return Positioned(
            top: widget.top,
            left: -150 + (_controller.value * (screenWidth + 300)),
            child: Opacity(opacity: 0.2, child: Text("☁️☁️", style: TextStyle(fontSize: widget.size))),
          );
        },
      );
    }
  }

  class _FallingFlowers extends StatefulWidget {
    const _FallingFlowers();
    @override
    State<_FallingFlowers> createState() => _FallingFlowersState();
  }

  class _FallingFlowersState extends State<_FallingFlowers> with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    @override
    void initState() {
      super.initState();
      _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    }
    @override
    void dispose() { _controller.dispose(); super.dispose(); }
    @override
    Widget build(BuildContext context) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: List.generate(5, (index) {
              double startPos = (index * 80.0);
              return Positioned(
                top: -50 + (_controller.value * 1000) % 800,
                left: startPos + (index * 20),
                child: const Opacity(opacity: 0.3, child: Text("🌸", style: TextStyle(fontSize: 20))),
              );
            }),
          );
        },
      );
    }
  }