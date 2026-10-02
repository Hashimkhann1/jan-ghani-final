import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jan_ghani_final/core/routes/accountant_router.dart';
import 'package:jan_ghani_final/features/accountant/authentication/domain/entities/accountant_user_entity.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/providers/accoutant_session_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/website_content.dart';
import '../../data/website_strings.dart';
import '../widget/installment_section.dart';
import '../widget/website_login_dialog.dart';
import '../widget/website_sections.dart';

/// Jan Ghani public website (static) — URL: `/`
///
/// Koi backend / form submit nahi: installment calculator browser mein
/// hisaab karta hai, "Contact" WhatsApp / phone kholta hai (website_content.dart).
/// Khulte hi (logged out ho to) login popup aata hai — accountant / customer
/// apne account mein ja sakein. Popup band karke website dekh sakte hain.
/// Language (English / اردو / پښتو) navbar se badalti hai aur browser mein
/// yaad rehti hai; Urdu / Pashto par poora page right-to-left.
class WebsiteScreen extends ConsumerStatefulWidget {
  const WebsiteScreen({super.key});

  @override
  ConsumerState<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends ConsumerState<WebsiteScreen> {
  final _scrollCtrl = ScrollController();
  final _sectionKeys = {
    for (final s in WebsiteSection.values) s: GlobalKey(),
  };
  bool _dialogOpen = false;
  bool _scrolled = false;
  WebsiteLang _lang = WebsiteLang.en;

  static const _langKey = 'website_lang';

  static bool get _hasWhatsApp => WebsiteContent.whatsapp.isNotEmpty;
  static bool get _hasPhone => WebsiteContent.phone.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final scrolled = _scrollCtrl.offset > 8;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(currentUserProvider) == null) _openLogin();
    });
    _loadLang();
  }

  Future<void> _loadLang() async {
    final saved = (await SharedPreferences.getInstance()).getString(_langKey);
    final lang = WebsiteLang.values.where((l) => l.name == saved).firstOrNull;
    if (lang != null && mounted) setState(() => _lang = lang);
  }

  Future<void> _setLang(WebsiteLang lang) async {
    setState(() => _lang = lang);
    await (await SharedPreferences.getInstance())
        .setString(_langKey, lang.name);
  }

  /// Urdu / Pashto ke liye Arabic-script font (Poppins mein ye huroof nahi).
  ThemeData _theme(BuildContext context) {
    final theme = Theme.of(context);
    if (!_lang.rtl) return theme;
    return theme.copyWith(
      textTheme: GoogleFonts.notoNaskhArabicTextTheme(theme.textTheme),
      primaryTextTheme:
          GoogleFonts.notoNaskhArabicTextTheme(theme.primaryTextTheme),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _openLogin() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    await showWebsiteLoginDialog(context);
    _dialogOpen = false;
  }

  void _goToAccount(AccountantUserEntity user) =>
      context.go(accountantHomeFor(user));

  void _scrollTo(WebsiteSection section) {
    final ctx = _sectionKeys[section]!.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openWhatsApp([String? message]) {
    launchUrl(
      Uri.https('wa.me', '/${WebsiteContent.whatsapp}',
          message == null ? null : {'text': message}),
      mode: LaunchMode.externalApplication,
    );
  }

  void _call() => launchUrl(Uri(scheme: 'tel', path: WebsiteContent.phone));

  /// WhatsApp → phone → warna contact section par scroll.
  void _contact([String? message]) {
    if (_hasWhatsApp) {
      _openWhatsApp(message);
    } else if (_hasPhone) {
      _call();
    } else {
      _scrollTo(WebsiteSection.contact);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Popup se login hua → popup band, seedha account mein.
    ref.listen<AccountantUserEntity?>(currentUserProvider, (prev, next) {
      if (prev != null || next == null) return;
      if (_dialogOpen) Navigator.of(context, rootNavigator: true).pop();
      _goToAccount(next);
    });

    final user = ref.watch(currentUserProvider);
    final onAccount = user == null ? _openLogin : () => _goToAccount(user);
    final t = _lang.text;
    final accountLabel = user == null ? t.login : t.myAccount;
    final mobile = MediaQuery.of(context).size.width < 900;

    return WebsiteLocale(
      lang: _lang,
      onChanged: _setLang,
      child: Directionality(
        textDirection: _lang.direction,
        child: Theme(
          data: _theme(context),
          child: _page(user, accountLabel, onAccount, mobile),
        ),
      ),
    );
  }

  Widget _page(AccountantUserEntity? user, String accountLabel,
      VoidCallback onAccount, bool mobile) {
    return Scaffold(
      backgroundColor: WebsiteColors.page,
      endDrawer: mobile
          ? WebsiteDrawer(
              accountLabel: accountLabel,
              onAccount: onAccount,
              onSection: _scrollTo,
            )
          : null,
      body: Column(
        children: [
          WebsiteNavBar(
            mobile: mobile,
            scrolled: _scrolled,
            accountLabel: accountLabel,
            onAccount: onAccount,
            onSection: _scrollTo,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: Column(
                children: [
                  HeroSection(
                    key: _sectionKeys[WebsiteSection.home],
                    mobile: mobile,
                    onInstallments: () =>
                        _scrollTo(WebsiteSection.installments),
                    onContact: _contact,
                  ),
                  AboutSection(
                      key: _sectionKeys[WebsiteSection.about], mobile: mobile),
                  ProductsSection(
                      key: _sectionKeys[WebsiteSection.products],
                      mobile: mobile),
                  InstallmentSection(
                    key: _sectionKeys[WebsiteSection.installments],
                    mobile: mobile,
                    onContact: _contact,
                    onGetInstallment: _contact,
                  ),
                  WhyUsSection(mobile: mobile),
                  BranchesSection(
                    key: _sectionKeys[WebsiteSection.branches],
                    mobile: mobile,
                    onContact: _contact,
                  ),
                  ContactSection(
                    key: _sectionKeys[WebsiteSection.contact],
                    mobile: mobile,
                    accountLabel: accountLabel,
                    onAccount: onAccount,
                    onWhatsApp: _hasWhatsApp ? _openWhatsApp : null,
                    onCall: _hasPhone ? _call : null,
                  ),
                  WebsiteFooter(mobile: mobile, onSection: _scrollTo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
