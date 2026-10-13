import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/profile.dart';
import '../services/program_generator.dart';
import '../state/app_state.dart';
import 'theme.dart';
import 'widgets.dart';

/// Multi-step profile form. Used for first-time setup and for editing.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.initial});

  final UserProfile? initial;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _bodyForm = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _weight;
  late final TextEditingController _height;

  int _step = 0;
  bool _saving = false;
  late Sex _sex;
  Experience? _experience;
  Goal? _goal;
  late int _days;
  late int _minutes;
  late GymType _gym;
  late Set<Limitation> _limitations;
  late Set<Equipment> _homeEquipment;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    final account = AppScope.read(context).account;
    _name = TextEditingController(text: p?.name ?? account?.name ?? '');
    _age = TextEditingController(text: p == null ? '' : '${p.age}');
    _weight = TextEditingController(text: p == null ? '' : _num(p.weightKg));
    _height = TextEditingController(text: p == null ? '' : _num(p.heightCm));
    _sex = p?.sex ?? Sex.male;
    _experience = p?.experience;
    _goal = p?.goal;
    _days = p?.daysPerWeek ?? 3;
    _minutes = p?.sessionMinutes ?? 60;
    _gym = p?.preferredGym ?? GymType.full;
    _limitations = {...?p?.limitations};
    _homeEquipment = {...?p?.homeEquipment};
  }

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _next() {
    if (_step == 0 && !_bodyForm.currentState!.validate()) return;
    if (_step == 1 && (_experience == null || _goal == null)) {
      toast(context, 'กรุณาเลือกประสบการณ์และเป้าหมาย');
      return;
    }
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    final profile = UserProfile(
      name: _name.text.trim(),
      sex: _sex,
      age: _parse(_age)!.round(),
      weightKg: _parse(_weight)!,
      heightCm: _parse(_height)!,
      experience: _experience!,
      goal: _goal!,
      daysPerWeek: _days,
      sessionMinutes: _minutes,
      preferredGym: _gym,
      limitations: _limitations,
      homeEquipment: _homeEquipment,
    );
    final state = AppScope.read(context);
    if (_editing &&
        !await confirm(
          context,
          title: 'จัดโปรแกรมใหม่?',
          message:
              'ระบบจะสร้างโปรแกรม Full / Mid / Home ใหม่จากข้อมูลล่าสุด และตั้งโปรแกรม ${_gym.label} เป็นโปรแกรมหลัก '
              'ประวัติการฝึกเดิมยังอยู่ครบ',
          ok: 'จัดโปรแกรมใหม่',
        )) {
      return;
    }
    setState(() => _saving = true);
    await state.saveProfile(profile);
    state.requestTab(1);
    if (!mounted) return;
    if (_editing) Navigator.of(context).pop();
    toast(context,
        'จัดโปรแกรม 3 แบบเรียบร้อย · ตั้ง ${_gym.label} เป็นโปรแกรมหลักให้แล้ว');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titles = ['ข้อมูลร่างกาย', 'ประสบการณ์และเป้าหมาย', 'เวลาและสถานที่'];
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: _editing || _step > 0,
          leading: (_editing || _step > 0)
              ? IconButton(
                  tooltip: 'ย้อนกลับ',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _step > 0
                      ? setState(() => _step--)
                      : Navigator.of(context).maybePop(),
                )
              : null,
          title: Text(_editing ? 'แก้ไขข้อมูล' : 'ตั้งค่าโปรไฟล์'),
          actions: [
            if (!_editing)
              IconButton(
                tooltip: 'ออกจากระบบ',
                icon: const Icon(Icons.logout),
                onPressed: () => AppScope.read(context).logout(),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / 3,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageBody(
                  maxWidth: 640,
                  children: [
                    const SizedBox(height: 8),
                    Text('ขั้นตอน ${_step + 1}/3',
                        style: TextStyle(color: scheme.primary)),
                    Text(
                      titles[_step],
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: switch (_step) {
                          0 => _bodyStep(),
                          1 => _experienceStep(),
                          _ => _scheduleStep(),
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 608),
          child: Row(
            children: [
              if (_step > 0) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(96, 52)),
                  onPressed: () => setState(() => _step--),
                  child: const Text('ย้อนกลับ'),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _next,
                  icon: Icon(_step < 2 ? Icons.arrow_forward : Icons.auto_awesome),
                  label: Text(_step < 2 ? 'ถัดไป' : 'จัดโปรแกรมให้ฉัน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── step 1 ───────────────────────────

  Widget _bodyStep() {
    String? range(String? v, double min, double max, String label) {
      final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
      if (n == null) return 'กรุณากรอก$label';
      if (n < min || n > max) {
        return '$label ควรอยู่ระหว่าง ${min.toInt()}–${max.toInt()}';
      }
      return null;
    }

    final numberFormatter =
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));
    final w = _parse(_weight);
    final h = _parse(_height);
    final bmi = (w != null && h != null && h > 0) ? w / ((h / 100) * (h / 100)) : null;

    return Form(
      key: _bodyForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'ชื่อเล่น'),
            textInputAction: TextInputAction.next,
            validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
          ),
          const SizedBox(height: 16),
          Text('เพศ', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<Sex>(
            segments: [
              for (final s in Sex.values)
                ButtonSegment(value: s, label: Text(s.label)),
            ],
            selected: {_sex},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() => _sex = v.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _age,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'อายุ', suffixText: 'ปี'),
            validator: (v) => range(v, 13, 90, 'อายุ'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [numberFormatter],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      labelText: 'น้ำหนัก', suffixText: 'kg'),
                  validator: (v) => range(v, 30, 250, 'น้ำหนัก'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _height,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [numberFormatter],
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      labelText: 'ส่วนสูง', suffixText: 'cm'),
                  validator: (v) => range(v, 120, 230, 'ส่วนสูง'),
                ),
              ),
            ],
          ),
          if (bmi != null && bmi > 10 && bmi < 80) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.monitor_weight_outlined),
                title: Text('BMI ${bmi.toStringAsFixed(1)}'),
                subtitle: Text(UserProfile.bmiCategoryOf(bmi)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────── step 2 ───────────────────────────

  Widget _experienceStep() {
    final scheme = Theme.of(context).colorScheme;
    final goalIcons = {
      Goal.muscle: Icons.fitness_center,
      Goal.strength: Icons.bolt,
      Goal.fatLoss: Icons.local_fire_department_outlined,
      Goal.health: Icons.favorite_outline,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('เล่นเวทมานานแค่ไหน (อย่างสม่ำเสมอ)?',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final e in Experience.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ChoiceCard(
              selected: _experience == e,
              onTap: () => setState(() => _experience = e),
              title: e.label,
              subtitle: '${e.hint} · ระดับ${e.level.label}',
            ),
          ),
        const SizedBox(height: 16),
        Text('เป้าหมายหลัก', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 480 ? 4 : 2;
          final w = (c.maxWidth - (cols - 1) * 10) / cols;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final g in Goal.values)
                SizedBox(
                  width: w,
                  child: _ChoiceCard(
                    selected: _goal == g,
                    onTap: () => setState(() => _goal = g),
                    icon: goalIcons[g],
                    title: g.label,
                    subtitle: g.hint,
                    vertical: true,
                  ),
                ),
            ],
          );
        }),
        const SizedBox(height: 8),
        Text(
          'ระดับประสบการณ์ใช้กำหนดปริมาณเซ็ต ความยากของท่า และความใกล้ failure',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
        ),
      ],
    );
  }

  // ─────────────────────────── step 3 ───────────────────────────

  Widget _scheduleStep() {
    final scheme = Theme.of(context).colorScheme;
    final beginner = _experience?.level == TrainingLevel.beginner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('ฝึกได้กี่วันต่อสัปดาห์?',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var d = 2; d <= 6; d++)
              ChoiceChip(
                label: Text('$d วัน'),
                selected: _days == d,
                onSelected: (_) => setState(() => _days = d),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'จะได้ตาราง ${ProgramGenerator.splitName(beginner ? _days.clamp(2, 4) : _days)}'
          '${beginner && _days > 4 ? ' 4 วัน + คาร์ดิโอ ${_days - 4} วัน (มือใหม่)' : ''}',
          style: TextStyle(color: scheme.primary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Text('เวลาต่อครั้ง', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in const [30, 45, 60, 75, 90])
              ChoiceChip(
                label: Text('$m นาที'),
                selected: _minutes == m,
                onSelected: (_) => setState(() => _minutes = m),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('ปกติเล่นที่ไหน? (ระบบจะเลือกโปรแกรมนี้ให้อัตโนมัติ)',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final g in GymType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ChoiceCard(
              selected: _gym == g,
              onTap: () => setState(() => _gym = g),
              icon: g.icon,
              iconColor: g.color,
              title: '${g.label} · ${g.labelTh}',
              subtitle: g.description,
            ),
          ),
        const SizedBox(height: 12),
        Text('อุปกรณ์ที่มีที่บ้าน (ใช้จัดโปรแกรม Home Gym)',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in Equipment.homeChoices)
              FilterChip(
                label: Text(e.label),
                selected: _homeEquipment.contains(e),
                onSelected: (v) => setState(() =>
                    v ? _homeEquipment.add(e) : _homeEquipment.remove(e)),
              ),
          ],
        ),
        if (_homeEquipment.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('ไม่มีอุปกรณ์ = ใช้น้ำหนักตัว เก้าอี้ และโต๊ะ',
                style:
                    TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
          ),
        const SizedBox(height: 20),
        Text('มีอาการบาดเจ็บ/ข้อจำกัดหรือไม่?',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final l in Limitation.values)
              FilterChip(
                label: Text(l.label),
                selected: _limitations.contains(l),
                onSelected: (v) => setState(
                    () => v ? _limitations.add(l) : _limitations.remove(l)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.health_and_safety_outlined,
                  color: scheme.onSecondaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'โปรแกรมนี้เป็นคำแนะนำทั่วไป ไม่ใช่คำวินิจฉัยทางการแพทย์ '
                  'หากมีโรคประจำตัว ตั้งครรภ์ หรือมีอาการเจ็บ ควรปรึกษาแพทย์ก่อนเริ่มฝึก',
                  style: TextStyle(
                      color: scheme.onSecondaryContainer, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    this.icon,
    this.iconColor,
    this.vertical = false,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final iconWidget = icon == null
        ? null
        : Icon(icon,
            color: iconColor ?? (selected ? scheme.primary : scheme.onSurfaceVariant));
    final text = Column(
      crossAxisAlignment:
          vertical ? CrossAxisAlignment.start : CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(subtitle,
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
      ],
    );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : (light ? Colors.white : scheme.surfaceContainer),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: vertical
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ?iconWidget,
                      if (iconWidget != null) const SizedBox(height: 8),
                      text,
                    ],
                  )
                : Row(
                    children: [
                      if (iconWidget != null) ...[
                        iconWidget,
                        const SizedBox(width: 12),
                      ],
                      Expanded(child: text),
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected ? scheme.primary : scheme.outline,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
