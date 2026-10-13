import 'package:fitplan/data/exercise_library.dart';
import 'package:fitplan/models/workout_log.dart';
import 'package:fitplan/services/progression.dart';
import 'package:flutter_test/flutter_test.dart';

ExerciseLog _log(String id, List<(double?, int)> sets) => ExerciseLog(
      exerciseId: id,
      repMin: 6,
      repMax: 10,
      rir: '1–2',
      restSec: 120,
      sets: [for (final (w, r) in sets) SetLog(weight: w, reps: r, done: true)],
    );

Suggestion _suggest(String id, ExerciseLog? last, {int planned = 3}) =>
    Progression.suggest(exerciseById[id]!, last,
        repMin: 6, repMax: 10, rir: '1–2', plannedSets: planned);

void main() {
  test('first session has no suggested weight', () {
    final s = _suggest('back_squat', null);
    expect(s.weight, isNull);
    expect(s.text, contains('ครั้งแรก'));
  });

  test('adds load only when every planned set hits the top of the range', () {
    final s = _suggest(
        'back_squat', _log('back_squat', [(100, 10), (100, 10), (100, 10)]));
    expect(s.weight, 105); // lower-body barbell: +5 kg
    final upper = _suggest('bench_press',
        _log('bench_press', [(60, 10), (60, 10), (60, 10)]));
    expect(upper.weight, 62.5); // upper-body: +2.5 kg
    final db = _suggest('db_bench_press',
        _log('db_bench_press', [(20, 10), (20, 10), (20, 10)]));
    expect(db.weight, 22); // dumbbells: +2 kg
  });

  test('holds load when not all planned sets were completed at the top', () {
    final partial =
        _suggest('back_squat', _log('back_squat', [(100, 10), (100, 9)]));
    expect(partial.weight, 100);
    final fewer = _suggest(
        'back_squat', _log('back_squat', [(100, 10), (100, 10)]),
        planned: 3);
    expect(fewer.weight, 100);
  });

  test('blank weights carry forward from the set above', () {
    final s = _suggest(
        'back_squat', _log('back_squat', [(100, 10), (null, 10), (null, 10)]));
    expect(s.weight, 105);
  });

  test('reduces load when reps fall well below the range', () {
    final s = _suggest(
        'back_squat', _log('back_squat', [(100, 3), (100, 3), (100, 2)]));
    expect(s.weight, closeTo(92, 0.5));
  });

  test('bodyweight exercises progress by reps/variation', () {
    final s = _suggest('push_up', _log('push_up', [(null, 10), (null, 10), (null, 10)]));
    expect(s.weight, isNull);
    expect(s.text, contains('ยากขึ้น'));
  });

  test('Epley e1RM', () {
    expect(Progression.e1rm(100, 1), 100);
    expect(Progression.e1rm(100, 10), closeTo(133.3, 0.1));
    expect(Progression.e1rm(null, 10), isNull);
  });

  test('personal records compare against earlier sessions only', () {
    WorkoutSession session(String id, DateTime at, double w, int r) =>
        WorkoutSession(
          id: id,
          programId: 'p',
          programName: 'p',
          dayId: 'd',
          dayName: 'd',
          startedAt: at,
          finishedAt: at.add(const Duration(hours: 1)),
          exercises: [_log('bench_press', [(w, r)])],
        );
    final a = session('a', DateTime(2026, 1, 1), 60, 8);
    final b = session('b', DateTime(2026, 1, 8), 65, 8);
    expect(Progression.personalRecords(a, [a]), isEmpty); // first ever
    final prs = Progression.personalRecords(b, [b, a]);
    expect(prs.single.weight, 65);
    final c = session('c', DateTime(2026, 1, 15), 60, 6);
    expect(Progression.personalRecords(c, [c, b, a]), isEmpty);
  });

  test('lastLog picks the most recent finished session', () {
    WorkoutSession s(DateTime at, double w, {bool finished = true}) =>
        WorkoutSession(
          id: '$at',
          programId: 'p',
          programName: 'p',
          dayId: 'd',
          dayName: 'd',
          startedAt: at,
          finishedAt: finished ? at : null,
          exercises: [_log('bench_press', [(w, 8)])],
        );
    final log = Progression.lastLog([
      s(DateTime(2026, 1, 1), 50),
      s(DateTime(2026, 1, 9), 70, finished: false),
      s(DateTime(2026, 1, 5), 60),
    ], 'bench_press');
    expect(log!.sets.single.weight, 60);
  });
}
