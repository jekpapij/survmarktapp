import 'package:flutter/material.dart';

/// Pill kecil buat status (OPEN/PAUSED/CLOSED, FEATURED, Expiring Soon,
/// nanti juga status withdrawal admin/wallet: Pending/Disetujui/Ditolak).
/// Warna nggak di-hardcode di sini — dikasih dari luar (`background`/
/// `foreground`) karena tiap konteks (survey, withdrawal, audit log) punya
/// palet statusnya sendiri; widget ini cuma nge-DRY-in bentuk pill-nya.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.fontSize = 11,
    this.fontFamily = 'JetBrainsMono',
    this.fontWeight = FontWeight.bold,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final double fontSize;

  /// Default JetBrains Mono Bold (pola paling umum di badge Figma), tapi
  /// beberapa badge (mis. CLOSED di `researcher-dashboard`) ternyata pakai
  /// Inter — override lewat sini kalau ketemu pengecualian kayak gitu lagi.
  final String fontFamily;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize - 1, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
