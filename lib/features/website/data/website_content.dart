import 'dart:math' as math;

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

  /// Calculator ke rules (tracker wale): har mahine ka 2.5% baqi raqam par,
  /// kam az kam 15% advance, qist Rs 50 tak round.
  static const instRatePerMonth = 0.025;
  static const instMinAdvance = 0.15;
  static const instRoundTo = 50;
  static const instPlans = <int>[6, 10, 12, 18, 24];
  static const instPopularPlan = 12;
  static const instLowestPlan = 24;
  static const instDefaultPrice = 50000;

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

/// Ek qist plan ka hisaab. Qist Rs 50 tak round, aakhri qist farq pura karti hai.
class InstallmentPlan {
  final int months;
  final double financed;
  final double total;
  final double monthly;
  final double last;

  const InstallmentPlan._(
      this.months, this.financed, this.total, this.monthly, this.last);

  factory InstallmentPlan.of(double financed, int months) {
    const r = WebsiteContent.instRoundTo;
    final total = financed * (1 + WebsiteContent.instRatePerMonth * months);
    var per = math.max(r, (total / months / r + 0.5).floor() * r).toDouble();
    var last = total - per * (months - 1);
    if (last <= 0) {
      per = (total / months).ceilToDouble();
      last = total - per * (months - 1);
    }
    return InstallmentPlan._(
        months, financed, total, per, last.roundToDouble());
  }

  double get charge => total - financed;

  /// Kul charge % (2.5% x mahine), maslan 12 mahine → 30.
  num get chargePct => pctNum(WebsiteContent.instRatePerMonth * months);

  /// 0.025 → 2.5, 0.3 → 30 (float ka kachra hata kar).
  static num pctNum(double fraction) {
    final p = (fraction * 1000).round() / 10;
    return p == p.roundToDouble() ? p.round() : p;
  }

  bool get lastDiffers => last != monthly;
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
