// Website ka static data (photos, calculator rules, branches, contact).
// Translate hone wala text: website_strings.dart (English / اردو / پښتو).
// Contact fields khali ('') hon to wo line / button nahi dikhta.

class WebsiteContent {
  WebsiteContent._();

  // Photos (assets/images/website/) — website_strings.dart ke lists ke order
  // se jurte hain. Photo badalni ho to same naam se file replace kar do.
  static const _img = 'assets/images/website';

  static const heroImage = '$_img/hero_store.jpg';

  static const highlightImages = <String>[
    '$_img/hl_shops.jpg',
    '$_img/hl_household.jpg',
    '$_img/hl_delivery.jpg',
    '$_img/hl_installments.jpg',
  ];

  static const categoryImages = <String>[
    '$_img/cat_grocery.jpg',
    '$_img/cat_cleaning.jpg',
    '$_img/cat_personal_care.jpg',
    '$_img/cat_kitchen.jpg',
    '$_img/cat_snacks.jpg',
    '$_img/cat_baby.jpg',
  ];

  static const instStepImages = <String>[
    '$_img/step_choose.jpg',
    '$_img/step_advance.jpg',
    '$_img/step_monthly.jpg',
  ];

  static const whyUsImages = <String>[
    '$_img/why_prices.jpg',
    '$_img/why_quality.jpg',
    '$_img/why_installments.jpg',
    '$_img/why_online.jpg',
  ];

  /// Calculator ke fixed rules.
  static const instMonths = 10;
  static const instMarkup = 0.30;
  static const instAdvances = <double>[0.30, 0.40, 0.50];
  static const instDefaultPrice = 100000;

  // ── Branches ──
  // Branch add karne ke liye: WebsiteBranch('Name', 'Area', lat: .., lng: .., mapUrl: '...')
  // Khali list par "nearest branch" wala card dikhta hai.
  static const branches = <WebsiteBranch>[
    WebsiteBranch(
      'Jan Ghani — Branch 1',
      'Majeedabad',
      lat: 34.1724072,
      lng: 71.873252,
      mapUrl:
          'https://www.google.com/maps/place/JANGHANI/@34.1725323,71.8648328,15.44z/data=!4m14!1m7!3m6!1s0x38d935108d3f143d:0x9a629f675774d1b!2sJAN+GHANI+MART+3!8m2!3d34.1765699!4d71.8668713!16s%2Fg%2F11snnhvzsg!3m5!1s0x38d935735a4eaa4d:0x20eebf2f3334f5ed!8m2!3d34.1724072!4d71.873252!16s%2Fg%2F11h3mf7csf',
    ),
    WebsiteBranch(
      'Jan Ghani — Branch 2',
      'Jaga Road',
      lat: 34.1645504,
      lng: 71.8780076,
      mapUrl:
          'https://www.google.com/maps/@34.1645504,71.8780076,145m/data=!3m1!1e3',
    ),
  ];

  // ── Contact (khali chhodo to nahi dikhega) ──
  /// WhatsApp number, country code ke saath, maslan '923001234567'.
  static const whatsapp = '923459357032';
  static const phone = '+92 345 9357032';
  static const email = '';
  static const address = '';
}

class WebsiteItem {
  /// Asset path (assets/images/website/...).
  final String image;
  final String title;
  final String text;
  const WebsiteItem(this.image, this.title, this.text);
}

class WebsiteBranch {
  final String name;
  final String address;
  final String phone;

  /// Google Maps link — card par "Get directions".
  final String mapUrl;

  /// Card ke upar embedded map (dono hon tabhi dikhta hai).
  final double? lat;
  final double? lng;
  const WebsiteBranch(this.name, this.address,
      {this.phone = '', this.mapUrl = '', this.lat, this.lng});
}
