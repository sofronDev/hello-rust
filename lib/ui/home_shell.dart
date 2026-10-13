import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'programs_page.dart';
import 'progress_page.dart';
import 'today_page.dart';
import 'workout_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  AppState? _state;

  static const _destinations = [
    (Icons.today_outlined, Icons.today, 'วันนี้'),
    (Icons.calendar_view_week_outlined, Icons.calendar_view_week, 'โปรแกรม'),
    (Icons.history_outlined, Icons.history, 'ประวัติ'),
    (Icons.insights_outlined, Icons.insights, 'สถิติ'),
    (Icons.person_outline, Icons.person, 'ฉัน'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.read(context);
    if (state != _state) {
      _state?.tabRequest.removeListener(_onTabRequest);
      _state = state..tabRequest.addListener(_onTabRequest);
      _onTabRequest();
    }
  }

  @override
  void dispose() {
    _state?.tabRequest.removeListener(_onTabRequest);
    super.dispose();
  }

  void _onTabRequest() {
    final requested = _state!.tabRequest.value;
    if (requested == null) return;
    _state!.tabRequest.value = null;
    if (requested != _index) setState(() => _index = requested);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final body = Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _index,
            children: const [
              TodayPage(),
              ProgramsPage(),
              HistoryPage(),
              ProgressPage(),
              ProfilePage(),
            ],
          ),
        ),
        if (state.activeSession != null) const _ActiveWorkoutBanner(),
      ],
    );

    if (width < 640) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final (icon, selected, label) in _destinations)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(selected),
                label: label,
              ),
          ],
        ),
      );
    }

    final extended = width >= 1100;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: extended,
              minExtendedWidth: 200,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fitness_center,
                          color: Colors.white, size: 22),
                    ),
                    if (extended) ...[
                      const SizedBox(width: 10),
                      const Text('FitPlan',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
              destinations: [
                for (final (icon, selected, label) in _destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _ActiveWorkoutBanner extends StatelessWidget {
  const _ActiveWorkoutBanner();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.activeSession!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      child: InkWell(
        onTap: () => openWorkout(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: scheme.onPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'กำลังฝึก: ${session.dayName} · ${session.completedSets}/${session.plannedSets} เซ็ต',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: scheme.onPrimary, fontWeight: FontWeight.w600),
                ),
              ),
              Text('กลับไปบันทึก',
                  style: TextStyle(color: scheme.onPrimary)),
              Icon(Icons.chevron_right, color: scheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
