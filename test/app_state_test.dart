import 'package:fitplan/data/preset_programs.dart';
import 'package:fitplan/models/profile.dart';
import 'package:fitplan/services/auth_service.dart';
import 'package:fitplan/services/storage.dart';
import 'package:fitplan/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = UserProfile(
  name: 'ต้น',
  sex: Sex.male,
  age: 28,
  weightKg: 72,
  heightCm: 172,
  experience: Experience.sixTo24Months,
  goal: Goal.muscle,
  daysPerWeek: 4,
  sessionMinutes: 60,
  preferredGym: GymType.mid,
);

void main() {
  late MemoryStore store;
  late DateTime now;

  AppState newState() => AppState(
        store: store,
        auth: LocalAuthService(store, iterations: 1000),
        clock: () => now,
      );

  setUp(() {
    store = MemoryStore();
    now = DateTime(2026, 10, 13, 18); // Tuesday
  });

  test('saving a profile generates 3 programs and activates the usual gym',
      () async {
    final state = newState();
    await state.init();
    await state.register('ต้น', 'ton@example.com', 'password123');
    expect(state.profile, isNull);
    final plan = await state.saveProfile(_profile);
    expect(plan!.programs.length, 3);
    expect(state.generatedPrograms.map((p) => p.gymType),
        [GymType.full, GymType.mid, GymType.home]);
    expect(state.activeProgram!.gymType, GymType.mid);
    expect(state.todaysDay!.name, 'Lower A'); // Tuesday
  });

  test('a finished workout persists and reloads after restart', () async {
    final state = newState();
    await state.init();
    await state.register('ต้น', 'ton@example.com', 'password123');
    await state.saveProfile(_profile);
    final program = state.activeProgram!;
    final session = state.startSession(program, program.days.first);
    final first = session.exercises.first;
    first.sets[0]
      ..weight = 60
      ..reps = 10
      ..done = true;
    state.activeSessionChanged();

    // In-progress session survives a reload.
    final reloaded = newState();
    await reloaded.init();
    expect(reloaded.activeSession?.completedSets, 1);

    now = now.add(const Duration(minutes: 50));
    final result = await reloaded.finishActiveSession();
    expect(result.session.completedSets, 1);
    expect(result.session.exercises.length, 1); // empty exercises dropped

    final again = newState();
    await again.init();
    expect(again.activeSession, isNull);
    expect(again.sessions.single.exercises.single.sets.single.weight, 60);
    expect(again.sessionsInWeek(now).length, 1);
    expect(again.weekStreak, 1);
  });

  test('deload week halves sets', () async {
    final state = newState();
    await state.init();
    await state.register('ต้น', 'ton@example.com', 'password123');
    await state.saveProfile(_profile);
    final program = state.activeProgram!;
    expect(state.cycleWeek, 1);
    now = now.add(Duration(days: 7 * (program.cycleWeeks - 1)));
    expect(state.isDeloadWeek, isTrue);
    final day = program.days.first;
    final session = state.startSession(program, day);
    expect(session.deload, isTrue);
    expect(session.exercises.first.sets.length,
        (day.exercises.first.sets / 2).ceil());
    now = now.add(const Duration(days: 7));
    expect(state.cycleWeek, 1);
  });

  test('accounts are isolated from each other', () async {
    final state = newState();
    await state.init();
    await state.register('A', 'a@example.com', 'password123');
    await state.saveProfile(_profile);
    await state.addBodyWeight(71, now);
    await state.logout();
    await state.register('B', 'b@example.com', 'password123');
    expect(state.profile, isNull);
    expect(state.bodyWeights, isEmpty);
    await state.logout();
    await state.login('a@example.com', 'password123');
    expect(state.profile!.weightKg, 71);
  });

  test('presets can be activated', () async {
    final state = newState();
    await state.init();
    await state.register('ต้น', 'ton@example.com', 'password123');
    await state.saveProfile(_profile);
    await state.activateProgram(presetPrograms.first);
    expect(state.activeProgram!.id, presetPrograms.first.id);
    // Regenerating keeps adopted presets.
    await state.saveProfile(_profile.copyWith(daysPerWeek: 3));
    expect(state.programs.any((p) => p.id == presetPrograms.first.id), isTrue);
  });

  test('backup export/import round-trips and rejects junk', () async {
    final state = newState();
    await state.init();
    await state.register('ต้น', 'ton@example.com', 'password123');
    await state.saveProfile(_profile);
    final program = state.activeProgram!;
    final s = state.startSession(program, program.days.first);
    s.exercises.first.sets.first
      ..weight = 40
      ..reps = 8
      ..done = true;
    await state.finishActiveSession();
    final backup = state.exportJson();

    await state.logout();
    await state.register('ใหม่', 'new@example.com', 'password123');
    await state.importJson(backup);
    expect(state.profile!.name, 'ต้น');
    expect(state.sessions.length, 1);
    expect(state.activeProgram!.id, program.id);

    await expectLater(state.importJson('{"x":1}'), throwsFormatException);
    await expectLater(state.importJson('not json'), throwsFormatException);
    expect(state.sessions.length, 1); // unchanged after a bad import
  });
}
