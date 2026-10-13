import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../state/app_state.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.read(context);
    setState(() => _busy = true);
    // Let the spinner paint before the (CPU-bound) password hashing runs.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      if (_register) {
        await state.register(_name.text, _email.text, _password.text);
      } else {
        await state.login(_email.text, _password.text);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final form = _buildForm(context);
    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  const Expanded(child: _Hero(expanded: true)),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Hero(expanded: false),
                        const SizedBox(height: 24),
                        form,
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('เข้าสู่ระบบ')),
                ButtonSegment(value: true, label: Text('สมัครสมาชิก')),
              ],
              selected: {_register},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() {
                _register = v.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 20),
            if (_register) ...[
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.nickname],
                decoration: const InputDecoration(
                  labelText: 'ชื่อเล่น',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'อีเมล',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) => LocalAuthService.validateEmail(v ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction:
                  _register ? TextInputAction.next : TextInputAction.done,
              autofillHints: [
                _register ? AutofillHints.newPassword : AutofillHints.password,
              ],
              onFieldSubmitted: (_) => _register ? null : _submit(),
              decoration: InputDecoration(
                labelText: 'รหัสผ่าน',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => _register
                  ? LocalAuthService.validatePassword(v ?? '')
                  : ((v ?? '').isEmpty ? 'กรุณากรอกรหัสผ่าน' : null),
            ),
            if (_register) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'ยืนยันรหัสผ่าน',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    v != _password.text ? 'รหัสผ่านไม่ตรงกัน' : null,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!,
                    style: TextStyle(color: scheme.onErrorContainer)),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(_register ? 'สร้างบัญชี' : 'เข้าสู่ระบบ'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'บัญชีและข้อมูลการฝึกถูกเก็บไว้ในเบราว์เซอร์ของอุปกรณ์นี้ '
                    'รหัสผ่านถูกเข้ารหัสแบบ PBKDF2 · ย้ายเครื่องได้ด้วยเมนู "สำรองข้อมูล"',
                    style: TextStyle(
                        fontSize: 12.5, color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const points = [
      (Icons.auto_awesome, 'จัดตารางรายสัปดาห์ให้อัตโนมัติ 3 แบบ'),
      (Icons.science_outlined, 'อ้างอิง ACSM Position Stand 2026 และงานวิจัยล่าสุด'),
      (Icons.phone_iphone, 'ใช้ผ่านเว็บได้ทันที ไม่ต้องติดตั้งแอป'),
    ];
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: expanded ? Colors.white.withValues(alpha: 0.18) : scheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.fitness_center, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Text(
          'FitPlan',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: expanded ? Colors.white : scheme.onSurface,
          ),
        ),
      ],
    );

    if (!expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          logo,
          const SizedBox(height: 12),
          Text(
            'บันทึกการออกกำลังกาย\nพร้อมโปรแกรมที่จัดให้คุณ',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 12),
          for (final (icon, text) in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(text,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F8B6C), Color(0xFF0B5C4A)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          logo,
          const SizedBox(height: 32),
          const Text(
            'บันทึกการออกกำลังกาย\nพร้อมโปรแกรมที่จัดให้คุณ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 28),
          for (final (icon, text) in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(text,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
