import 'profile.dart';

enum Muscle {
  chest('อก'),
  back('หลัง'),
  shoulders('ไหล่'),
  biceps('หน้าแขน'),
  triceps('หลังแขน'),
  quads('ต้นขาหน้า'),
  hamstrings('ต้นขาหลัง'),
  glutes('ก้น'),
  calves('น่อง'),
  abs('แกนกลาง');

  const Muscle(this.label);
  final String label;
}

/// Movement patterns used as "slots" when building a training day.
enum Pattern {
  squat('สควอท / ดันขา'),
  lunge('ขาข้างเดียว'),
  hinge('พับสะโพก'),
  glute('สะโพก / ก้น'),
  horizontalPush('ดันแนวนอน'),
  inclinePush('ดันเฉียงขึ้น'),
  verticalPush('ดันเหนือศีรษะ'),
  horizontalPull('ดึงแนวนอน'),
  verticalPull('ดึงแนวดิ่ง'),
  kneeFlexion('งอเข่า (ต้นขาหลัง)'),
  kneeExtension('เหยียดเข่า (ต้นขาหน้า)'),
  chestFly('เปิดอก'),
  lateralRaise('ไหล่ข้าง'),
  rearDelt('ไหล่หลัง'),
  biceps('หน้าแขน'),
  triceps('หลังแขน'),
  calves('น่อง'),
  core('แกนกลางลำตัว');

  const Pattern(this.label);
  final String label;

  bool get isLowerBody => const {
        Pattern.squat,
        Pattern.lunge,
        Pattern.hinge,
        Pattern.glute,
        Pattern.kneeFlexion,
        Pattern.kneeExtension,
        Pattern.calves,
      }.contains(this);
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.nameTh,
    required this.pattern,
    required this.equipment,
    required this.muscles,
    required this.cue,
    this.compound = false,
    this.difficulty = 1,
    this.pref = 2,
    this.avoidWith = const {},
    this.loadable = true,
    this.lengthened = false,
    this.strengthLift = false,
    this.timed = false,
  });

  final String id;
  final String name;
  final String nameTh;
  final Pattern pattern;

  /// All of these must be available to perform the exercise.
  final Set<Equipment> equipment;

  /// Muscles trained: 1.0 = direct (prime mover), 0.5 = indirect.
  /// Weekly volume is counted with this "fractional" method, which Pelland
  /// et al. found to best predict hypertrophy and strength outcomes.
  final Map<Muscle, double> muscles;

  /// Short Thai coaching cue.
  final String cue;
  final bool compound;

  /// 1 = easy to learn/perform, 3 = demanding (skill or relative strength).
  final int difficulty;

  /// General preference score (0–5): stability, ease of progression and
  /// stimulus per unit of fatigue.
  final int pref;

  /// Excluded when the user reports any of these limitations.
  final Set<Limitation> avoidWith;

  /// False for pure bodyweight moves where weight is not tracked.
  final bool loadable;

  /// Emphasises the stretched (long muscle length) position.
  final bool lengthened;

  /// Classic barbell lift preferred when the goal is maximal strength.
  final bool strengthLift;

  /// Reps are seconds (e.g. planks).
  final bool timed;

  bool availableWith(Set<Equipment> available) =>
      equipment.every(available.contains);

  Muscle get primaryMuscle =>
      muscles.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}
