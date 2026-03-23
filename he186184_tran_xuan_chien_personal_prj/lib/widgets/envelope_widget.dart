import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/game_provider.dart';

class EnvelopeWidget extends StatelessWidget {
  final int index;
  const EnvelopeWidget({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final envelope = game.envelopes[index];
    final bool isSelected = game.selectedId == envelope.id;
    final bool isOpened = envelope.isOpened;

    return GestureDetector(
      onTap: (isOpened || game.isGameOver)
          ? null
          : () => game.selectEnvelope(envelope.id),
      child: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: isOpened ? pi : 0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          builder: (context, val, child) {
            // Xác định đang ở mặt trước hay mặt sau dựa trên góc quay
            bool isBack = val >= pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002) // Độ sâu 3D rõ nét hơn
                ..rotateY(val),
              child: isBack
                  ? _buildBackFace(envelope.value, isSelected)
                  : _buildFrontFace(isSelected),
            );
          },
        ),
      ),
    );
  }

  // --- MẶT TRƯỚC: BAO LÌ XÌ ĐỎ ---
  Widget _buildFrontFace(bool isSelected) {
    return _cardWrapper(
      isSelected: isSelected,
      isBack: false,
      color: isSelected ? Colors.redAccent : Colors.red[700]!,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🧧", style: TextStyle(fontSize: 40)),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.yellowAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "ĐÃ CHỌN",
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  // --- MẶT SAU: THẺ LỘC VÀNG KIM ---
  Widget _buildBackFace(int value, bool isSelected) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi), // Lật lại để chữ không bị ngược
      child: _cardWrapper(
        isSelected: isSelected,
        isBack: true,
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "GIÁ TRỊ",
              style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 1),
            ),
            const SizedBox(height: 2),
            Text(
              "${value}k",
              style: TextStyle(
                color: value == 0 ? Colors.blueGrey : Colors.red.shade800,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.orange.withOpacity(0.3), offset: const Offset(1, 1), blurRadius: 2),
                ],
              ),
            ),
            // Đường gạch ngang trang trí
            Container(
              height: 1.5,
              width: 35,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Colors.amber.shade600, Colors.transparent]),
              ),
            ),
            const Text(
              "🧧 LỘC XUÂN",
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // --- KHUNG CONTAINER CHUNG CHO CẢ 2 MẶT ---
  Widget _cardWrapper({
    required bool isSelected,
    required bool isBack,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        // Hiệu ứng viền vàng kim khi lật mặt sau
        border: Border.all(
          color: isBack ? Colors.amber.shade600 : (isSelected ? Colors.yellowAccent : Colors.transparent),
          width: isBack ? 1.5 : (isSelected ? 3 : 0),
        ),
        // Đổ bóng theo trạng thái
        boxShadow: [
          BoxShadow(
            color: isSelected ? Colors.yellowAccent.withOpacity(0.4) : Colors.black26,
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
        // Gradient ánh kim cho mặt sau
        gradient: isBack
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.yellow.shade50, Colors.amber.shade100, Colors.yellow.shade50],
        )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            if (isBack) ...[
              // Hoa văn mây chìm góc trên
              Positioned(
                top: -12, left: -12,
                child: Opacity(
                  opacity: 0.08,
                  child: Icon(Icons.filter_vintage, size: 55, color: Colors.orange.shade900),
                ),
              ),
              // Hoa đào góc dưới
              const Positioned(
                bottom: 4, right: 4,
                child: Opacity(opacity: 0.4, child: Text("🌸", style: TextStyle(fontSize: 12))),
              ),
              // Viền chỉ phụ bên trong (Inner Border)
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.amber.shade200.withOpacity(0.4), width: 0.8),
                  ),
                ),
              ),
            ],
            Center(child: child),
          ],
        ),
      ),
    );
  }
}