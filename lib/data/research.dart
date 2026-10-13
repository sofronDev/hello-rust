class ResearchRef {
  const ResearchRef({
    required this.key,
    required this.short,
    required this.title,
    required this.finding,
    required this.applied,
    required this.citation,
  });

  /// Tag used in program rationale, e.g. [ACSM2026].
  final String key;

  /// Short label for citation chips, e.g. "ACSM 2026".
  final String short;
  final String title;
  final String finding;
  final String applied;
  final String citation;
}

const researchRefs = <ResearchRef>[
  ResearchRef(
    key: 'ACSM2026',
    short: 'ACSM 2026',
    title: 'ACSM Position Stand 2026 — แนวทางการฝึกด้วยแรงต้าน',
    finding:
        'สรุปจาก 137 systematic reviews (>30,000 คน) — การเริ่มฝึกให้ผลมากที่สุด, ฝึกกล้ามเนื้อหลักทุกส่วน ≥2 ครั้ง/สัปดาห์สำคัญกว่าการหาโปรแกรม "สมบูรณ์แบบ", '
        'ความแข็งแรงเพิ่มได้ดีที่สุดด้วยน้ำหนัก ≥80% 1RM, กล้ามโตได้ในช่วงน้ำหนักกว้าง (~30–100% 1RM) หากออกแรงเพียงพอ, '
        'ปริมาณ ~10 เซ็ต/กล้ามเนื้อ/สัปดาห์ขึ้นไปเหมาะกับการเพิ่มกล้าม, ไม่จำเป็นต้องฝึกถึง failure และ power ใช้ ~30–70% 1RM ยกเร็ว',
    applied:
        'ทุกโปรแกรมฝึกแต่ละกล้ามเนื้อ ≥2 ครั้ง/สัปดาห์, ช่วงครั้งตามเป้าหมาย, RIR แทนการฝึกถึง failure และเน้นยกเร็วสำหรับผู้สูงอายุ',
    citation:
        'Currier BS, D\'Souza AC, Fiatarone Singh MA, … Phillips SM. American College of Sports Medicine Position Stand: '
        'Resistance Training Prescription for Muscle Function, Hypertrophy, and Physical Performance in Healthy Adults: '
        'An Overview of Reviews. Medicine & Science in Sports & Exercise. 2026.',
  ),
  ResearchRef(
    key: 'PELLAND',
    short: 'Pelland et al.',
    title: 'Dose–response ของปริมาณและความถี่',
    finding:
        'Meta-regression 67 งานวิจัย (2,058 คน): ยิ่งเพิ่มเซ็ต/สัปดาห์ กล้ามและความแข็งแรงยิ่งเพิ่ม แต่ผลตอบแทนลดลงเรื่อย ๆ (ความแข็งแรงอิ่มตัวเร็วกว่า). '
        'การนับเซ็ตแบบ "fractional" (ท่าที่ใช้กล้ามทางอ้อม = 0.5 เซ็ต) ทำนายผลได้ดีที่สุด. ความถี่มีผลชัดกับความแข็งแรงมากกว่ากล้าม',
    applied:
        'กำหนดช่วงเซ็ตเป้าหมายตามประสบการณ์ (มือใหม่ 6–12, กลาง 10–20, สูง 12–24) และแสดงปริมาณต่อกล้ามเนื้อด้วยการนับแบบ fractional',
    citation:
        'Pelland JC, et al. The Resistance Training Dose Response: Meta-Regressions Exploring the Effects of Weekly Volume '
        'and Frequency on Muscle Hypertrophy and Strength Gains. Sports Medicine (preprint SportRxiv 2024).',
  ),
  ResearchRef(
    key: 'ROBINSON2024',
    short: 'Robinson 2024',
    title: 'ความใกล้ failure (RIR)',
    finding:
        'กล้ามโตเพิ่มขึ้นเมื่อฝึกใกล้ failure มากขึ้น ขณะที่ความแข็งแรงแทบไม่ขึ้นกับความใกล้ failure',
    applied:
        'ท่าเสริมเหลือแรง 0–2 ครั้ง, ท่าหลัก 1–3 ครั้ง (เน้นแข็งแรง 2–3) เพื่อสมดุลระหว่างการกระตุ้นและความล้า',
    citation:
        'Robinson ZP, et al. Exploring the Dose–Response Relationship Between Estimated Resistance Training Proximity to '
        'Failure, Strength Gain, and Muscle Hypertrophy: A Series of Meta-Regressions. Sports Medicine. 2024;54(9):2209–2231.',
  ),
  ResearchRef(
    key: 'SINGER2024',
    short: 'Singer 2024',
    title: 'เวลาพักระหว่างเซ็ต',
    finding:
        'การพัก >60 วินาทีให้ผลต่อกล้ามดีกว่าเล็กน้อย แต่ไม่พบความแตกต่างชัดเจนเมื่อพักเกิน ~90 วินาที',
    applied: 'ท่าหลักพัก ~2 นาที (เน้นแข็งแรง 3 นาที), ท่าเสริม 75–90 วินาที',
    citation:
        'Singer A, et al. Give it a rest: a systematic review with Bayesian meta-analysis on the effect of inter-set rest '
        'interval duration on muscle hypertrophy. Frontiers in Sports and Active Living. 2024.',
  ),
  ResearchRef(
    key: 'LML',
    short: 'Maeo 2021/2023',
    title: 'ฝึกในช่วงกล้ามยืด (long muscle length)',
    finding:
        'ท่าที่ให้แรงต้านสูงขณะกล้ามยืด เช่น overhead triceps extension และ seated leg curl ให้กล้ามโตกว่าท่าเทียบเคียงในหลายการทดลอง; '
        'หลักฐานยังไม่สรุปเด็ดขาดทุกกล้ามเนื้อ แต่ไม่มีข้อเสีย',
    applied:
        'ระบบให้คะแนนพิเศษกับท่าเสริมที่เน้นช่วงกล้ามยืด (incline curl, overhead extension, seated leg curl, cable lateral raise ฯลฯ)',
    citation:
        'Maeo S, et al. Greater hamstrings muscle hypertrophy … after training at long versus short muscle lengths. '
        'Med Sci Sports Exerc. 2021 · Maeo S, et al. Triceps brachii hypertrophy is substantially greater after elbow '
        'extension training performed in the overhead versus neutral arm position. Eur J Sport Sci. 2023 · '
        'Wolf M, et al. Partial vs full range of motion resistance training: a systematic review and meta-analysis. '
        'Int J Strength Cond. 2023.',
  ),
  ResearchRef(
    key: 'IVERSEN2021',
    short: 'Iversen 2021',
    title: 'โปรแกรมประหยัดเวลา',
    finding:
        'การจับคู่ซูเปอร์เซ็ต/paired sets ของท่าที่ไม่ใช้กล้ามเดียวกัน ลดเวลาฝึกได้มากโดยแทบไม่ลดผลลัพธ์',
    applied:
        'เมื่อมีเวลา ≤60 นาทีหรือเป้าหมายลดไขมัน ระบบจับคู่ท่าเสริมเป็นซูเปอร์เซ็ต และจับคู่ท่าดัน/ดึงเมื่อมีเวลา ≤30 นาที',
    citation:
        'Iversen VM, Norum M, Schoenfeld BJ, Fimland MS. No Time to Lift? Designing Time-Efficient Training Programs for '
        'Strength and Hypertrophy: A Narrative Review. Sports Medicine. 2021;51(10):2079–2095.',
  ),
  ResearchRef(
    key: 'PLOTKIN2022',
    short: 'Plotkin 2022',
    title: 'Progressive overload: เพิ่มน้ำหนักหรือเพิ่มครั้ง',
    finding:
        'การเพิ่มจำนวนครั้งหรือเพิ่มน้ำหนักให้กล้ามโตใกล้เคียงกัน — สำคัญที่ต้องค่อย ๆ เพิ่มความท้าทาย',
    applied:
        'Double progression: เพิ่มครั้งจนถึงเลขบนของช่วงทุกเซ็ต แล้วจึงเพิ่มน้ำหนัก แอปคำนวณน้ำหนักที่แนะนำให้อัตโนมัติ',
    citation:
        'Plotkin D, et al. Progressive overload without progressing load? The effects of load or repetition progression on '
        'muscular adaptations. PeerJ. 2022;10:e14142.',
  ),
  ResearchRef(
    key: 'BELL2023',
    short: 'Bell 2023',
    title: 'Deload',
    finding:
        'ฉันทามติผู้เชี่ยวชาญ (Delphi): deload ราวทุก 4–8 สัปดาห์ นาน ~1 สัปดาห์ โดยลดปริมาณเป็นหลัก ช่วยฟื้นตัวทั้งร่างกายและจิตใจ',
    applied: 'รอบละ 5–6 สัปดาห์ สัปดาห์สุดท้ายลดเซ็ตลงครึ่งหนึ่งโดยอัตโนมัติ',
    citation:
        'Bell L, et al. Integrating Deloading into Strength and Physique Sports Training Programmes: An International '
        'Delphi Consensus Approach. Sports Medicine – Open. 2023.',
  ),
  ResearchRef(
    key: 'LOPES2019',
    short: 'Lopes 2019',
    title: 'ยางยืด vs อุปกรณ์ทั่วไป',
    finding:
        'การฝึกด้วยยางยืดเพิ่มความแข็งแรงได้ใกล้เคียงการฝึกด้วยอุปกรณ์ทั่วไป',
    applied: 'โปรแกรม Home Gym ใช้ยางยืด/น้ำหนักตัวได้อย่างมั่นใจ และเพิ่มความยากด้วยท่าที่ยากขึ้น',
    citation:
        'Lopes JSS, et al. Effects of training with elastic resistance versus conventional resistance on muscular strength: '
        'A systematic review and meta-analysis. SAGE Open Medicine. 2019;7.',
  ),
  ResearchRef(
    key: 'MORTON',
    short: 'Morton 2018',
    title: 'โปรตีน',
    finding:
        'โปรตีนรวม ~1.6 g/kg/วัน เป็นจุดที่การเพิ่มมวลกล้ามจากการฝึกเริ่มไม่เพิ่มขึ้นอีก (ขอบบน ~2.2 g/kg)',
    applied: 'หน้าโปรไฟล์แสดงเป้าหมายโปรตีนต่อวันจากน้ำหนักตัว',
    citation:
        'Morton RW, et al. A systematic review, meta-analysis and meta-regression of the effect of protein supplementation '
        'on resistance training-induced gains in muscle mass and strength in healthy adults. Br J Sports Med. 2018;52(6):376–384.',
  ),
  ResearchRef(
    key: 'WHO2020',
    short: 'WHO 2020',
    title: 'WHO กิจกรรมทางกาย',
    finding:
        'ผู้ใหญ่ควรมีกิจกรรมแอโรบิกระดับปานกลาง 150–300 นาที/สัปดาห์ และฝึกกล้ามเนื้อ ≥2 วัน/สัปดาห์',
    applied: 'วันพักแนะนำเดิน/คาร์ดิโอ และเป้าหมายลดไขมันมีคำแนะนำคาร์ดิโอเพิ่ม',
    citation:
        'Bull FC, et al. World Health Organization 2020 guidelines on physical activity and sedentary behaviour. '
        'Br J Sports Med. 2020;54:1451–1462.',
  ),
];
