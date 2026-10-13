# FitPlan — บันทึกการออกกำลังกาย (Flutter PWA)

เว็บแอปสำหรับบันทึกการออกกำลังกายที่ **ไม่ต้องติดตั้งแอป** — เปิดผ่านเบราว์เซอร์ได้ทันทีบนมือถือ, iPad และคอมพิวเตอร์ (ออกแบบโดยเน้นมือถือเป็นหลัก) และเพิ่มไอคอนบนหน้าจอโฮมเพื่อใช้แบบ Progressive Web App ได้ รวมถึงใช้งานออฟไลน์

## ความสามารถ

- **ระบบล็อกอิน** — สมัคร/เข้าสู่ระบบด้วยอีเมล รหัสผ่านถูกแฮชด้วย PBKDF2-HMAC-SHA256 (60,000 รอบ + salt) ข้อมูลของแต่ละบัญชีแยกจากกัน
- **จัดโปรแกรมให้อัตโนมัติ** — กรอก น้ำหนัก ส่วนสูง อายุ เพศ ประสบการณ์ เป้าหมาย จำนวนวัน/สัปดาห์ เวลาต่อครั้ง อุปกรณ์ที่บ้าน และอาการบาดเจ็บ
  แล้วระบบจะสร้างตารางรายสัปดาห์ให้ **3 แบบ: Full Gym, Mid Gym, Home Gym** พร้อมเลือกแบบที่ตรงกับที่คุณเล่นประจำเป็นโปรแกรมหลักให้อัตโนมัติ
- **โปรแกรมเบื้องต้น** 7 แบบ (มือใหม่ Full Body, เร่งด่วน 2 วัน × 30 นาที, บอดี้เวทที่บ้าน, ดัมเบลล้วน, Upper/Lower, เน้นแข็งแรง, PPL 6 วัน)
- **บันทึกเวิร์กเอาต์** — กรอกน้ำหนัก/จำนวนครั้งต่อเซ็ต, ตัวจับเวลาพักพร้อมเสียง/สั่น, ซูเปอร์เซ็ต, เปลี่ยนท่าตามอุปกรณ์, ระบบแนะนำน้ำหนักครั้งถัดไป (double progression), แจ้ง PR, Deload อัตโนมัติ
- **ประวัติและสถิติ** — เซ็ตต่อกล้ามเนื้อเทียบเป้าหมาย, จำนวนเวิร์กเอาต์ต่อสัปดาห์, กราฟ 1RM โดยประมาณรายท่า, น้ำหนักตัว
- **สำรอง/กู้คืนข้อมูล** เป็นไฟล์ JSON เพื่อย้ายเครื่อง

## หลักการจัดโปรแกรม (อ้างอิงงานวิจัย)

| หลักการ | แหล่งอ้างอิง |
|---|---|
| ฝึกกล้ามเนื้อหลักทุกส่วน ≥2 ครั้ง/สัปดาห์, แข็งแรงใช้ ≥80% 1RM, กล้ามโตได้ในช่วง ~30–100% 1RM ถ้าออกแรงพอ, ไม่จำเป็นต้องถึง failure | ACSM Position Stand 2026 (Currier, … Phillips) — *Med Sci Sports Exerc* |
| ปริมาณเซ็ต/สัปดาห์ตามประสบการณ์ (ผลตอบแทนลดลงเรื่อย ๆ), นับเซ็ตทางอ้อมเป็น 0.5 | Pelland et al. — dose–response meta-regressions |
| RIR 0–3 ตามบทบาทของท่า | Robinson et al. 2024, *Sports Med* |
| พัก ~2 นาทีท่าหลัก, 75–90 วินาทีท่าเสริม | Singer et al. 2024, *Front Sports Act Living* |
| ท่าเสริมเน้นช่วงกล้ามยืด | Maeo et al. 2021/2023; Wolf et al. 2023 |
| ซูเปอร์เซ็ตเมื่อเวลาน้อย | Iversen et al. 2021, *Sports Med* |
| Double progression | Plotkin et al. 2022, *PeerJ* |
| Deload ทุก 5–6 สัปดาห์ | Bell et al. 2023 (Delphi consensus), *Sports Med – Open* |
| ยางยืด/น้ำหนักตัวสำหรับ Home Gym | Lopes et al. 2019, *SAGE Open Med* |

รายละเอียดทั้งหมดอยู่ในแอป (เมนู ฉัน → งานวิจัยที่ใช้อ้างอิง) และใน `lib/data/research.dart`
ข้อกำหนดเหล่านี้ถูกตรวจด้วย unit test กับทุกชุดข้อมูลโปรไฟล์ (~6,000 โปรแกรม) ใน `test/program_generator_test.dart`

> โปรแกรมเป็นคำแนะนำทั่วไป ไม่ใช่คำวินิจฉัยทางการแพทย์

## โครงสร้างโค้ด

```
lib/
  data/        exercise_library (110 ท่า), preset_programs, research
  models/      profile, exercise, program, workout_log
  services/    program_generator, progression, auth_service, storage, alert/, file_io/
  state/       app_state (ChangeNotifier + AppScope)
  ui/          auth, onboarding, home_shell, today, programs, program_detail,
               workout, history, progress, profile, research
web/           index.html, manifest.json, sw.js (service worker), flutter_bootstrap.js, icons
```

## พัฒนาและทดสอบ

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter build web --release --no-web-resources-cdn   # ได้ไฟล์ใน build/web
```

## Deploy (GitHub Pages)

ไฟล์ workflow พร้อมใช้อยู่ที่ `docs/deploy-workflow.yml` (analyze → test → build ทุก PR และ deploy ขึ้น GitHub Pages เมื่อ push เข้า `master`)
เปิดใช้งาน 2 ขั้นตอน:

1. ย้ายไฟล์ไปที่ `.github/workflows/deploy.yml`
   (`git mv docs/deploy-workflow.yml .github/workflows/deploy.yml` หรือสร้างไฟล์ผ่านหน้าเว็บ GitHub)
2. **Settings → Pages → Build and deployment → Source: GitHub Actions**

แอปจะอยู่ที่ `https://<owner>.github.io/<repo>/` (เช่น `https://sofrondev.github.io/hello-rust/`)

## ข้อจำกัด

ตอนนี้บัญชีและข้อมูลเก็บใน **เบราว์เซอร์ของอุปกรณ์นั้น ๆ** (localStorage) จึงยังไม่ซิงก์ข้ามเครื่องอัตโนมัติ (ใช้ "สำรองข้อมูล/กู้คืน" ย้ายได้)
หากต้องการซิงก์บนคลาวด์ ให้เพิ่มคลาส `AuthService` ใหม่ (เช่น Firebase Auth หรือ Supabase) แทน `LocalAuthService` ใน `lib/main.dart`
