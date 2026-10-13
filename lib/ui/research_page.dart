import 'package:flutter/material.dart';

import '../data/research.dart';
import 'widgets.dart';

class ResearchPage extends StatelessWidget {
  const ResearchPage({super.key, this.highlight});

  /// Reference key to show first and highlight.
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final refs = [...researchRefs]
      ..sort((a, b) => (b.key == highlight ? 1 : 0) - (a.key == highlight ? 1 : 0));
    return Scaffold(
      appBar: AppBar(title: const Text('งานวิจัยที่ใช้อ้างอิง')),
      body: PageBody(
        children: [
          Text(
            'โปรแกรมทั้งหมดในแอปสร้างจากหลักฐานด้านล่าง โดยยึด ACSM Position Stand 2026 '
            '(ทบทวนงานวิจัย 137 ชิ้น) เป็นแกนหลัก และใช้ meta-analysis ล่าสุดกำหนดรายละเอียด',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 16),
          for (final r in refs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                shape: r.key == highlight
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: scheme.primary, width: 2),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pill(r.short, icon: Icons.menu_book_outlined),
                      const SizedBox(height: 8),
                      Text(r.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(r.finding, style: const TextStyle(height: 1.5)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline,
                                size: 18, color: scheme.onPrimaryContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ในแอป: ${r.applied}',
                                style: TextStyle(
                                    color: scheme.onPrimaryContainer,
                                    height: 1.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        r.citation,
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Text(
            'ข้อมูลนี้เพื่อการศึกษา ไม่ใช่คำแนะนำทางการแพทย์',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
