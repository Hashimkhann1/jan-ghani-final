import 'package:flutter/widgets.dart';

import 'website_content.dart';

// Website ka translate hone wala text — English / اردو / پښتو.
// Naya text add karo to teeno languages mein add karo.
// `{n}` wali jagah code number / amount daal deta hai (fill()).

enum WebsiteLang {
  en('English', TextDirection.ltr),
  ur('اردو', TextDirection.rtl),
  ps('پښتو', TextDirection.rtl);

  final String label;
  final TextDirection direction;
  const WebsiteLang(this.label, this.direction);

  bool get rtl => direction == TextDirection.rtl;

  WebsiteText get text => switch (this) {
        WebsiteLang.en => WebsiteText.en,
        WebsiteLang.ur => WebsiteText.ur,
        WebsiteLang.ps => WebsiteText.ps,
      };
}

/// Website subtree ko current language deta hai.
/// `WebsiteText.of(context)` se text, `WebsiteLocale.of(context)` se language.
class WebsiteLocale extends InheritedWidget {
  final WebsiteLang lang;
  final ValueChanged<WebsiteLang> onChanged;

  const WebsiteLocale({
    super.key,
    required this.lang,
    required this.onChanged,
    required super.child,
  });

  static WebsiteLocale of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WebsiteLocale>()!;

  @override
  bool updateShouldNotify(WebsiteLocale old) => old.lang != lang;
}

/// Urdu / Pashto mein letter-spacing huroof ka jor tod deti hai — wahan 0.
double tracking(BuildContext context, double value) =>
    Directionality.of(context) == TextDirection.rtl ? 0 : value;

extension WebsiteFill on String {
  String fill(Object n) => replaceAll('{n}', '$n');

  /// Doosri jagah (`{a}`) — maslan amount.
  String fillA(Object a) => replaceAll('{a}', '$a');
}

typedef TextPair = (String title, String text);

class WebsiteText {
  final String brand;
  final String tagline;

  // ── Nav ──
  final String navHome;
  final String navInstallments;
  final String navBranches;
  final String login;
  final String myAccount;
  final String menu;
  final String language;

  // ── Hero ──
  final String heroChip;
  final String heroTitle1;
  final String heroTitle2;
  final String heroText;
  final String exploreInstallments;
  final String contactUs;
  final String trustQuality;
  final String trustDelivery;
  final String trustPlans;
  final String deliveredDoorstep;
  final String easyInstallments;
  final String perMonth;


  // ── Installments ──
  final String instEyebrow;
  final String instTitle;
  final String instText;
  final String instMotto;
  final List<TextPair> instSteps;
  final List<String> instBenefits;
  final String howItWorks;
  final String instHeadline;
  final String duration;
  final String charge;
  final String advance;
  final String monthsValue;
  final String contactBrand;
  final String calculator;
  final String productPrice;
  final String advanceLabel;
  final String ofPrice;
  final String minAdvanceWarn;
  final String fullAdvance;
  final String choosePlan;
  final String monthsShort;
  final String tagPopular;
  final String tagLowest;
  final String lastInstallment;
  final String totalWithAdvance;
  final String priceFixed;
  final String chargePerMonth;
  final String fromPct;
  final String newCalculation;
  final String advancePayment;
  final String remaining;
  final String chargeRow;
  final String totalInstallment;
  final String calculate;
  final String getOnInstallments;
  final String instNote;
  final String monthlyPayment;
  final String perMonthFor;

  // ── Branches ──
  final String branchesEyebrow;
  final String branchesTitle;
  final String branchesText;
  final String directions;
  final String nearestTitle;
  final String nearestText;

  final String copyright;

  const WebsiteText({
    required this.brand,
    required this.tagline,
    required this.navHome,
    required this.navInstallments,
    required this.navBranches,
    required this.login,
    required this.myAccount,
    required this.menu,
    required this.language,
    required this.heroChip,
    required this.heroTitle1,
    required this.heroTitle2,
    required this.heroText,
    required this.exploreInstallments,
    required this.contactUs,
    required this.trustQuality,
    required this.trustDelivery,
    required this.trustPlans,
    required this.deliveredDoorstep,
    required this.easyInstallments,
    required this.perMonth,
    required this.instEyebrow,
    required this.instTitle,
    required this.instText,
    required this.instMotto,
    required this.instSteps,
    required this.instBenefits,
    required this.howItWorks,
    required this.instHeadline,
    required this.duration,
    required this.charge,
    required this.advance,
    required this.monthsValue,
    required this.contactBrand,
    required this.calculator,
    required this.productPrice,
    required this.advanceLabel,
    required this.ofPrice,
    required this.minAdvanceWarn,
    required this.fullAdvance,
    required this.choosePlan,
    required this.monthsShort,
    required this.tagPopular,
    required this.tagLowest,
    required this.lastInstallment,
    required this.totalWithAdvance,
    required this.priceFixed,
    required this.chargePerMonth,
    required this.fromPct,
    required this.newCalculation,
    required this.advancePayment,
    required this.remaining,
    required this.chargeRow,
    required this.totalInstallment,
    required this.calculate,
    required this.getOnInstallments,
    required this.instNote,
    required this.monthlyPayment,
    required this.perMonthFor,
    required this.branchesEyebrow,
    required this.branchesTitle,
    required this.branchesText,
    required this.directions,
    required this.nearestTitle,
    required this.nearestText,
    required this.copyright,
  });

  static WebsiteText of(BuildContext context) =>
      WebsiteLocale.of(context).lang.text;

  // Icons website_content.dart mein — text yahan; dono order se jurte hain.
  List<WebsiteItem> get instStepItems =>
      _items(WebsiteContent.instStepIcons, instSteps);

  static List<WebsiteItem> _items(List<IconData> icons, List<TextPair> pairs) =>
      [
        for (int i = 0; i < pairs.length; i++)
          WebsiteItem(icons[i], pairs[i].$1, pairs[i].$2),
      ];

  // ── English ────────────────────────────────────────────────────────────────
  static const en = WebsiteText(
    brand: 'Jan Ghani',
    tagline: 'Household goods for every family',
    navHome: 'Home',
    navInstallments: 'Installments',
    navBranches: 'Branches',
    login: 'Login',
    myAccount: 'My Account',
    menu: 'Menu',
    language: 'Language',
    heroChip: 'Our mission: 10,000 shops across Pakistan',
    heroTitle1: 'Everything You Need.',
    heroTitle2: 'Now on Easy Installments.',
    heroText: 'Shop with Jan Ghani and get the products you need with flexible '
        'installment options.',
    exploreInstallments: 'Explore Installments',
    contactUs: 'Contact Us',
    trustQuality: 'Quality products',
    trustDelivery: 'Doorstep delivery',
    trustPlans: '6 to 24 month plans',
    deliveredDoorstep: 'Delivered right to your doorstep',
    easyInstallments: 'Easy installments',
    perMonth: '{n} / month',
    instEyebrow: 'Installments',
    instTitle: 'Buy Anything on Easy Installments',
    instText: "Need a product that isn't available at Jan Ghani? Choose the "
        'product you want from anywhere and Jan Ghani can arrange it for you '
        'on an easy installment plan.',
    instMotto: 'You Choose It. We Arrange It. You Pay Monthly.',
    instSteps: [
      (
        'Choose Your Product',
        'Choose the product you want, even if it is not currently '
            'available at Jan Ghani.'
      ),
      (
        'Pay Your Advance',
        'Pay at least 15% of the price in advance — pay more to lower '
            'your monthly installment.'
      ),
      (
        'Easy Monthly Payments',
        'Pay the remaining amount in 6, 10, 12, 18 or 24 easy monthly '
            'installments.'
      ),
    ],
    instBenefits: [
      'Any product — even if it is not in our stores',
      'Advance from just 15% of the price',
      'Choose your plan: 6, 10, 12, 18 or 24 months',
      'Only 2.5% per month — shown upfront, no surprises',
      'Price fixed today — no increase later',
    ],
    howItWorks: 'HOW IT WORKS',
    instHeadline: 'Get it today.\nPay in up to {n} easy months.',
    duration: 'Duration',
    charge: 'Charge',
    advance: 'Advance',
    monthsValue: '{n} Months',
    contactBrand: 'Contact Jan Ghani',
    calculator: 'Installment Calculator',
    productPrice: 'Product Price',
    advanceLabel: 'Advance Payment',
    ofPrice: '{n}% of price',
    minAdvanceWarn: 'A minimum {n}% advance is required: {a}. Plans below '
        'use the {n}% advance.',
    fullAdvance: 'Advance equals the full price — no installments needed.',
    choosePlan: 'Choose Your Plan',
    monthsShort: 'months',
    tagPopular: 'Popular',
    tagLowest: 'Lowest installment',
    lastInstallment: 'Last installment {n}',
    totalWithAdvance: 'Total price (incl. advance) {n}',
    priceFixed: 'Price fixed today — no increase later',
    chargePerMonth: '{n}% / month',
    fromPct: 'From {n}%',
    newCalculation: 'New calculation',
    advancePayment: 'Advance Payment ({n}%)',
    remaining: 'Remaining Amount',
    chargeRow: '{n}% Installment Charge',
    totalInstallment: 'Total Installment Amount',
    calculate: 'Calculate Installment',
    getOnInstallments: 'Get on Installments',
    instNote: 'This calculator gives an estimate only. Your final plan is '
        'confirmed by the Jan Ghani team.',
    monthlyPayment: 'Your Monthly Payment',
    perMonthFor: '/per month for {n} months',
    branchesEyebrow: 'Branches',
    branchesTitle: 'Visit a Jan Ghani store',
    branchesText: 'We are growing every day towards our mission of 10,000 '
        'shops across Pakistan.',
    directions: 'Directions',
    nearestTitle: 'Find your nearest Jan Ghani branch',
    nearestText: 'Our branches stock everyday household goods and can help '
        'you set up an installment plan. Get in touch and we will guide you '
        'to the store closest to you.',
    copyright: '© {n} Jan Ghani. All rights reserved.',
  );

  // ── اردو ───────────────────────────────────────────────────────────────────
  static const ur = WebsiteText(
    brand: 'جان غنی',
    tagline: 'ہر گھرانے کے لیے گھریلو سامان',
    navHome: 'ہوم',
    navInstallments: 'قسطیں',
    navBranches: 'برانچز',
    login: 'لاگ اِن',
    myAccount: 'میرا اکاؤنٹ',
    menu: 'مینو',
    language: 'زبان',
    heroChip: 'ہمارا مشن: پورے پاکستان میں 10,000 دکانیں',
    heroTitle1: 'آپ کی ضرورت کی ہر چیز۔',
    heroTitle2: 'اب آسان قسطوں پر۔',
    heroText: 'جان غنی سے خریداری کریں اور اپنی ضرورت کی اشیاء آسان قسطوں '
        'کے ساتھ حاصل کریں۔',
    exploreInstallments: 'قسطوں کی تفصیل دیکھیں',
    contactUs: 'ہم سے رابطہ کریں',
    trustQuality: 'معیاری مصنوعات',
    trustDelivery: 'گھر تک ڈیلیوری',
    trustPlans: '6 سے 24 ماہ کے پلان',
    deliveredDoorstep: 'سامان سیدھا آپ کی دہلیز تک',
    easyInstallments: 'آسان قسطیں',
    perMonth: '{n} / ماہانہ',
    instEyebrow: 'قسطیں',
    instTitle: 'کوئی بھی چیز آسان قسطوں پر خریدیں',
    instText: 'کوئی ایسی چیز چاہیے جو جان غنی پر دستیاب نہیں؟ کہیں سے بھی اپنی '
        'پسند کی چیز منتخب کریں، جان غنی وہ آپ کو آسان قسطوں پر فراہم کر دے گا۔',
    instMotto: 'آپ پسند کریں۔ ہم انتظام کریں۔ آپ ماہانہ ادا کریں۔',
    instSteps: [
      (
        'اپنی چیز منتخب کریں',
        'اپنی پسند کی چیز منتخب کریں، چاہے وہ اس وقت جان غنی پر دستیاب نہ ہو۔'
      ),
      (
        'ایڈوانس ادا کریں',
        'قیمت کا کم از کم 15% پیشگی ادا کریں — زیادہ دیں تو ماہانہ قسط کم ہو '
            'جائے گی۔'
      ),
      (
        'آسان ماہانہ قسطیں',
        'باقی رقم 6، 10، 12، 18 یا 24 آسان ماہانہ قسطوں میں ادا کریں۔'
      ),
    ],
    instBenefits: [
      'کوئی بھی چیز — چاہے ہمارے اسٹورز میں نہ ہو',
      'صرف 15% پیشگی سے شروع',
      'اپنا پلان چنیں: 6، 10، 12، 18 یا 24 ماہ',
      'صرف 2.5% ماہانہ — پہلے سے واضح، کوئی چھپی فیس نہیں',
      'قیمت آج ہی طے — بعد میں کوئی اضافہ نہیں',
    ],
    howItWorks: 'یہ کیسے کام کرتا ہے',
    instHeadline: 'آج ہی حاصل کریں۔\n{n} آسان مہینوں تک ادائیگی کریں۔',
    duration: 'مدت',
    charge: 'چارج',
    advance: 'ایڈوانس',
    monthsValue: '{n} ماہ',
    contactBrand: 'جان غنی سے رابطہ کریں',
    calculator: 'قسط کیلکولیٹر',
    productPrice: 'چیز کی قیمت',
    advanceLabel: 'پیشگی رقم',
    ofPrice: 'قیمت کا {n}%',
    minAdvanceWarn: 'کم از کم {n}% پیشگی ضروری ہے: {a}۔ نیچے قسطیں {n}% '
        'پیشگی کے حساب سے ہیں۔',
    fullAdvance: 'پیشگی پوری قیمت کے برابر ہے — قسط کی ضرورت نہیں۔',
    choosePlan: 'اپنا پلان چنیں',
    monthsShort: 'مہینے',
    tagPopular: 'مقبول',
    tagLowest: 'کم قسط',
    lastInstallment: 'آخری قسط {n}',
    totalWithAdvance: 'کل قیمت (پیشگی سمیت) {n}',
    priceFixed: 'قیمت آج ہی طے — بعد میں کوئی اضافہ نہیں',
    chargePerMonth: '{n}% ماہانہ',
    fromPct: '{n}% سے',
    newCalculation: 'نیا حساب',
    advancePayment: 'ایڈوانس ادائیگی ({n}%)',
    remaining: 'باقی رقم',
    chargeRow: '{n}% قسط چارج',
    totalInstallment: 'کل قسط رقم',
    calculate: 'قسط کا حساب لگائیں',
    getOnInstallments: 'قسطوں پر حاصل کریں',
    instNote: 'یہ کیلکولیٹر صرف اندازہ دیتا ہے۔ آپ کے حتمی پلان کی تصدیق جان '
        'غنی کی ٹیم کرتی ہے۔',
    monthlyPayment: 'آپ کی ماہانہ قسط',
    perMonthFor: 'فی ماہ، {n} ماہ کے لیے',
    branchesEyebrow: 'برانچز',
    branchesTitle: 'جان غنی اسٹور تشریف لائیں',
    branchesText: 'ہم پورے پاکستان میں 10,000 دکانوں کے اپنے مشن کی طرف روز '
        'بروز بڑھ رہے ہیں۔',
    directions: 'راستہ دیکھیں',
    nearestTitle: 'اپنی قریبی جان غنی برانچ تلاش کریں',
    nearestText: 'ہماری برانچز میں روزمرہ کا گھریلو سامان دستیاب ہے اور وہ قسط '
        'پلان بنانے میں بھی آپ کی مدد کر سکتی ہیں۔ ہم سے رابطہ کریں، ہم آپ کو '
        'قریبی اسٹور تک رہنمائی کریں گے۔',
    copyright: '© {n} جان غنی۔ جملہ حقوق محفوظ ہیں۔',
  );

  // ── پښتو ───────────────────────────────────────────────────────────────────
  static const ps = WebsiteText(
    brand: 'جان غني',
    tagline: 'د هرې کورنۍ لپاره د کور سامانونه',
    navHome: 'کور',
    navInstallments: 'قسطونه',
    navBranches: 'څانګې',
    login: 'ننوتل',
    myAccount: 'زما حساب',
    menu: 'مینو',
    language: 'ژبه',
    heroChip: 'زموږ موخه: په ټول پاکستان کې 10,000 دوکانونه',
    heroTitle1: 'هر هغه څه چې تاسو ورته اړتیا لرئ.',
    heroTitle2: 'اوس په اسانه قسطونو.',
    heroText: 'له جان غني څخه پېرود وکړئ او خپل اړین توکي په اسانه قسطونو '
        'ترلاسه کړئ.',
    exploreInstallments: 'قسطونه وګورئ',
    contactUs: 'موږ سره اړیکه ونیسئ',
    trustQuality: 'باکیفیته محصولات',
    trustDelivery: 'تر کوره رسول',
    trustPlans: 'له 6 تر 24 میاشتو پلانونه',
    deliveredDoorstep: 'ستاسو تر دروازې پورې رسول کېږي',
    easyInstallments: 'اسانه قسطونه',
    perMonth: '{n} / میاشت',
    instEyebrow: 'قسطونه',
    instTitle: 'هر شی په اسانه قسطونو واخلئ',
    instText: 'داسې توکي ته اړتیا لرئ چې په جان غني کې نشته؟ له هر ځای څخه '
        'خپل خوښ توکی غوره کړئ، جان غني به یې تاسو ته په اسانه قسطونو برابر کړي.',
    instMotto: 'تاسو یې غوره کړئ. موږ یې برابروو. تاسو میاشتنی تادیه کوئ.',
    instSteps: [
      (
        'خپل توکی غوره کړئ',
        'خپل خوښ توکی غوره کړئ، که څه هم اوس مهال په جان غني کې نه وي.'
      ),
      (
        'پیشکي ورکړئ',
        'د بیې لږ تر لږه 15% پیشکي ورکړئ — زیات یې ورکړئ نو میاشتنی قسط '
            'به کم شي.'
      ),
      (
        'اسانه میاشتنۍ تادیې',
        'پاتې پیسې په 6، 10، 12، 18 یا 24 اسانه میاشتنیو قسطونو کې ورکړئ.'
      ),
    ],
    instBenefits: [
      'هر توکی — که څه هم زموږ په پلورنځیو کې نه وي',
      'یوازې له 15% پیشکي څخه پیل',
      'خپل پلان غوره کړئ: 6، 10، 12، 18 یا 24 میاشتې',
      'یوازې 2.5% په میاشت کې — له مخکې ښکاره، هېڅ پټ لګښت نشته',
      'بیه نن ټاکل کېږي — وروسته هېڅ زیاتوالی نشته',
    ],
    howItWorks: 'دا څنګه کار کوي',
    instHeadline: 'نن یې ترلاسه کړئ.\nتر {n} اسانه میاشتو پورې یې ورکړئ.',
    duration: 'موده',
    charge: 'فیس',
    advance: 'پیشکي',
    monthsValue: '{n} میاشتې',
    contactBrand: 'جان غني سره اړیکه ونیسئ',
    calculator: 'د قسط حساب',
    productPrice: 'د توکي بیه',
    advanceLabel: 'پیشکي پیسې',
    ofPrice: 'د بیې {n}%',
    minAdvanceWarn: 'لږ تر لږه {n}% پیشکي اړینه ده: {a}. لاندې قسطونه د '
        '{n}% پیشکي په حساب دي.',
    fullAdvance: 'پیشکي د ټولې بیې سره برابره ده — قسط ته اړتیا نشته.',
    choosePlan: 'خپل پلان غوره کړئ',
    monthsShort: 'میاشتې',
    tagPopular: 'مشهور',
    tagLowest: 'کم قسط',
    lastInstallment: 'وروستی قسط {n}',
    totalWithAdvance: 'ټوله بیه (د پیشکي سره) {n}',
    priceFixed: 'بیه نن ټاکل کېږي — وروسته هېڅ زیاتوالی نشته',
    chargePerMonth: '{n}% په میاشت',
    fromPct: 'له {n}% څخه',
    newCalculation: 'نوی حساب',
    advancePayment: 'پیشکي تادیه ({n}%)',
    remaining: 'پاتې پیسې',
    chargeRow: '{n}% د قسط فیس',
    totalInstallment: 'د قسط ټولې پیسې',
    calculate: 'قسط حساب کړئ',
    getOnInstallments: 'په قسطونو یې واخلئ',
    instNote: 'دا حساب یوازې اټکل دی. ستاسو وروستی پلان د جان غني ټیم '
        'تاییدوي.',
    monthlyPayment: 'ستاسو میاشتنی قسط',
    perMonthFor: 'په میاشت کې، د {n} میاشتو لپاره',
    branchesEyebrow: 'څانګې',
    branchesTitle: 'د جان غني پلورنځي ته راشئ',
    branchesText: 'موږ هره ورځ په ټول پاکستان کې د 10,000 دوکانونو د خپلې '
        'موخې پر لور وده کوو.',
    directions: 'لار وګورئ',
    nearestTitle: 'د جان غني نږدې څانګه ومومئ',
    nearestText: 'زموږ څانګې د ورځني ژوند د کور سامانونه لري او د قسطي پلان په '
        'جوړولو کې هم مرسته کولی شي. موږ سره اړیکه ونیسئ، موږ به تاسو ته د '
        'نږدې پلورنځي لارښوونه وکړو.',
    copyright: '© {n} جان غني. ټول حقونه خوندي دي.',
  );
}
