import '../data/exercise_library.dart';
import '../models/exercise.dart';
import '../models/profile.dart';
import '../models/program.dart';

enum SlotRole { primary, secondary, accessory }

class _Slot {
  const _Slot(this.pattern, this.role, this.priority);

  final Pattern pattern;
  final SlotRole role;

  /// Lower number = more important. Higher numbers are trimmed first when a
  /// session would run longer than the user's available time.
  final int priority;
}

class _DayTemplate {
  const _DayTemplate(this.name, this.focus, this.slots);

  final String name;
  final String focus;
  final List<_Slot> slots;
}

const _p = SlotRole.primary;
const _s = SlotRole.secondary;
const _a = SlotRole.accessory;

const _fullA = _DayTemplate('Full Body A', 'ทั้งตัว · เน้นสควอทและดันแนวนอน', [
  _Slot(Pattern.squat, _p, 1),
  _Slot(Pattern.horizontalPush, _p, 1),
  _Slot(Pattern.horizontalPull, _p, 1),
  _Slot(Pattern.hinge, _s, 2),
  _Slot(Pattern.lateralRaise, _a, 3),
  _Slot(Pattern.triceps, _a, 4),
  _Slot(Pattern.calves, _a, 5),
  _Slot(Pattern.core, _a, 6),
]);

const _fullB = _DayTemplate('Full Body B', 'ทั้งตัว · เน้นพับสะโพกและดึงแนวดิ่ง', [
  _Slot(Pattern.hinge, _p, 1),
  _Slot(Pattern.verticalPull, _p, 1),
  _Slot(Pattern.inclinePush, _p, 1),
  _Slot(Pattern.lunge, _s, 2),
  _Slot(Pattern.kneeFlexion, _a, 3),
  _Slot(Pattern.biceps, _a, 4),
  _Slot(Pattern.rearDelt, _a, 5),
  _Slot(Pattern.core, _a, 6),
]);

const _fullC = _DayTemplate('Full Body C', 'ทั้งตัว · เน้นขาหน้าและไหล่', [
  _Slot(Pattern.squat, _p, 1),
  _Slot(Pattern.horizontalPull, _p, 1),
  _Slot(Pattern.verticalPush, _s, 2),
  _Slot(Pattern.glute, _s, 2),
  _Slot(Pattern.chestFly, _a, 3),
  _Slot(Pattern.kneeFlexion, _a, 4),
  _Slot(Pattern.biceps, _a, 5),
  _Slot(Pattern.calves, _a, 6),
]);

const _upperA = _DayTemplate('Upper A', 'ร่างกายส่วนบน · เน้นดัน/ดึงแนวนอน', [
  _Slot(Pattern.horizontalPush, _p, 1),
  _Slot(Pattern.horizontalPull, _p, 1),
  _Slot(Pattern.verticalPush, _s, 2),
  _Slot(Pattern.verticalPull, _s, 2),
  _Slot(Pattern.lateralRaise, _a, 3),
  _Slot(Pattern.triceps, _a, 4),
  _Slot(Pattern.biceps, _a, 4),
]);

const _upperB = _DayTemplate('Upper B', 'ร่างกายส่วนบน · เน้นดึงแนวดิ่งและอกบน', [
  _Slot(Pattern.verticalPull, _p, 1),
  _Slot(Pattern.inclinePush, _p, 1),
  _Slot(Pattern.horizontalPull, _s, 2),
  _Slot(Pattern.chestFly, _a, 3),
  _Slot(Pattern.lateralRaise, _a, 3),
  _Slot(Pattern.biceps, _a, 4),
  _Slot(Pattern.triceps, _a, 4),
  _Slot(Pattern.rearDelt, _a, 5),
]);

const _lowerA = _DayTemplate('Lower A', 'ร่างกายส่วนล่าง · เน้นต้นขาหน้า', [
  _Slot(Pattern.squat, _p, 1),
  _Slot(Pattern.hinge, _s, 2),
  _Slot(Pattern.kneeExtension, _a, 3),
  _Slot(Pattern.kneeFlexion, _a, 3),
  _Slot(Pattern.calves, _a, 4),
  _Slot(Pattern.core, _a, 5),
]);

const _lowerB = _DayTemplate('Lower B', 'ร่างกายส่วนล่าง · เน้นสะโพกและต้นขาหลัง', [
  _Slot(Pattern.hinge, _p, 1),
  _Slot(Pattern.lunge, _s, 2),
  _Slot(Pattern.glute, _s, 2),
  _Slot(Pattern.kneeFlexion, _a, 3),
  _Slot(Pattern.calves, _a, 4),
  _Slot(Pattern.core, _a, 5),
]);

const _push = _DayTemplate('Push', 'อก · ไหล่ · หลังแขน', [
  _Slot(Pattern.horizontalPush, _p, 1),
  _Slot(Pattern.inclinePush, _s, 2),
  _Slot(Pattern.verticalPush, _s, 2),
  _Slot(Pattern.lateralRaise, _a, 3),
  _Slot(Pattern.chestFly, _a, 3),
  _Slot(Pattern.triceps, _a, 4),
]);

const _pull = _DayTemplate('Pull', 'หลัง · หน้าแขน · ไหล่หลัง', [
  _Slot(Pattern.verticalPull, _p, 1),
  _Slot(Pattern.horizontalPull, _s, 2),
  _Slot(Pattern.horizontalPull, _a, 3),
  _Slot(Pattern.rearDelt, _a, 3),
  _Slot(Pattern.biceps, _a, 4),
  _Slot(Pattern.core, _a, 5),
]);

const _legs = _DayTemplate('Legs', 'ต้นขา · สะโพก · น่อง', [
  _Slot(Pattern.squat, _p, 1),
  _Slot(Pattern.hinge, _s, 2),
  _Slot(Pattern.lunge, _s, 3),
  _Slot(Pattern.kneeExtension, _a, 3),
  _Slot(Pattern.kneeFlexion, _a, 3),
  _Slot(Pattern.calves, _a, 4),
]);

/// When a slot has no suitable exercise (equipment or limitations), these
/// patterns are tried in order.
const _fallbacks = <Pattern, List<Pattern>>{
  Pattern.inclinePush: [Pattern.horizontalPush],
  Pattern.verticalPush: [Pattern.lateralRaise, Pattern.inclinePush],
  Pattern.verticalPull: [Pattern.horizontalPull],
  Pattern.horizontalPull: [Pattern.verticalPull],
  Pattern.chestFly: [Pattern.horizontalPush, Pattern.inclinePush],
  Pattern.lateralRaise: [Pattern.rearDelt, Pattern.verticalPush],
  Pattern.rearDelt: [Pattern.horizontalPull],
  Pattern.kneeExtension: [Pattern.squat, Pattern.lunge],
  Pattern.kneeFlexion: [Pattern.hinge],
  Pattern.glute: [Pattern.hinge, Pattern.lunge],
  Pattern.hinge: [Pattern.glute, Pattern.kneeFlexion],
  Pattern.lunge: [Pattern.squat],
  Pattern.squat: [Pattern.lunge],
  Pattern.biceps: [Pattern.horizontalPull, Pattern.verticalPull],
  Pattern.triceps: [Pattern.horizontalPush],
};

const _weekdays = <int, List<int>>{
  2: [1, 4],
  3: [1, 3, 5],
  4: [1, 2, 4, 5],
  5: [1, 2, 4, 5, 6],
  6: [1, 2, 3, 4, 5, 6],
};

class _Item {
  _Item(this.slot, this.exercise, this.sets);

  final _Slot slot;
  final Exercise exercise;
  int sets;
}

/// The three generated variants plus the one recommended for the user.
class GeneratedPlan {
  const GeneratedPlan(this.programs, this.recommended);

  final List<WorkoutProgram> programs;
  final GymType recommended;

  WorkoutProgram byType(GymType t) =>
      programs.firstWhere((p) => p.gymType == t);
}

/// Builds weekly programs from a [UserProfile].
///
/// Design principles (see `lib/data/research.dart` for citations):
/// * every major muscle trained ≥2×/week (ACSM 2026 Position Stand)
/// * weekly sets per muscle scaled to training age with diminishing returns
///   (Pelland et al. dose–response meta-regressions; fractional set counting)
/// * loads/rep ranges by goal: ≥80% 1RM (≈≤6 reps) for strength, a broad
///   6–20+ range for hypertrophy when sets end near failure (ACSM 2026)
/// * proximity to failure 0–3 RIR (Robinson et al. 2024)
/// * rest ≥90 s for accessories, 2–3 min for main lifts (Singer et al. 2024)
/// * long-muscle-length biased exercise choices for accessories
/// * session length fitted to the user's time budget, using supersets when
///   time is short (Iversen et al. 2021)
/// * planned deload week every 5–6 weeks (Bell et al. 2023 Delphi consensus)
class ProgramGenerator {
  const ProgramGenerator();

  GeneratedPlan generate(UserProfile profile, {DateTime? now}) {
    final stamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final programs = [
      for (final type in GymType.values)
        build(profile, type, id: '${type.name}-$stamp'),
    ];
    return GeneratedPlan(programs, profile.preferredGym);
  }

  /// Effective number of lifting days (beginners are capped at 4 so they can
  /// recover and build the habit; extra days become cardio/active recovery).
  static int liftingDays(UserProfile p) {
    final d = p.daysPerWeek.clamp(2, 6);
    return p.level == TrainingLevel.beginner ? d.clamp(2, 4) : d;
  }

  static String splitName(int days) => switch (days) {
        2 || 3 => 'Full Body',
        4 => 'Upper / Lower',
        5 => 'Upper / Lower + Push / Pull / Legs',
        _ => 'Push / Pull / Legs',
      };

  WorkoutProgram build(
    UserProfile profile,
    GymType type, {
    required String id,
    String? name,
    String? description,
    bool isPreset = false,
  }) {
    final days = liftingDays(profile);
    final templates = switch (days) {
      2 => [_fullA, _fullB],
      3 => [_fullA, _fullB, _fullC],
      4 => [_upperA, _lowerA, _upperB, _lowerB],
      5 => [_upperA, _lowerA, _push, _pull, _legs],
      _ => [_push, _pull, _legs, _push, _pull, _legs],
    };
    final equipment = equipmentFor(type, profile.homeEquipment);
    final usage = <String, int>{};
    final weekdays = _weekdays[days]!;

    final dayItems = <List<_Item>>[];
    for (final t in templates) {
      final items = <_Item>[];
      for (final slot in t.slots) {
        final ex = _pick(slot, profile, equipment, usage, items);
        if (ex == null) continue;
        usage[ex.id] = (usage[ex.id] ?? 0) + 1;
        items.add(_Item(slot, ex, _baseSets(slot.role, profile, days)));
      }
      _trimToTime(items, profile);
      dayItems.add(items);
    }
    _topUpWeekly(dayItems, profile);
    for (final items in dayItems) {
      _fillTime(items, profile);
    }
    _capWeeklyVolume(dayItems, profile);

    final seenNames = <String, int>{};
    final programDays = <ProgramDay>[];
    for (var i = 0; i < templates.length; i++) {
      final t = templates[i];
      // Repeat templates (6-day PPL) get an A/B suffix.
      final count = templates.where((x) => x.name == t.name).length;
      final n = (seenNames[t.name] ?? 0) + 1;
      seenNames[t.name] = n;
      final dayName = count > 1 ? '${t.name} ${n == 1 ? 'A' : 'B'}' : t.name;
      programDays.add(ProgramDay(
        id: '$id-d${i + 1}',
        name: dayName,
        focus: t.focus,
        weekday: weekdays[i],
        exercises: _assemble(dayItems[i], profile),
      ));
    }

    return WorkoutProgram(
      id: id,
      name: name ?? '${type.label} · ${splitName(days)}',
      description: description ?? type.description,
      gymType: type,
      days: programDays,
      equipment: equipment,
      cycleWeeks: cycleWeeksFor(profile.level),
      rationale: _rationale(profile, type, days, programDays),
      isPreset: isPreset,
      level: profile.level,
      goal: profile.goal,
    );
  }

  static int cycleWeeksFor(TrainingLevel level) =>
      level == TrainingLevel.beginner || level == TrainingLevel.novice ? 6 : 5;

  // ─────────────────────────── exercise selection ───────────────────────────

  /// Candidate exercises for [pattern] given equipment and limitations,
  /// best first. Also used for in-workout swaps.
  static List<Exercise> candidates(
    Pattern pattern,
    UserProfile? profile,
    Set<Equipment> equipment, {
    SlotRole role = SlotRole.secondary,
    Map<String, int> usage = const {},
  }) {
    final list = exerciseLibrary
        .where((e) =>
            e.pattern == pattern &&
            e.availableWith(equipment) &&
            (profile == null ||
                !e.avoidWith.any(profile.limitations.contains)))
        .toList();
    final scores = {
      for (final e in list) e.id: _score(e, role, profile, usage),
    };
    // Stable sort: library order breaks ties.
    final indexed = list.asMap().entries.toList()
      ..sort((a, b) {
        final c = scores[b.value.id]!.compareTo(scores[a.value.id]!);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    return [for (final e in indexed) e.value];
  }

  Exercise? _pick(
    _Slot slot,
    UserProfile profile,
    Set<Equipment> equipment,
    Map<String, int> usage,
    List<_Item> today,
  ) {
    final usedToday = today.map((i) => i.exercise.id).toSet();
    final patterns = [slot.pattern, ...?_fallbacks[slot.pattern]];
    final maxDifficulty = _targetDifficulty(profile) + 1;
    // First pass skips moves far beyond the user's level (e.g. feet-elevated
    // push-ups for a beginner) so a fallback pattern is used instead.
    for (final strict in [true, false]) {
      for (final pattern in patterns) {
        final list = candidates(pattern, profile, equipment,
                role: slot.role, usage: usage)
            .where((e) =>
                !usedToday.contains(e.id) &&
                (!strict || e.difficulty <= maxDifficulty));
        if (list.isNotEmpty) return list.first;
      }
    }
    return null;
  }

  static int _targetDifficulty(UserProfile p) => switch (p.level) {
        TrainingLevel.beginner => p.goal == Goal.strength ? 2 : 1,
        TrainingLevel.novice => 2,
        TrainingLevel.intermediate || TrainingLevel.advanced => 3,
      };

  static bool _preferStable(UserProfile p) => p.age >= 60 || p.bmi >= 30;

  static double _score(
    Exercise e,
    SlotRole role,
    UserProfile? p,
    Map<String, int> usage,
  ) {
    var s = e.pref.toDouble();
    if (e.loadable) s += 1; // easier to progress load over time
    if (e.lengthened && role != SlotRole.primary) s += 0.5;
    if (p != null) {
      final target = _targetDifficulty(p);
      if (e.difficulty > target) s -= (e.difficulty - target) * 2.0;
      // Easy bodyweight moves are too light for trained lifters to reach
      // near-failure in a sensible rep range.
      if (!e.loadable && e.difficulty < target) {
        s -= (target - e.difficulty) * 1.0;
      }
      if (p.goal == Goal.strength && role == SlotRole.primary && e.strengthLift) {
        s += 3;
      }
      if (_preferStable(p)) {
        if (e.equipment.contains(Equipment.machine)) s += 1;
        if (e.difficulty >= 3) s -= 2;
      }
    }
    s -= (usage[e.id] ?? 0) * 2.5; // variety across the week
    return s;
  }

  // ─────────────────────────── volume & time ───────────────────────────

  static int _baseSets(SlotRole role, UserProfile p, int days) {
    var sets = switch ((role, p.level)) {
      (SlotRole.primary, TrainingLevel.advanced) => 4,
      (SlotRole.primary, _) => 3,
      (SlotRole.secondary, TrainingLevel.beginner) => 2,
      (SlotRole.secondary, _) => 3,
      (SlotRole.accessory, TrainingLevel.beginner) => 2,
      (SlotRole.accessory, TrainingLevel.novice) => 2,
      (SlotRole.accessory, _) => 3,
    };
    // Two sessions a week: more sets per session to reach ~10 weekly sets.
    if (days == 2 && role != SlotRole.accessory) sets += 1;
    if (p.goal == Goal.strength && role == SlotRole.primary) sets += 1;
    return sets.clamp(2, 5);
  }

  /// Weekly fractional sets per muscle above which more volume is unlikely
  /// to be worth the extra fatigue for this training age.
  static double weeklyCap(TrainingLevel level) => switch (level) {
        TrainingLevel.beginner => 12,
        TrainingLevel.novice => 16,
        TrainingLevel.intermediate => 20,
        TrainingLevel.advanced => 24,
      };

  /// Weekly target band shown to the user.
  static (int, int) weeklyTarget(TrainingLevel level) => switch (level) {
        TrainingLevel.beginner => (6, 12),
        TrainingLevel.novice => (10, 16),
        TrainingLevel.intermediate => (10, 20),
        TrainingLevel.advanced => (12, 24),
      };

  int _minutes(List<_Item> items, UserProfile p) =>
      estimateMinutes(_assemble(items, p));

  /// Removes slots/sets until the session fits the user's time budget.
  void _trimToTime(List<_Item> items, UserProfile p) {
    final budget = p.sessionMinutes;

    bool dropSlot(bool Function(_Item) where) {
      final candidates = items.where(where).toList()
        ..sort((a, b) => b.slot.priority.compareTo(a.slot.priority));
      if (candidates.isEmpty) return false;
      items.remove(candidates.first);
      return true;
    }

    bool reduceSets(SlotRole role, int floor) {
      final c = items
          .where((i) => i.slot.role == role && i.sets > floor)
          .toList()
        ..sort((a, b) => b.sets.compareTo(a.sets));
      if (c.isEmpty) return false;
      // Trim the least important exercise among those with the most sets.
      final maxSets = c.first.sets;
      final pick = c.where((i) => i.sets == maxSets).toList()
        ..sort((a, b) => b.slot.priority.compareTo(a.slot.priority));
      pick.first.sets--;
      return true;
    }

    final steps = <bool Function()>[
      () => dropSlot((i) => i.slot.priority >= 5),
      () => reduceSets(SlotRole.accessory, 2),
      () => reduceSets(SlotRole.secondary, 2),
      () => dropSlot((i) => i.slot.priority >= 4),
      () => reduceSets(
          SlotRole.primary, p.goal == Goal.strength ? 3 : 2),
      () => dropSlot((i) => i.slot.priority >= 3),
      // Keep every movement (and so ≥2×/week per muscle) before cutting
      // main-lift sets further; 2 sets still build strength (ACSM 2026).
      () => reduceSets(SlotRole.primary, 2),
      () => dropSlot((i) => i.slot.priority >= 2),
    ];

    var guard = 0;
    while (_minutes(items, p) > budget + 2 && guard++ < 60) {
      if (!steps.any((step) => step())) break;
    }
  }

  /// Adds sets where a muscle is below the weekly target band, as long as
  /// the day still fits the time budget.
  void _topUpWeekly(List<List<_Item>> days, UserProfile p) {
    final (lo, _) = weeklyTarget(p.level);
    const majors = {
      Muscle.chest,
      Muscle.back,
      Muscle.shoulders,
      Muscle.quads,
      Muscle.hamstrings,
      Muscle.glutes,
      Muscle.biceps,
      Muscle.triceps,
    };
    for (var guard = 0; guard < 60; guard++) {
      final volume = _volume(days);
      final low = majors.where((m) => (volume[m] ?? 0) < lo).toList()
        ..sort((a, b) => (volume[a] ?? 0).compareTo(volume[b] ?? 0));
      var added = false;
      for (final muscle in low) {
        // Prefer the day/exercise with the fewest sets that still fits.
        final options = <(List<_Item>, _Item)>[
          for (final day in days)
            for (final i in day)
              if ((i.exercise.muscles[muscle] ?? 0) >= 1 && i.sets < 4)
                (day, i),
        ]..sort((a, b) => a.$2.sets.compareTo(b.$2.sets));
        for (final (day, item) in options) {
          item.sets++;
          if (_minutes(day, p) <= p.sessionMinutes + 2) {
            added = true;
            break;
          }
          item.sets--;
        }
        if (added) break;
      }
      if (!added) return;
    }
  }

  /// Uses spare time for extra accessory/secondary sets (trained lifters).
  void _fillTime(List<_Item> items, UserProfile p) {
    if (p.level == TrainingLevel.beginner) return;
    for (var guard = 0; guard < 30; guard++) {
      final addable = items
          .where((i) => i.slot.role != SlotRole.primary && i.sets < 4)
          .toList()
        ..sort((a, b) {
          final c = a.sets.compareTo(b.sets);
          return c != 0 ? c : a.slot.priority.compareTo(b.slot.priority);
        });
      if (addable.isEmpty) return;
      addable.first.sets++;
      if (_minutes(items, p) > p.sessionMinutes - 3) {
        addable.first.sets--;
        return;
      }
    }
  }

  static Map<Muscle, double> _volume(List<List<_Item>> days) {
    final volume = <Muscle, double>{};
    for (final day in days) {
      for (final i in day) {
        i.exercise.muscles.forEach((m, f) {
          volume[m] = (volume[m] ?? 0) + i.sets * f;
        });
      }
    }
    return volume;
  }

  void _capWeeklyVolume(List<List<_Item>> days, UserProfile p) {
    final cap = weeklyCap(p.level);
    for (var guard = 0; guard < 80; guard++) {
      final volume = _volume(days);
      final over = volume.entries.where((e) => e.value > cap).toList();
      if (over.isEmpty) return;
      final muscle = over.first.key;
      // 1) Remove a set from the least important non-primary exercise that
      //    trains this muscle directly.
      _Item? target;
      for (final day in days) {
        for (final i in day) {
          if ((i.exercise.muscles[muscle] ?? 0) < 1 || i.sets <= 2) continue;
          if (i.slot.role == SlotRole.primary) continue;
          if (target == null || i.slot.priority > target.slot.priority) {
            target = i;
          }
        }
      }
      if (target != null) {
        target.sets--;
        continue;
      }
      // 2) Drop an accessory that only landed here as a fallback (e.g. a
      //    row standing in for curls when there is no equipment).
      List<_Item>? dropDay;
      _Item? drop;
      for (final day in days) {
        for (final i in day) {
          if ((i.exercise.muscles[muscle] ?? 0) < 1) continue;
          if (i.slot.role != SlotRole.accessory) continue;
          if (drop == null || i.slot.priority > drop.slot.priority) {
            drop = i;
            dropDay = day;
          }
        }
      }
      if (drop != null) {
        dropDay!.remove(drop);
        continue;
      }
      // 3) Trim main-lift sets down to 2.
      for (final day in days) {
        for (final i in day) {
          if ((i.exercise.muscles[muscle] ?? 0) >= 1 && i.sets > 2) {
            target = i;
          }
        }
      }
      if (target == null) return;
      target.sets--;
    }
  }

  // ─────────────────────────── prescription ───────────────────────────

  List<ProgramExercise> _assemble(List<_Item> items, UserProfile p) {
    final useSupersets = p.sessionMinutes <= 60 || p.goal == Goal.fatLoss;
    final tags = List<String?>.filled(items.length, null);
    if (useSupersets) {
      var next = 0;
      String newTag() => String.fromCharCode(65 + next++);
      for (var i = 0; i + 1 < items.length; i++) {
        if (tags[i] != null) continue;
        final a = items[i];
        final b = items[i + 1];
        if (_canPair(a, b, p)) {
          final t = newTag();
          tags[i] = t;
          tags[i + 1] = t;
          i++;
        }
      }
    }

    return [
      for (var i = 0; i < items.length; i++)
        _prescribe(items[i], p, tags[i]),
    ];
  }

  static const _upperPush = {
    Pattern.horizontalPush,
    Pattern.inclinePush,
    Pattern.verticalPush,
  };
  static const _upperPull = {Pattern.horizontalPull, Pattern.verticalPull};

  /// Pair exercises that don't compete for the same muscles.
  bool _canPair(_Item a, _Item b, UserProfile p) {
    final roles = {a.slot.role, b.slot.role};
    if (roles.contains(SlotRole.primary)) {
      // Main lifts are only paired (alternating sets) when time is very
      // short, and never two lower-body compounds together.
      if (p.sessionMinutes > 30) return false;
      final pa = a.exercise.pattern, pb = b.exercise.pattern;
      if ((_upperPush.contains(pa) && _upperPull.contains(pb)) ||
          (_upperPull.contains(pa) && _upperPush.contains(pb))) {
        return true;
      }
      if (pa.isLowerBody && pb.isLowerBody) return false;
    }
    final shared = a.exercise.muscles.keys
        .where((m) =>
            (a.exercise.muscles[m] ?? 0) >= 1 &&
            (b.exercise.muscles[m] ?? 0) >= 0.5)
        .isNotEmpty;
    final sharedReverse = b.exercise.muscles.keys
        .where((m) =>
            (b.exercise.muscles[m] ?? 0) >= 1 &&
            (a.exercise.muscles[m] ?? 0) >= 0.5)
        .isNotEmpty;
    return !shared && !sharedReverse;
  }

  ProgramExercise _prescribe(_Item item, UserProfile p, String? superset) {
    final e = item.exercise;
    final role = item.slot.role;
    final (repMin, repMax) = repRange(e, role, p.goal, p.level);
    return ProgramExercise(
      exerciseId: e.id,
      sets: item.sets,
      repMin: repMin,
      repMax: repMax,
      rir: rirFor(role, p.goal, p.level),
      restSec: restFor(role, p.goal, p.level, superset != null),
      superset: superset,
      note: p.age >= 60 && role == SlotRole.primary && e.loadable
          ? 'ยกขึ้นเร็วที่สุดอย่างควบคุม ลงช้า 2–3 วินาที (เน้นพลัง)'
          : null,
    );
  }

  static (int, int) repRange(
      Exercise e, SlotRole role, Goal goal, TrainingLevel level) {
    if (e.timed) return level == TrainingLevel.beginner ? (20, 40) : (30, 60);
    if (!e.loadable) {
      // Bodyweight: effort, not load, drives adaptation, so ranges are wide
      // and set by how hard the variation is.
      return switch (e.difficulty) {
        3 => (4, 10),
        2 => (8, 15),
        _ => role == SlotRole.accessory ? (12, 25) : (10, 20),
      };
    }
    const small = {
      Pattern.lateralRaise,
      Pattern.rearDelt,
      Pattern.calves,
      Pattern.core,
    };
    return switch (role) {
      SlotRole.primary => switch (goal) {
          Goal.strength =>
            level == TrainingLevel.beginner ? (6, 8) : (4, 6),
          Goal.muscle => (6, 10),
          Goal.fatLoss || Goal.health => (8, 12),
        },
      SlotRole.secondary => switch (goal) {
          Goal.strength => (6, 10),
          Goal.muscle || Goal.fatLoss => (8, 12),
          Goal.health => (10, 15),
        },
      SlotRole.accessory => small.contains(e.pattern) ? (12, 20) : (10, 15),
    };
  }

  static String rirFor(SlotRole role, Goal goal, TrainingLevel level) {
    if (goal == Goal.health) return '2–3';
    if (level == TrainingLevel.beginner) {
      return role == SlotRole.accessory ? '1–2' : '2–3';
    }
    return switch (role) {
      SlotRole.primary => goal == Goal.strength
          ? '2–3'
          : level == TrainingLevel.advanced
              ? '1–2'
              : '1–3',
      SlotRole.secondary => '1–2',
      SlotRole.accessory => level == TrainingLevel.advanced ? '0–1' : '0–2',
    };
  }

  static int restFor(
      SlotRole role, Goal goal, TrainingLevel level, bool superset) {
    if (superset) return role == SlotRole.primary ? 120 : 90;
    return switch (role) {
      SlotRole.primary => goal == Goal.strength
          ? (level == TrainingLevel.beginner ? 150 : 180)
          : 120,
      SlotRole.secondary => switch (goal) {
          Goal.strength => 150,
          Goal.muscle => 120,
          Goal.fatLoss || Goal.health => 90,
        },
      SlotRole.accessory =>
        goal == Goal.fatLoss || goal == Goal.health ? 75 : 90,
    };
  }

  // ─────────────────────────── rationale ───────────────────────────

  List<String> _rationale(
    UserProfile p,
    GymType type,
    int days,
    List<ProgramDay> programDays,
  ) {
    final (lo, hi) = weeklyTarget(p.level);
    final split = splitName(days);
    final avgMin = programDays.isEmpty
        ? 0
        : (programDays.fold<int>(0, (a, d) => a + d.estimatedMinutes) /
                programDays.length)
            .round();
    final usesSupersets =
        programDays.any((d) => d.exercises.any((e) => e.superset != null));
    final notes = <String>[
      'ตาราง $split $days วัน/สัปดาห์ ให้กล้ามเนื้อหลักทุกส่วนถูกฝึกอย่างน้อย 2 ครั้ง/สัปดาห์ '
          'ตาม ACSM Position Stand 2026 ซึ่งเน้นว่าความสม่ำเสมอสำคัญกว่าโปรแกรมที่ "สมบูรณ์แบบ" [ACSM2026]',
      'ปริมาณเป้าหมาย ~$lo–$hi เซ็ต/กล้ามเนื้อ/สัปดาห์ (นับเซ็ตทางอ้อมเป็นครึ่งเซ็ต) — '
          'กล้ามเนื้อและความแข็งแรงเพิ่มตามปริมาณแต่ผลตอบแทนลดลงเรื่อย ๆ จึงเลือกช่วงที่คุ้มค่าสำหรับระดับ${p.level.label} [PELLAND]',
      switch (p.goal) {
        Goal.strength =>
          'ท่าหลักใช้ 4–6 ครั้ง/เซ็ต (≈80–85% 1RM) เพราะน้ำหนัก ≥80% 1RM เพิ่มความแข็งแรงได้ดีที่สุด และเสริมด้วยท่ารองช่วงครั้งปานกลางเพื่อสร้างกล้าม [ACSM2026]',
        Goal.muscle =>
          'ใช้ช่วงครั้งกว้าง 6–20 ครั้ง กล้ามโตได้ใกล้เคียงกันตั้งแต่น้ำหนักเบาถึงหนัก (~30–100% 1RM) ถ้าแต่ละเซ็ตเข้าใกล้หมดแรงพอ [ACSM2026]',
        Goal.fatLoss =>
          'เวทช่วยรักษามวลกล้ามเนื้อระหว่างลดไขมัน ใช้ 8–15 ครั้ง/เซ็ต และแนะนำคาร์ดิโอ 150–300 นาที/สัปดาห์ร่วมกับโปรตีน ~1.6 g/kg/วัน [WHO2020][MORTON]',
        Goal.health =>
          'เน้นฝึกครบทุกส่วนด้วยน้ำหนักปานกลาง 8–15 ครั้ง ซึ่งเพียงพอต่อสุขภาพ กล้ามเนื้อ และกระดูก ตามคำแนะนำขั้นต่ำ 2 วัน/สัปดาห์ [ACSM2026][WHO2020]',
      },
      'หยุดแต่ละเซ็ตเมื่อเหลือแรงอีก ${rirFor(SlotRole.secondary, p.goal, p.level)} ครั้ง (RIR) — '
          'ยิ่งใกล้ failure กล้ามยิ่งโต แต่ไม่จำเป็นต้องถึง failure ทุกเซ็ต และความแข็งแรงไม่ต่างกันมาก [ROBINSON2024]',
      'พัก ~2 นาทีในท่าหลัก (3 นาทีถ้าเน้นแข็งแรง) และ 75–90 วินาทีในท่าเสริม — การพัก >60 วินาทีให้ผลต่อกล้ามดีกว่าเล็กน้อย แต่เกิน ~90 วินาทีแทบไม่ต่างกัน [SINGER2024]',
      'ท่าเสริมเลือกท่าที่ฝึกในช่วงกล้ามยืด (เช่น incline curl, overhead extension, seated leg curl) ซึ่งหลายงานวิจัยชี้ว่าอาจช่วยให้กล้ามโตกว่า [LML]',
      'ใช้เวลาเฉลี่ย ~$avgMin นาที/ครั้ง ตามเวลาที่คุณมี (${p.sessionMinutes} นาที)'
          '${usesSupersets ? ' โดยจับคู่ซูเปอร์เซ็ตท่าที่ไม่ใช้กล้ามเดียวกันเพื่อประหยัดเวลาโดยไม่ลดคุณภาพ [IVERSEN2021]' : ''}',
      'เพิ่มน้ำหนักแบบ double progression: เมื่อทำได้ครบเลขบนของช่วงครั้งทุกเซ็ต ให้เพิ่มน้ำหนัก ~2.5–5% แอปจะแนะนำให้อัตโนมัติ [PLOTKIN2022]',
      'ทุก ${cycleWeeksFor(p.level)} สัปดาห์ สัปดาห์สุดท้ายเป็น Deload ลดเซ็ตลงครึ่งหนึ่งเพื่อฟื้นตัว [BELL2023]',
    ];
    if (p.daysPerWeek > days) {
      notes.add(
          'มือใหม่จำกัดเวทไว้ $days วัน/สัปดาห์ เพื่อให้ฟื้นตัวทันและสร้างนิสัย อีก ${p.daysPerWeek - days} วันแนะนำเดินเร็ว/คาร์ดิโอเบา ๆ 20–40 นาที');
    }
    if (p.limitations.isNotEmpty) {
      notes.add(
          'ตัดท่าที่มักกระตุ้นอาการบริเวณ${p.limitations.map((l) => l.label).join(', ')} และใช้ท่าทดแทน — หากเจ็บระหว่างเล่นให้หยุดและปรึกษาแพทย์/นักกายภาพ');
    }
    if (p.age >= 60) {
      notes.add(
          'อายุ ≥60 ปี: ท่าหลักเน้นยกขึ้นเร็วอย่างควบคุม (power training ~30–70% 1RM) เพื่อสมรรถภาพในชีวิตประจำวัน และเลือกท่าที่มั่นคง [ACSM2026]');
    }
    if (p.bmi >= 30) {
      notes.add(
          'เลือกท่าที่แรงกระแทกต่ำและมั่นคง ไม่มีการกระโดด เพื่อความปลอดภัยของข้อต่อ');
    }
    switch (type) {
      case GymType.full:
        notes.add(
            'Full Gym: ใช้เครื่องเล่นและเคเบิลเป็นหลักเพราะมั่นคง ปรับน้ำหนักง่าย และให้แรงต้านดีในช่วงกล้ามยืด');
      case GymType.mid:
        notes.add(
            'Mid Gym: ใช้ฟรีเวท (ดัมเบล/บาร์เบล) + เคเบิลพื้นฐาน — ฟรีเวทและเครื่องเล่นให้ผลใกล้เคียงกันเมื่อปริมาณและความหนักเท่ากัน [ACSM2026]');
      case GymType.home:
        notes.add(
            'Home Gym: ยางยืดและน้ำหนักตัวเพิ่มความแข็งแรงได้ใกล้เคียงอุปกรณ์ทั่วไปหากฝึกใกล้หมดแรง — เพิ่มความยากด้วยท่าที่ยากขึ้น ทำช้าลง หรือทำขาเดียว [LOPES2019][ACSM2026]');
    }
    return notes;
  }
}
