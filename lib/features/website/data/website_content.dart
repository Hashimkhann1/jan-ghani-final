import 'package:flutter/material.dart';

// Website ka static data (icons, calculator rules, branches, contact).
// Translate hone wala text: website_strings.dart (English / اردو / پښتو).
// Contact fields khali ('') hon to wo line / button nahi dikhta.

class WebsiteContent {
  WebsiteContent._();

  // Icons — website_strings.dart ke lists ke order se jurte hain.
  static const highlightIcons = <IconData>[
    Icons.storefront_rounded,
    Icons.inventory_2_rounded,
    Icons.local_shipping_rounded,
    Icons.event_repeat_rounded,
  ];

  static const categoryIcons = <IconData>[
    Icons.rice_bowl_rounded,
    Icons.cleaning_services_rounded,
    Icons.spa_rounded,
    Icons.soup_kitchen_rounded,
    Icons.local_cafe_rounded,
    Icons.child_friendly_rounded,
  ];

  static const instStepIcons = <IconData>[
    Icons.touch_app_rounded,
    Icons.payments_rounded,
    Icons.calendar_month_rounded,
  ];

  static const whyUsIcons = <IconData>[
    Icons.sell_rounded,
    Icons.verified_rounded,
    Icons.event_repeat_rounded,
    Icons.receipt_long_rounded,
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
  final IconData icon;
  final String title;
  final String text;
  const WebsiteItem(this.icon, this.title, this.text);
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
