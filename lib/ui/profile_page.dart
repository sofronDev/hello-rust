import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/file_io/file_io.dart';
import '../services/progression.dart' show fmtKg;
import '../state/app_state.dart';
import 'format.dart';
import 'onboarding_page.dart';
import 'research_page.dart';
import 'theme.dart';
import 'widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final account = state.account;
    final p = state.profile;
    final scheme = Theme.of(context).colorScheme;
    if (account == null || p == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('ฉัน')),
      body: PageBody(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: Text(
                  p.name.isEmpty ? '?' : p.name.characters.first.toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(account.email,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SectionTitle('ร่างกาย'),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.monitor_weight_outlined,
                  label: 'น้ำหนัก (kg)',
                  value: fmtKg(p.weightKg),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  icon: Icons.height,
                  label: 'ส่วนสูง (cm)',
                  value: fmtKg(p.heightCm),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  icon: Icons.speed,
                  label: p.bmiCategory,
                  value: 'BMI ${p.bmi.toStringAsFixed(1)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.local_fire_department_outlined,
                  color: const Color(0xFFE07B39),
                  label: 'พลังงาน/วัน (โดยประมาณ)',
                  value: '${fmtNumber(p.tdee.round())} kcal',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  icon: Icons.egg_outlined,
                  color: const Color(0xFF5B5BD6),
                  label: 'โปรตีนแนะนำ/วัน',
                  value: '${p.proteinGrams.round()} g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            p.goal == Goal.fatLoss
                ? 'ลดไขมัน: กินน้อยกว่าพลังงานที่ใช้ ~300–500 kcal/วัน และโปรตีน ~1.6 g/kg เพื่อรักษากล้ามเนื้อ'
                : 'พลังงานคำนวณจากสูตร Mifflin–St Jeor × ระดับกิจกรรม · โปรตีน 1.6 g/kg (Morton 2018)',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SectionTitle('ข้อมูลการฝึก'),
          Card(
            child: Column(
              children: [
                _InfoRow(Icons.trending_up, 'ประสบการณ์',
                    '${p.experience.label} (${p.level.label})'),
                _InfoRow(Icons.flag_outlined, 'เป้าหมาย', p.goal.label),
                _InfoRow(Icons.event_repeat, 'ตาราง',
                    '${p.daysPerWeek} วัน/สัปดาห์ · ${p.sessionMinutes} นาที'),
                _InfoRow(p.preferredGym.icon, 'เล่นประจำที่',
                    '${p.preferredGym.label} (${p.preferredGym.labelTh})'),
                _InfoRow(Icons.home_repair_service_outlined, 'อุปกรณ์ที่บ้าน',
                    p.homeEquipment.isEmpty
                        ? 'น้ำหนักตัว'
                        : p.homeEquipment.map((e) => e.label).join(', ')),
                _InfoRow(Icons.healing_outlined, 'ข้อจำกัด',
                    p.limitations.isEmpty
                        ? 'ไม่มี'
                        : p.limitations.map((e) => e.label).join(', ')),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => OnboardingPage(initial: p))),
                      icon: const Icon(Icons.tune),
                      label: const Text('แก้ไขข้อมูลและจัดโปรแกรมใหม่'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('การตั้งค่า'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('งานวิจัยที่ใช้อ้างอิง'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ResearchPage())),
                ),
                const Divider(indent: 56),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.dark_mode_outlined),
                      const SizedBox(width: 16),
                      const Expanded(child: Text('ธีม')),
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto, size: 18),
                              tooltip: 'ตามระบบ'),
                          ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined, size: 18),
                              tooltip: 'สว่าง'),
                          ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined, size: 18),
                              tooltip: 'มืด'),
                        ],
                        selected: {state.themeMode},
                        onSelectionChanged: (v) => state.setThemeMode(v.first),
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.install_mobile_outlined),
                  title: const Text('เพิ่มไอคอนบนหน้าจอโฮม'),
                  subtitle: const Text('เปิดเร็วเหมือนแอป ใช้งานออฟไลน์ได้'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _installGuide(context),
                ),
              ],
            ),
          ),
          const SectionTitle('ข้อมูลของคุณ'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('สำรองข้อมูล'),
                  subtitle: const Text('ดาวน์โหลดไฟล์ไว้ย้ายไปเครื่องอื่น'),
                  onTap: () => _export(context, state),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: const Text('กู้คืนข้อมูล'),
                  subtitle: const Text('นำเข้าจากไฟล์สำรอง (แทนที่ข้อมูลปัจจุบัน)'),
                  onTap: () => _import(context, state),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              if (await confirm(context,
                  title: 'ออกจากระบบ?',
                  message: 'ข้อมูลยังเก็บอยู่ในเครื่องนี้ เข้าสู่ระบบอีกครั้งเพื่อใช้งานต่อ',
                  ok: 'ออกจากระบบ')) {
                await state.logout();
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('ออกจากระบบ'),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            onPressed: () => _deleteAccount(context, state),
            child: const Text('ลบบัญชีและข้อมูลทั้งหมด'),
          ),
          const SizedBox(height: 8),
          Text(
            'FitPlan · ข้อมูลทั้งหมดเก็บในเบราว์เซอร์ของอุปกรณ์นี้',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, AppState state) async {
    final json = state.exportJson();
    final d = state.now;
    final name =
        'fitplan-backup-${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}.json';
    if (fileIoSupported) {
      downloadText(name, json);
      toast(context, 'ดาวน์โหลด $name แล้ว');
    } else {
      await Clipboard.setData(ClipboardData(text: json));
      if (context.mounted) toast(context, 'คัดลอกข้อมูลสำรองไปที่คลิปบอร์ดแล้ว');
    }
  }

  Future<void> _import(BuildContext context, AppState state) async {
    final ok = await confirm(
      context,
      title: 'กู้คืนข้อมูล?',
      message: 'ข้อมูลโปรไฟล์ โปรแกรม และประวัติในบัญชีนี้จะถูกแทนที่ด้วยไฟล์สำรอง',
      ok: 'เลือกไฟล์',
    );
    if (!ok) return;
    final text = await pickTextFile();
    if (text == null || !context.mounted) return;
    try {
      await state.importJson(text);
      if (context.mounted) toast(context, 'กู้คืนข้อมูลเรียบร้อย');
    } on FormatException catch (e) {
      if (context.mounted) toast(context, e.message);
    }
  }

  Future<void> _deleteAccount(BuildContext context, AppState state) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบบัญชี?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'บัญชี โปรแกรม และประวัติการฝึกทั้งหมดในเครื่องนี้จะถูกลบถาวร ใส่รหัสผ่านเพื่อยืนยัน'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              minimumSize: const Size(64, 44),
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('ลบถาวร'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty) return;
    try {
      await state.deleteAccount(password);
    } on AuthException catch (e) {
      if (context.mounted) toast(context, e.message);
    }
  }

  void _installGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ใช้งานผ่านเว็บได้เลย ไม่ต้องติดตั้งจาก App Store',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('ถ้าอยากเปิดเร็วเหมือนแอป ให้เพิ่มไอคอนบนหน้าจอโฮม:'),
              SizedBox(height: 16),
              _Step(Icons.phone_iphone, 'iPhone / iPad (Safari)',
                  'แตะปุ่มแชร์ ⬆︎ แล้วเลือก "เพิ่มไปยังหน้าจอโฮม"'),
              _Step(Icons.android, 'Android (Chrome)',
                  'แตะเมนู ⋮ แล้วเลือก "ติดตั้งแอป" หรือ "เพิ่มลงในหน้าจอหลัก"'),
              _Step(Icons.computer, 'คอมพิวเตอร์ (Chrome / Edge)',
                  'กดไอคอนติดตั้งที่แถบที่อยู่ด้านขวา'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label,
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
      subtitle: Text(value,
          style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500)),
    );
  }
}
