import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/app_header.dart';
import '../services/saved_works_service.dart';
import '../services/app_preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _disableWordMasking = false;
  int _textSize = 10;
  String _selectedTheme = 'Default';
  int _ttsSpeechRate = 100;
  String _appVersion = 'Loading...';
  String _buildNumber = '';
  String _databaseSize = '0 B';
  double _databaseSizeProgress = 0.0;
  bool _isDeleting = false;

  final SavedWorksService _savedWorksService = SavedWorksService();
  final AppPreferencesService _appPreferencesService = AppPreferencesService();

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadDatabaseSize();
    _loadThemeMode();
    _loadTextSize();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = 'Unknown';
          _buildNumber = '';
        });
      }
    }
  }

  Future<void> _loadDatabaseSize() async {
    try {
      final sizeInBytes = await _savedWorksService.getDatabaseSize();
      if (mounted) {
        setState(() {
          _databaseSize = _formatBytes(sizeInBytes);
          // Calculate progress (assuming max size is 2GB for progress bar)
          const maxSizeBytes = 2 * 1024 * 1024 * 1024; // 2GB
          _databaseSizeProgress = (sizeInBytes / maxSizeBytes).clamp(0.0, 1.0);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _databaseSize = '0 B';
          _databaseSizeProgress = 0.0;
        });
      }
    }
  }

  Future<void> _loadThemeMode() async {
    try {
      final themeMode = await _appPreferencesService.getThemeMode();
      if (mounted) {
        setState(() {
          _selectedTheme = themeMode;
        });
      }
    } catch (e) {
      print('Error loading theme mode: $e');
    }
  }

  Future<void> _saveThemeMode(String themeMode) async {
    try {
      await _appPreferencesService.setThemeMode(themeMode);
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }

  Future<void> _loadTextSize() async {
    try {
      final textSize = await _appPreferencesService.getTextSize();
      if (mounted) {
        setState(() {
          _textSize = textSize;
        });
      }
    } catch (e) {
      print('Error loading text size: $e');
    }
  }

  Future<void> _saveTextSize(int textSize) async {
    try {
      await _appPreferencesService.setTextSize(textSize);
    } catch (e) {
      print('Error saving text size: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Future<void> _deleteAllStories() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Delete All Stories',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to delete all saved stories? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFe7165b),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final success = await _savedWorksService.clearAllSavedWorks();
        if (mounted) {
          if (success) {
            // Reload database size
            await _loadDatabaseSize();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'All stories deleted successfully',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: const Color(0xFF20a852),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to delete stories',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${e.toString()}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

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
                  const SizedBox(height: 24),
                  // App Info Section
                  _buildAppInfo(),
                  const SizedBox(height: 12),
                  // Menu Items
                  _buildMenuItems(),
                  const SizedBox(height: 24),
                  // Clear Caches Section
                  _buildClearCachesSection(),
                  const SizedBox(height: 24),
                  // Disable Word Masking
                  // _buildDisableWordMasking(),
                  // const SizedBox(height: 24),
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
              height: 32,
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
            const SizedBox(height: 3),
            Text(
              '$_appVersion ($_buildNumber)',
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
        // _buildMenuItem(
        //   iconPath: 'assets/ic_fanfiction/ic_subscription.svg',
        //   title: 'Subscribe',
        //   onTap: () {},
        // ),
        // _buildDivider(),
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
        // _buildMenuItem(
        //   iconPath: 'assets/ic_fanfiction/ic_restore_purchase.svg',
        //   title: 'Restore Purchases',
        //   onTap: () {},
        // ),
        // _buildDivider(),
        // _buildMenuItem(
        //   iconPath: 'assets/ic_fanfiction/ic_manage_subscription.svg',
        //   title: 'Manage Subscription',
        //   onTap: () {},
        // ),
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
              'Database Size: $_databaseSize',
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
                widthFactor: _databaseSizeProgress.clamp(0.0, 1.0),
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
              onTap: _isDeleting ? null : _deleteAllStories,
              borderRadius: BorderRadius.circular(30),
              child: Center(
                child: _isDeleting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFFe7165b),
                          ),
                        ),
                      )
                    : Text(
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
        Center(
          child: Text(
            'Lorem ipsum dolor sit amet, consectetur',
            style: GoogleFonts.poppins(
              fontSize: _textSize.toDouble(),
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextSizeButton(
                label: '+A',
                onTap: () {
                  if (_textSize < 20) {
                    final newSize = _textSize + 2;
                    setState(() {
                      _textSize = newSize;
                    });
                    // Save text size preference
                    _saveTextSize(newSize);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextSizeButton(
                label: '-A',
                onTap: () {
                  if (_textSize > 10) {
                    final newSize = _textSize - 2;
                    setState(() {
                      _textSize = newSize;
                    });
                    // Save text size preference
                    _saveTextSize(newSize);
                  }
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
            return GestureDetector(
              onTap: () {
                final themeName = theme['name'] as String;
                setState(() {
                  _selectedTheme = themeName;
                });
                // Save theme preference
                _saveThemeMode(themeName);
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
                  // if (isPremium)
                  //   Positioned(
                  //     right: -2,
                  //     top: -2,
                  //     child: Icon(Icons.star, size: 10, color: Colors.amber),
                  //   ),
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
        Center(
          child: Text(
            '$_ttsSpeechRate',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
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
