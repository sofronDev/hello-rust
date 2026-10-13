import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/preset_programs.dart';
import '../models/exercise.dart';
import '../models/profile.dart';
import '../models/program.dart';
import '../models/workout_log.dart';
import '../services/auth_service.dart';
import '../services/program_generator.dart';
import '../services/progression.dart';
import '../services/storage.dart';

class FinishResult {
  const FinishResult(this.session, this.records);

  final WorkoutSession session;
  final List<PersonalRecord> records;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime startOfWeek(DateTime d) =>
    dateOnly(d).subtract(Duration(days: d.weekday - 1));

class AppState extends ChangeNotifier {
  AppState({
    required this.store,
    required this.auth,
    this.generator = const ProgramGenerator(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final KeyValueStore store;
  final AuthService auth;
  final ProgramGenerator generator;
  final DateTime Function() _clock;

  bool ready = false;
  UserProfile? profile;
  List<WorkoutProgram> programs = [];
  String? activeProgramId;
  DateTime? activeSince;

  /// Finished sessions, newest first.
  List<WorkoutSession> sessions = [];
  WorkoutSession? activeSession;
  List<BodyWeightEntry> bodyWeights = [];
  ThemeMode themeMode = ThemeMode.system;

  /// Lets pages ask the home shell to switch tabs.
  final tabRequest = ValueNotifier<int?>(null);
  void requestTab(int index) => tabRequest.value = index;

  Account? get account => auth.currentAccount;
  bool get loggedIn => account != null;
  DateTime get now => _clock();

  String _k(String name) => 'u:${account!.id}:$name';

  // ─────────────────────────── lifecycle ───────────────────────────

  Future<void> init() async {
    final theme = store.getString('settings:theme');
    if (theme != null) {
      themeMode = ThemeMode.values.firstWhere((m) => m.name == theme,
          orElse: () => ThemeMode.system);
    }
    try {
      if (await auth.restoreSession() != null) _loadUserData();
    } catch (_) {
      // Corrupt session data should never block the app from starting.
      await auth.logout();
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await auth.login(email: email, password: password);
    _loadUserData();
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    await auth.register(name: name, email: email, password: password);
    _loadUserData();
    notifyListeners();
  }

  Future<void> logout() async {
    await auth.logout();
    _clearMemory();
    notifyListeners();
  }

  Future<void> deleteAccount(String password) async {
    final prefix = 'u:${account!.id}:';
    await auth.deleteAccount(password);
    for (final key in store.keys().where((k) => k.startsWith(prefix))) {
      await store.remove(key);
    }
    _clearMemory();
    notifyListeners();
  }

  void _clearMemory() {
    profile = null;
    programs = [];
    activeProgramId = null;
    activeSince = null;
    sessions = [];
    activeSession = null;
    bodyWeights = [];
  }

  dynamic _read(String name) {
    final raw = store.getString(_k(name));
    return raw == null ? null : jsonDecode(raw);
  }

  Future<void> _write(String name, Object? value) => value == null
      ? store.remove(_k(name))
      : store.setString(_k(name), jsonEncode(value));

  void _loadUserData() {
    _clearMemory();
    final p = _read('profile');
    if (p != null) profile = UserProfile.fromJson(p as Map<String, dynamic>);
    programs = [
      for (final j in (_read('programs') as List? ?? const []))
        WorkoutProgram.fromJson(j as Map<String, dynamic>),
    ];
    final active = _read('active') as Map<String, dynamic>?;
    if (active != null) {
      activeProgramId = active['id'] as String?;
      final since = active['since'] as String?;
      activeSince = since == null ? null : DateTime.parse(since);
    }
    sessions = [
      for (final j in (_read('sessions') as List? ?? const []))
        WorkoutSession.fromJson(j as Map<String, dynamic>),
    ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final s = _read('activeSession');
    if (s != null) {
      activeSession = WorkoutSession.fromJson(s as Map<String, dynamic>);
    }
    bodyWeights = [
      for (final j in (_read('bodyweights') as List? ?? const []))
        BodyWeightEntry.fromJson(j as Map<String, dynamic>),
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _savePrograms() =>
      _write('programs', programs.map((p) => p.toJson()).toList());

  Future<void> _saveActive() => _write('active', {
        'id': activeProgramId,
        'since': activeSince?.toIso8601String(),
      });

  Future<void> _saveSessions() =>
      _write('sessions', sessions.map((s) => s.toJson()).toList());

  Future<void> _saveBodyWeights() =>
      _write('bodyweights', bodyWeights.map((b) => b.toJson()).toList());

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await store.setString('settings:theme', mode.name);
    notifyListeners();
  }

  // ─────────────────────────── profile & programs ───────────────────────────

  /// Saves the profile and (re)generates the Full/Mid/Home programs. The one
  /// matching the user's usual training place becomes active automatically.
  Future<GeneratedPlan?> saveProfile(UserProfile p,
      {bool regenerate = true}) async {
    profile = p;
    await _write('profile', p.toJson());
    GeneratedPlan? plan;
    if (regenerate) {
      plan = generator.generate(p, now: now);
      programs = [
        ...plan.programs,
        ...programs.where((x) => x.isPreset),
      ];
      await _savePrograms();
      await activateProgram(plan.byType(p.preferredGym));
    }
    notifyListeners();
    return plan;
  }

  List<WorkoutProgram> get generatedPrograms =>
      programs.where((p) => !p.isPreset).toList()
        ..sort((a, b) => a.gymType.index.compareTo(b.gymType.index));

  WorkoutProgram? get activeProgram {
    for (final p in programs) {
      if (p.id == activeProgramId) return p;
    }
    for (final p in presetPrograms) {
      if (p.id == activeProgramId) return p;
    }
    return null;
  }

  Future<void> activateProgram(WorkoutProgram program) async {
    if (!programs.any((p) => p.id == program.id)) {
      programs = [...programs, program];
      await _savePrograms();
    }
    activeProgramId = program.id;
    activeSince = startOfWeek(now);
    await _saveActive();
    notifyListeners();
  }

  /// Persists user edits to a program (e.g. a swapped exercise).
  Future<void> updateProgram(WorkoutProgram program) async {
    programs = [
      for (final p in programs) p.id == program.id ? program : p,
    ];
    await _savePrograms();
    notifyListeners();
  }

  /// 1-based week within the current mesocycle.
  int get cycleWeek {
    final p = activeProgram;
    if (p == null || activeSince == null) return 1;
    final weeks = startOfWeek(now).difference(activeSince!).inDays ~/ 7;
    return weeks.clamp(0, 1 << 20) % p.cycleWeeks + 1;
  }

  bool get isDeloadWeek {
    final p = activeProgram;
    return p != null && cycleWeek == p.cycleWeeks;
  }

  ProgramDay? get todaysDay => activeProgram?.dayForWeekday(now.weekday);

  /// The next not-yet-done training day this week (or the first day).
  ProgramDay? get nextDay {
    final p = activeProgram;
    if (p == null || p.days.isEmpty) return null;
    final doneIds = sessionsInWeek(now).map((s) => s.dayId).toSet();
    for (final d in p.days) {
      if (d.weekday >= now.weekday && !doneIds.contains(d.id)) return d;
    }
    for (final d in p.days) {
      if (!doneIds.contains(d.id)) return d;
    }
    return p.days.first;
  }

  // ─────────────────────────── sessions ───────────────────────────

  WorkoutSession startSession(WorkoutProgram program, ProgramDay day) {
    final deload = program.id == activeProgramId && isDeloadWeek;
    final session = WorkoutSession(
      id: _id(),
      programId: program.id,
      programName: program.name,
      dayId: day.id,
      dayName: day.name,
      startedAt: now,
      deload: deload,
      exercises: [
        for (final pe in day.exercises) _logFor(pe, deload),
      ],
    );
    activeSession = session;
    saveActiveSession();
    notifyListeners();
    return session;
  }

  ExerciseLog _logFor(ProgramExercise pe, bool deload) {
    final sets = deload ? max(1, (pe.sets / 2).ceil()) : pe.sets;
    final last = Progression.lastLog(sessions, pe.exerciseId);
    final suggestion = Progression.suggest(pe.exercise, last,
        repMin: pe.repMin,
        repMax: pe.repMax,
        rir: pe.rir,
        plannedSets: pe.sets);
    return ExerciseLog(
      exerciseId: pe.exerciseId,
      repMin: pe.repMin,
      repMax: pe.repMax,
      rir: deload ? '3–4' : pe.rir,
      restSec: pe.restSec,
      superset: pe.superset,
      sets: [
        for (var i = 0; i < sets; i++) SetLog(weight: suggestion.weight),
      ],
    );
  }

  Suggestion suggestionFor(ExerciseLog log) => Progression.suggest(
        log.exercise,
        Progression.lastLog(sessions, log.exerciseId),
        repMin: log.repMin,
        repMax: log.repMax,
        rir: log.rir,
        plannedSets: log.sets.length,
      );

  void swapExercise(ExerciseLog log, Exercise replacement) {
    log.exerciseId = replacement.id;
    final suggestion = suggestionFor(log);
    for (final s in log.sets) {
      if (!s.done) s.weight = suggestion.weight;
    }
    saveActiveSession();
  }

  void saveActiveSession() {
    final s = activeSession;
    _write('activeSession', s?.toJson());
  }

  /// Persists the in-progress session and refreshes listeners (progress
  /// counters in the banner/header).
  void activeSessionChanged() {
    saveActiveSession();
    notifyListeners();
  }

  Future<FinishResult> finishActiveSession() async {
    final s = activeSession!;
    s.finishedAt = now;
    // Drop empty sets/exercises so history only holds real work.
    for (final e in s.exercises) {
      e.sets = e.completedSets.toList();
    }
    s.exercises = s.exercises.where((e) => e.sets.isNotEmpty).toList();
    final records = Progression.personalRecords(s, sessions);
    sessions = [s, ...sessions];
    activeSession = null;
    await _saveSessions();
    await _write('activeSession', null);
    notifyListeners();
    return FinishResult(s, records);
  }

  Future<void> discardActiveSession() async {
    activeSession = null;
    await _write('activeSession', null);
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    sessions = sessions.where((s) => s.id != id).toList();
    await _saveSessions();
    notifyListeners();
  }

  List<WorkoutSession> sessionsInWeek(DateTime day) {
    final start = startOfWeek(day);
    final end = start.add(const Duration(days: 7));
    return sessions
        .where((s) => !s.startedAt.isBefore(start) && s.startedAt.isBefore(end))
        .toList();
  }

  Map<Muscle, double> muscleSetsInWeek(DateTime day) {
    final out = {for (final m in Muscle.values) m: 0.0};
    for (final s in sessionsInWeek(day)) {
      s.muscleSets.forEach((m, v) => out[m] = out[m]! + v);
    }
    return out;
  }

  /// Consecutive weeks (ending this week or last week) with ≥1 workout.
  int get weekStreak {
    var week = startOfWeek(now);
    if (sessionsInWeek(week).isEmpty) {
      week = week.subtract(const Duration(days: 7));
    }
    var streak = 0;
    while (sessionsInWeek(week).isNotEmpty) {
      streak++;
      week = week.subtract(const Duration(days: 7));
    }
    return streak;
  }

  // ─────────────────────────── body weight ───────────────────────────

  Future<void> addBodyWeight(double kg, DateTime date) async {
    final d = dateOnly(date);
    bodyWeights = [
      ...bodyWeights.where((b) => dateOnly(b.date) != d),
      BodyWeightEntry(date: d, kg: kg),
    ]..sort((a, b) => a.date.compareTo(b.date));
    await _saveBodyWeights();
    // Keep the profile current without regenerating programs.
    if (profile != null && bodyWeights.last.date == d) {
      profile = profile!.copyWith(weightKg: kg);
      await _write('profile', profile!.toJson());
    }
    notifyListeners();
  }

  Future<void> deleteBodyWeight(BodyWeightEntry entry) async {
    bodyWeights = bodyWeights.where((b) => b != entry).toList();
    await _saveBodyWeights();
    notifyListeners();
  }

  // ─────────────────────────── backup ───────────────────────────

  String exportJson() => const JsonEncoder.withIndent(' ').convert({
        'app': 'fitplan',
        'version': 1,
        'exportedAt': now.toIso8601String(),
        'profile': profile?.toJson(),
        'programs': programs.map((p) => p.toJson()).toList(),
        'active': {
          'id': activeProgramId,
          'since': activeSince?.toIso8601String(),
        },
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'bodyweights': bodyWeights.map((b) => b.toJson()).toList(),
      });

  /// Replaces this account's data with a backup. Throws [FormatException]
  /// when the text is not a valid backup.
  Future<void> importJson(String raw) async {
    final Map<String, dynamic> j;
    try {
      j = (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      throw const FormatException('ไม่ใช่ไฟล์สำรองข้อมูลที่ถูกต้อง');
    }
    if (j['app'] != 'fitplan') {
      throw const FormatException('ไม่ใช่ไฟล์สำรองข้อมูลของแอปนี้');
    }
    // Parse everything first so a bad backup leaves current data untouched.
    final UserProfile? newProfile;
    final List<WorkoutProgram> newPrograms;
    final List<WorkoutSession> newSessions;
    final List<BodyWeightEntry> newWeights;
    try {
      newProfile = j['profile'] == null
          ? null
          : UserProfile.fromJson(j['profile'] as Map<String, dynamic>);
      newPrograms = [
        for (final p in j['programs'] as List? ?? const [])
          WorkoutProgram.fromJson(p as Map<String, dynamic>),
      ];
      newSessions = [
        for (final s in j['sessions'] as List? ?? const [])
          WorkoutSession.fromJson(s as Map<String, dynamic>),
      ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      newWeights = [
        for (final b in j['bodyweights'] as List? ?? const [])
          BodyWeightEntry.fromJson(b as Map<String, dynamic>),
      ]..sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {
      throw const FormatException('ข้อมูลสำรองเสียหายหรือไม่ครบ');
    }
    final active = j['active'] as Map<String, dynamic>?;
    profile = newProfile;
    programs = newPrograms;
    sessions = newSessions;
    bodyWeights = newWeights;
    activeProgramId = active?['id'] as String?;
    final since = active?['since'] as String?;
    activeSince = since == null ? null : DateTime.parse(since);
    await _write('profile', profile?.toJson());
    await _savePrograms();
    await _saveActive();
    await _saveSessions();
    await _saveBodyWeights();
    notifyListeners();
  }

  static final _rand = Random();
  static String _id() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_rand.nextInt(1 << 30).toRadixString(36)}';
}

/// Exposes [AppState] to the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
