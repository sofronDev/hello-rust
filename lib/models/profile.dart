import 'dart:math' as math;

enum Sex {
  male('ชาย'),
  female('หญิง'),
  other('ไม่ระบุ');

  const Sex(this.label);
  final String label;
}

/// How long the user has been lifting weights consistently.
enum Experience {
  none('ยังไม่เคยเล่น', 'เพิ่งเริ่มต้น'),
  under6Months('น้อยกว่า 6 เดือน', 'เคยเล่นบ้าง'),
  sixTo24Months('6 เดือน – 2 ปี', 'เล่นสม่ำเสมอ'),
  twoToFiveYears('2 – 5 ปี', 'มีประสบการณ์'),
  overFiveYears('มากกว่า 5 ปี', 'ช่ำชอง');

  const Experience(this.label, this.hint);
  final String label;
  final String hint;

  TrainingLevel get level => switch (this) {
        Experience.none || Experience.under6Months => TrainingLevel.beginner,
        Experience.sixTo24Months => TrainingLevel.novice,
        Experience.twoToFiveYears => TrainingLevel.intermediate,
        Experience.overFiveYears => TrainingLevel.advanced,
      };
}

enum TrainingLevel {
  beginner('มือใหม่'),
  novice('เริ่มคล่อง'),
  intermediate('ระดับกลาง'),
  advanced('ระดับสูง');

  const TrainingLevel(this.label);
  final String label;
}

enum Goal {
  muscle('เพิ่มกล้ามเนื้อ', 'สร้างกล้าม เพิ่มขนาด'),
  strength('เพิ่มความแข็งแรง', 'ยกได้หนักขึ้น'),
  fatLoss('ลดไขมัน', 'กระชับ รักษากล้ามขณะลดน้ำหนัก'),
  health('สุขภาพทั่วไป', 'แข็งแรง ใช้ชีวิตคล่องตัว');

  const Goal(this.label, this.hint);
  final String label;
  final String hint;
}

enum Limitation {
  knee('เข่า'),
  lowerBack('หลังส่วนล่าง'),
  shoulder('ไหล่');

  const Limitation(this.label);
  final String label;
}

enum GymType {
  full('Full Gym', 'ฟิตเนสเต็มรูปแบบ', 'เครื่องเล่นครบ เคเบิล บาร์เบล ดัมเบล'),
  mid('Mid Gym', 'ยิมขนาดกลาง', 'ดัมเบล บาร์เบล ม้านั่ง เคเบิล/ลาตพูลดาวน์ บาร์โหน'),
  home('Home Gym', 'เล่นที่บ้าน', 'น้ำหนักตัว + อุปกรณ์ที่คุณมี');

  const GymType(this.label, this.labelTh, this.description);
  final String label;
  final String labelTh;
  final String description;
}

enum Equipment {
  bodyweight('น้ำหนักตัว'),
  dumbbell('ดัมเบล'),
  barbell('บาร์เบล'),
  bench('ม้านั่ง'),
  rack('แร็คสควอท'),
  cable('เคเบิล / ลาตพูลดาวน์'),
  machine('เครื่องเล่น (Machine)'),
  pullUpBar('บาร์โหน'),
  band('ยางยืดออกกำลังกาย');

  const Equipment(this.label);
  final String label;

  /// Equipment a user can choose to own at home.
  static const homeChoices = [
    Equipment.dumbbell,
    Equipment.band,
    Equipment.pullUpBar,
    Equipment.bench,
  ];
}

Set<Equipment> equipmentFor(GymType type, Set<Equipment> homeEquipment) {
  switch (type) {
    case GymType.full:
      return Equipment.values.toSet();
    case GymType.mid:
      return {
        Equipment.bodyweight,
        Equipment.dumbbell,
        Equipment.barbell,
        Equipment.bench,
        Equipment.rack,
        Equipment.cable,
        Equipment.pullUpBar,
        Equipment.band,
      };
    case GymType.home:
      return {Equipment.bodyweight, ...homeEquipment};
  }
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.experience,
    required this.goal,
    required this.daysPerWeek,
    required this.sessionMinutes,
    required this.preferredGym,
    this.limitations = const {},
    this.homeEquipment = const {},
  });

  final String name;
  final Sex sex;
  final int age;
  final double weightKg;
  final double heightCm;
  final Experience experience;
  final Goal goal;
  final int daysPerWeek;
  final int sessionMinutes;
  final GymType preferredGym;
  final Set<Limitation> limitations;
  final Set<Equipment> homeEquipment;

  TrainingLevel get level => experience.level;

  double get bmi => weightKg / math.pow(heightCm / 100, 2);

  /// BMI category using the WHO Asia-Pacific cut-offs (used in Thailand).
  String get bmiCategory => bmiCategoryOf(bmi);

  static String bmiCategoryOf(double b) {
    if (b < 18.5) return 'น้ำหนักน้อย';
    if (b < 23) return 'ปกติ';
    if (b < 25) return 'น้ำหนักเกิน';
    if (b < 30) return 'อ้วนระดับ 1';
    return 'อ้วนระดับ 2';
  }

  /// Basal metabolic rate (Mifflin–St Jeor).
  double get bmr {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (sex) {
      Sex.male => base + 5,
      Sex.female => base - 161,
      Sex.other => base - 78,
    };
  }

  /// Estimated daily energy expenditure from BMR and training days.
  double get tdee {
    final factor = daysPerWeek <= 2
        ? 1.375
        : daysPerWeek <= 4
            ? 1.55
            : 1.725;
    return bmr * factor;
  }

  /// Protein target in grams/day. 1.6 g/kg is the point beyond which
  /// Morton et al. (2018) found no further benefit for lean-mass gains.
  /// For BMI ≥ 30 the target is based on a BMI-25 reference weight so it
  /// stays realistic.
  double get proteinGrams {
    final refWeight =
        bmi >= 30 ? 25 * math.pow(heightCm / 100, 2).toDouble() : weightKg;
    return refWeight * 1.6;
  }

  UserProfile copyWith({
    String? name,
    Sex? sex,
    int? age,
    double? weightKg,
    double? heightCm,
    Experience? experience,
    Goal? goal,
    int? daysPerWeek,
    int? sessionMinutes,
    GymType? preferredGym,
    Set<Limitation>? limitations,
    Set<Equipment>? homeEquipment,
  }) {
    return UserProfile(
      name: name ?? this.name,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      experience: experience ?? this.experience,
      goal: goal ?? this.goal,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      sessionMinutes: sessionMinutes ?? this.sessionMinutes,
      preferredGym: preferredGym ?? this.preferredGym,
      limitations: limitations ?? this.limitations,
      homeEquipment: homeEquipment ?? this.homeEquipment,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sex': sex.name,
        'age': age,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'experience': experience.name,
        'goal': goal.name,
        'daysPerWeek': daysPerWeek,
        'sessionMinutes': sessionMinutes,
        'preferredGym': preferredGym.name,
        'limitations': limitations.map((e) => e.name).toList(),
        'homeEquipment': homeEquipment.map((e) => e.name).toList(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] as String? ?? '',
        sex: Sex.values.byName(j['sex'] as String),
        age: (j['age'] as num).toInt(),
        weightKg: (j['weightKg'] as num).toDouble(),
        heightCm: (j['heightCm'] as num).toDouble(),
        experience: Experience.values.byName(j['experience'] as String),
        goal: Goal.values.byName(j['goal'] as String),
        daysPerWeek: (j['daysPerWeek'] as num).toInt(),
        sessionMinutes: (j['sessionMinutes'] as num).toInt(),
        preferredGym: GymType.values.byName(j['preferredGym'] as String),
        limitations: {
          for (final n in (j['limitations'] as List? ?? const []))
            Limitation.values.byName(n as String),
        },
        homeEquipment: {
          for (final n in (j['homeEquipment'] as List? ?? const []))
            Equipment.values.byName(n as String),
        },
      );
}
