import 'package:flutter/material.dart';

import '../data/preset_programs.dart';
import '../models/program.dart';
import '../state/app_state.dart';
import 'onboarding_page.dart';
import 'program_detail_page.dart';
import 'theme.dart';
import 'widgets.dart';

class ProgramsPage extends StatelessWidget {
  const ProgramsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile;
    final generated = state.generatedPrograms;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('โปรแกรม')),
      body: PageBody(
        maxWidth: 1100,
        children: [
          if (profile != null) ...[
            Text(
              'จัดให้จากข้อมูลของคุณ',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Pill(profile.level.label, icon: Icons.trending_up),
                Pill(profile.goal.label, icon: Icons.flag_outlined),
                Pill('${profile.daysPerWeek} วัน/สัปดาห์',
                    icon: Icons.event_repeat),
                Pill('${profile.sessionMinutes} นาที/ครั้ง',
                    icon: Icons.timer_outlined),
                for (final l in profile.limitations)
                  Pill('ระวัง${l.label}',
                      icon: Icons.healing_outlined, color: scheme.error),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => OnboardingPage(initial: profile))),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('แก้ไขข้อมูลและจัดโปรแกรมใหม่'),
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (generated.isEmpty)
            const EmptyState(
              icon: Icons.auto_awesome,
              title: 'ยังไม่มีโปรแกรมที่จัดให้',
              message: 'กรอกข้อมูลโปรไฟล์เพื่อให้ระบบจัดโปรแกรม 3 แบบ',
            )
          else
            ResponsiveGrid(
              minItemWidth: 320,
              children: [
                for (final p in generated)
                  ProgramCard(
                    program: p,
                    recommended: profile?.preferredGym == p.gymType,
                  ),
              ],
            ),
          SectionTitle('โปรแกรมเบื้องต้น', top: 32),
          Text(
            'โปรแกรมสำเร็จรูปที่สร้างด้วยหลักการเดียวกัน เลือกใช้ได้ทันทีโดยไม่ต้องกรอกข้อมูล',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            minItemWidth: 320,
            children: [
              for (final p in presetPrograms) ProgramCard(program: p),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lays children out in as many equal columns as fit.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 320,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols =
          (c.maxWidth / minItemWidth).floor().clamp(1, children.length.clamp(1, 4));
      final w = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: w, child: child),
        ],
      );
    });
  }
}

class ProgramCard extends StatelessWidget {
  const ProgramCard({super.key, required this.program, this.recommended = false});

  final WorkoutProgram program;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final active = state.activeProgramId == program.id;
    final color = program.gymType.color;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: active ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5),
          width: active ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProgramDetailPage(program: program))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 6, color: color),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(program.gymType.icon, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              program.isPreset
                                  ? program.gymType.label
                                  : program.gymType.labelTh,
                              style: TextStyle(
                                  color: program.gymType.textColor(context),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              program.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(program.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Pill('${program.daysPerWeek} วัน/สัปดาห์',
                          color: scheme.secondary),
                      Pill('~${program.averageMinutes} นาที',
                          color: scheme.secondary),
                      if (recommended)
                        const Pill('แนะนำสำหรับคุณ',
                            icon: Icons.auto_awesome,
                            color: Color(0xFFE07B39)),
                      if (active)
                        Pill('ใช้งานอยู่',
                            icon: Icons.check_circle, color: scheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
