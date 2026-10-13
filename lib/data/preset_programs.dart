import '../models/profile.dart';
import '../models/program.dart';
import '../services/program_generator.dart';

class PresetSpec {
  const PresetSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.gymType,
    required this.experience,
    required this.goal,
    required this.days,
    required this.minutes,
    this.homeEquipment = const {},
  });

  final String id;
  final String name;
  final String description;
  final GymType gymType;
  final Experience experience;
  final Goal goal;
  final int days;
  final int minutes;
  final Set<Equipment> homeEquipment;
}

/// Ready-made starter programs, built with the same evidence-based generator
/// using a neutral reference profile.
const presetSpecs = <PresetSpec>[
  PresetSpec(
    id: 'preset-beginner-fb3',
    name: 'มือใหม่ Full Body 3 วัน',
    description: 'เริ่มต้นที่ฟิตเนส ฝึกทั้งตัว จันทร์–พุธ–ศุกร์ ~45 นาที',
    gymType: GymType.full,
    experience: Experience.none,
    goal: Goal.muscle,
    days: 3,
    minutes: 45,
  ),
  PresetSpec(
    id: 'preset-express-2',
    name: 'เร่งด่วน 2 วัน × 30 นาที',
    description: 'ขั้นต่ำที่ได้ผลตาม ACSM: ฝึกทุกกล้ามเนื้อหลัก 2 ครั้ง/สัปดาห์',
    gymType: GymType.mid,
    experience: Experience.under6Months,
    goal: Goal.health,
    days: 2,
    minutes: 30,
  ),
  PresetSpec(
    id: 'preset-home-bw3',
    name: 'บอดี้เวทที่บ้าน 3 วัน',
    description: 'ไม่ต้องมีอุปกรณ์ ใช้น้ำหนักตัว เก้าอี้ และพื้นที่เล็ก ๆ',
    gymType: GymType.home,
    experience: Experience.none,
    goal: Goal.health,
    days: 3,
    minutes: 40,
  ),
  PresetSpec(
    id: 'preset-db-fb3',
    name: 'ดัมเบลล้วน 3 วัน',
    description: 'ดัมเบลปรับน้ำหนัก + ม้านั่ง เล่นที่บ้านหรือคอนโด',
    gymType: GymType.home,
    experience: Experience.sixTo24Months,
    goal: Goal.muscle,
    days: 3,
    minutes: 50,
    homeEquipment: {Equipment.dumbbell, Equipment.bench},
  ),
  PresetSpec(
    id: 'preset-ul4',
    name: 'Upper / Lower 4 วัน',
    description: 'สมดุลระหว่างปริมาณและการฟื้นตัว สำหรับคนเล่นสม่ำเสมอ',
    gymType: GymType.full,
    experience: Experience.sixTo24Months,
    goal: Goal.muscle,
    days: 4,
    minutes: 60,
  ),
  PresetSpec(
    id: 'preset-strength3',
    name: 'เน้นแข็งแรง 3 วัน',
    description: 'สควอท เบนช์ เดดลิฟต์ ด้วยน้ำหนัก ≥80% 1RM',
    gymType: GymType.mid,
    experience: Experience.twoToFiveYears,
    goal: Goal.strength,
    days: 3,
    minutes: 75,
  ),
  PresetSpec(
    id: 'preset-ppl6',
    name: 'Push / Pull / Legs 6 วัน',
    description: 'ปริมาณสูงสำหรับผู้มีประสบการณ์ ฝึกแต่ละส่วน 2 ครั้ง/สัปดาห์',
    gymType: GymType.full,
    experience: Experience.overFiveYears,
    goal: Goal.muscle,
    days: 6,
    minutes: 75,
  ),
];

WorkoutProgram buildPreset(PresetSpec spec) {
  final profile = UserProfile(
    name: '',
    sex: Sex.other,
    age: 30,
    weightKg: 65,
    heightCm: 168,
    experience: spec.experience,
    goal: spec.goal,
    daysPerWeek: spec.days,
    sessionMinutes: spec.minutes,
    preferredGym: spec.gymType,
    homeEquipment: spec.homeEquipment,
  );
  return const ProgramGenerator().build(
    profile,
    spec.gymType,
    id: spec.id,
    name: spec.name,
    description: spec.description,
    isPreset: true,
  );
}

final List<WorkoutProgram> presetPrograms = [
  for (final s in presetSpecs) buildPreset(s),
];
