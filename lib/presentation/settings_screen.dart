import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _disableWordMasking = false;
  int _textSize = 14;
  String _selectedTheme = 'Default';
  int _ttsSpeechRate = 100;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      child: Column(
        children: [
          const AppHeader(title: 'Setting', isHaveIcon: false),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // App Info Section
                  _buildAppInfo(),
                  const SizedBox(height: 24),
                  // Menu Items
                  _buildMenuItems(),
                  const SizedBox(height: 24),
                  // Clear Caches Section
                  _buildClearCachesSection(),
                  const SizedBox(height: 24),
                  // Disable Word Masking
                  _buildDisableWordMasking(),
                  const SizedBox(height: 24),
                  // Text Size Section
                  _buildTextSizeSection(),
                  const SizedBox(height: 24),
                  // Theme Section
                  _buildThemeSection(),
                  const SizedBox(height: 24),
                  // TTS Voice Section
                  _buildTTSVoiceSection(),
                  const SizedBox(height: 24),
                  // TTS Speech Rate Section
                  _buildTTSSpeechRateSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF7d26cd),
            border: Border.all(color: const Color(0xFF37393f), width: 0.3),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/img_book.svg',
              width: 40,
              height: 40,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storedo Reader Pro',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1.2.1 (undefined)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(
          iconPath: 'assets/ic_fanfiction/ic_subscription.svg',
          title: 'Subscribe',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuItem(
          iconPath: 'assets/ic_fanfiction/ic_policy.svg',
          title: 'Privacy Policy',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuItem(
          iconPath: 'assets/ic_fanfiction/ic_term.svg',
          title: 'Terms & Conditions',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuItem(
          iconPath: 'assets/ic_fanfiction/ic_request_feature.svg',
          title: 'Request A Feature',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuItem(
          iconPath: 'assets/ic_fanfiction/ic_report.svg',
          title: 'Report A Bug',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuItem(
          iconPath: 'assets/ic_fanfiction/ic_restore_purchase.svg',
          title: 'Restore Purchases',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuItem(
          iconPath: 'assets/ic_fanfiction/ic_manage_subscription.svg',
          title: 'Manage Subscription',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.2),
      height: 1,
      thickness: 1,
    );
  }

  Widget _buildClearCachesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              'assets/ic_fanfiction/ic_clear_caches.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Clear Caches',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Size: 1.3 GB',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(90),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.15, // 52px / 335px ≈ 0.15
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF20a852),
                    borderRadius: BorderRadius.circular(90),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFe7165b).withOpacity(0.1),
            border: Border.all(color: const Color(0xFFe7165b), width: 1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(30),
              child: Center(
                child: Text(
                  'Delete All Stories',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFe7165b),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisableWordMasking() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/ic_fanfiction/ic_disable_word.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Disable Word Masking',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.star, size: 14, color: Colors.amber),
              ],
            ),
            Switch(
              value: _disableWordMasking,
              onChanged: (value) {
                setState(() {
                  _disableWordMasking = value;
                });
              },
              activeColor: const Color(0xFF7d26cd),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Text Size',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              'Pt $_textSize',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Lorem ipsum dolor sit amet, consectetur',
          style: GoogleFonts.poppins(
            fontSize: _textSize.toDouble(),
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.7),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextSizeButton(
                label: '+A',
                onTap: () {
                  setState(() {
                    _textSize = (_textSize + 2).clamp(8, 24);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextSizeButton(
                label: '-A',
                onTap: () {
                  setState(() {
                    _textSize = (_textSize - 2).clamp(8, 24);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextSizeButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    final themes = [
      {'name': 'Default', 'color': Colors.black, 'isSelected': true},
      {'name': 'Light', 'color': const Color(0xFFfefefe), 'isSelected': false},
      {
        'name': 'Paper',
        'color': const Color(0xFF1d1d1d),
        'isSelected': false,
        'isPremium': true,
      },
      {
        'name': 'Calm',
        'color': const Color(0xFF3b392c),
        'isSelected': false,
        'isPremium': true,
      },
      {
        'name': 'Blue',
        'color': const Color(0xFF3f4b71),
        'isSelected': false,
        'isPremium': true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              'assets/ic_fanfiction/ic_setting_theme.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Theme',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: themes.map((theme) {
            final isSelected = _selectedTheme == theme['name'];
            final isPremium = theme['isPremium'] == true;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTheme = theme['name'] as String;
                });
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme['color'] as Color,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF7d26cd)
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 3 : 3,
                      ),
                      borderRadius: BorderRadius.circular(360),
                    ),
                    child: Center(
                      child: Text(
                        theme['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: theme['name'] == 'Light'
                              ? const Color(0xFF121212)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (isPremium)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Icon(Icons.star, size: 10, color: Colors.amber),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTTSVoiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              'assets/ic_fanfiction/ic_setting_voice.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'TTS Voice',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Default - English (United States)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTTSSpeechRateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              'assets/ic_fanfiction/ic_speech_rate.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'TTS Speech Rate',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.star, size: 14, color: Colors.amber),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '$_ttsSpeechRate',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSpeechRateButton(
                label: '+',
                onTap: () {
                  setState(() {
                    _ttsSpeechRate = (_ttsSpeechRate + 10).clamp(50, 200);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSpeechRateButton(
                label: '-',
                onTap: () {
                  setState(() {
                    _ttsSpeechRate = (_ttsSpeechRate - 10).clamp(50, 200);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeechRateButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
