import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
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

  // TTS Voice state
  FlutterTts? _flutterTts;
  List<Map<String, String>> _availableVoices = [];
  String? _selectedVoice;
  String _selectedLanguage = 'en-US';
  bool _isLoadingVoices = false;

  final SavedWorksService _savedWorksService = SavedWorksService();
  final AppPreferencesService _appPreferencesService = AppPreferencesService();

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadDatabaseSize();
    _loadThemeMode();
    _loadTextSize();
    _initTTS();
    _loadTTSVoice();
    _loadTTSSpeechRate();
    // Load voices when screen initializes
    _loadAvailableVoices();
  }

  void _initTTS() {
    _flutterTts = FlutterTts();
  }

  Future<void> _loadTTSVoice() async {
    try {
      final voice = await _appPreferencesService.getTTSVoice();
      final language = await _appPreferencesService.getTTSLanguage();

      // Load voices first to ensure we have the list
      await _loadAvailableVoices();

      if (mounted) {
        setState(() {
          _selectedVoice = voice;
          _selectedLanguage = language;
        });
      }

      // Debug: Print loaded voice info
      print('Loaded voice from preferences: $voice');
      print('Loaded language from preferences: $language');
      if (voice != null) {
        final voiceExists = _availableVoices.any((v) => v['name'] == voice);
        print('Voice exists in available voices: $voiceExists');
        if (!voiceExists) {
          print(
            'Available voices: ${_availableVoices.map((v) => v['name']).take(10).toList()}',
          );
        }
      }
    } catch (e) {
      print('Error loading TTS voice: $e');
    }
  }

  Future<void> _loadAvailableVoices() async {
    if (_flutterTts == null) return;

    setState(() {
      _isLoadingVoices = true;
    });

    try {
      // Get available voices
      final voices = await _flutterTts!.getVoices;
      if (mounted) {
        setState(() {
          _availableVoices = List<Map<String, String>>.from(
            voices.map(
              (voice) => {
                'name': voice['name']?.toString() ?? '',
                'locale': voice['locale']?.toString() ?? '',
              },
            ),
          );
          _isLoadingVoices = false;
        });
        // Debug: Print total voices loaded
        print('Total voices loaded: ${_availableVoices.length}');
        print('Selected language: $_selectedLanguage');
        final filteredCount = _availableVoices
            .where(
              (voice) =>
                  voice['locale']?.startsWith(
                    _selectedLanguage.split('-')[0],
                  ) ??
                  false,
            )
            .length;
        print('Filtered voices count: $filteredCount');
      }
    } catch (e) {
      print('Error loading available voices: $e');
      if (mounted) {
        setState(() {
          _isLoadingVoices = false;
        });
      }
    }
  }

  Future<void> _saveTTSVoice(String? voice) async {
    try {
      await _appPreferencesService.setTTSVoice(voice);
      if (mounted) {
        setState(() {
          _selectedVoice = voice;
        });
      }
    } catch (e) {
      print('Error saving TTS voice: $e');
    }
  }

  Future<void> _saveTTSLanguage(String language) async {
    try {
      await _appPreferencesService.setTTSLanguage(language);
      if (mounted) {
        setState(() {
          _selectedLanguage = language;
        });
      }
      // Reload voices when language changes
      await _loadAvailableVoices();
    } catch (e) {
      print('Error saving TTS language: $e');
    }
  }

  Future<void> _loadTTSSpeechRate() async {
    try {
      final speechRate = await _appPreferencesService.getTTSSpeechRate();
      if (mounted) {
        setState(() {
          _ttsSpeechRate = speechRate;
        });
      }
    } catch (e) {
      print('Error loading TTS speech rate: $e');
    }
  }

  Future<void> _saveTTSSpeechRate(int speechRate) async {
    try {
      await _appPreferencesService.setTTSSpeechRate(speechRate);
    } catch (e) {
      print('Error saving TTS speech rate: $e');
    }
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
          AppHeader(
            title: 'Setting',
            isHaveIcon: false,
            onLeftIconTap: () {
              context.push('/chatbot-suggestion');
            },
          ),
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
          onTap: () => _openPrivacyPolicy(),
        ),
        _buildDivider(),
        _buildMenuItem(
          iconPath: 'assets/ic_fanfiction/ic_term.svg',
          title: 'Terms & Conditions',
          onTap: () => _openTermsOfUse(),
        ),
        _buildDivider(),
        _buildMenuItem(
          iconPath: 'assets/ic_fanfiction/ic_request_feature.svg',
          title: 'Request A Feature',
          onTap: () => _openEmail(subject: 'Request A Feature'),
        ),
        _buildDivider(),
        _buildMenuItem(
          iconPath: 'assets/ic_fanfiction/ic_report.svg',
          title: 'Report A Bug',
          onTap: () => _openEmail(subject: 'Report A Bug'),
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

  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse('https://sites.google.com/view/fanficc/home');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Privacy Policy'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Privacy Policy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openTermsOfUse() async {
    final url = Uri.parse('https://sites.google.com/view/fanficc/terms-of-use');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Terms of Use'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Terms of Use: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEmail({required String subject}) async {
    final email = 'frovrio@gmail.com';
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    // Show all voices instead of filtering by language
    // If you want to filter by language, uncomment the code below
    // final filteredVoices = _availableVoices
    //     .where(
    //       (voice) =>
    //           voice['locale']?.startsWith(_selectedLanguage.split('-')[0]) ??
    //           false,
    //     )
    //     .toList();

    // Show all available voices
    final filteredVoices = _availableVoices;

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
        if (_isLoadingVoices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'Loading voices...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Default option
                _buildVoiceItem(
                  displayName: 'Default - English',
                  isSelected: _selectedVoice == null,
                  onTap: () {
                    // When selecting Default, also reset language to en-US
                    _saveTTSVoice(null);
                    _saveTTSLanguage('en-US');
                  },
                ),
                const SizedBox(height: 8),
                // Voice options
                ...filteredVoices.map((voice) {
                  final voiceName = voice['name'] ?? '';
                  final locale = voice['locale'] ?? '';
                  final isSelected = _selectedVoice == voiceName;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildVoiceItem(
                      displayName: _formatVoiceName(voiceName, locale),
                      isSelected: isSelected,
                      onTap: () => _saveTTSVoice(voiceName),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceItem({
    required String displayName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          displayName,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  String _formatVoiceName(String voiceName, String locale) {
    // Extract language name from locale (e.g., "da-DK" -> "Danish")
    final languageName = _getLanguageNameFromLocale(locale);

    // Extract voice name (remove locale prefix if exists)
    String cleanVoiceName = voiceName;
    if (voiceName.contains('-')) {
      final parts = voiceName.split('-');
      // Try to get a readable name (usually the first part or a meaningful part)
      if (parts.length > 2) {
        // Format like "en-us-x-xxx-local" -> take meaningful parts
        final meaningfulParts = parts
            .where((part) => part.length > 2 && !part.contains('x'))
            .toList();
        cleanVoiceName = meaningfulParts.isNotEmpty
            ? meaningfulParts.first
            : parts.first;
      } else {
        cleanVoiceName = parts.first;
      }
    }

    // Capitalize first letter
    if (cleanVoiceName.isNotEmpty) {
      cleanVoiceName =
          cleanVoiceName[0].toUpperCase() + cleanVoiceName.substring(1);
    }

    return '$cleanVoiceName - $languageName';
  }

  String _getLanguageNameFromLocale(String locale) {
    // Extract language code (e.g., "da-DK" -> "da")
    final langCode = locale.split('-').first.toLowerCase();

    // Map language codes to display names
    final languageMap = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'da': 'Danish',
      'nl': 'Dutch',
      'pl': 'Polish',
      'ru': 'Russian',
      'sv': 'Swedish',
      'tr': 'Turkish',
      'ar': 'Arabic',
      'hi': 'Hindi',
      'th': 'Thai',
      'vi': 'Vietnamese',
    };

    return languageMap[langCode] ?? langCode.toUpperCase();
  }

  String _getVoiceDisplayName(String voiceName) {
    // Extract a readable name from voice name
    // Voice names are usually in format like "en-us-x-xxx-local" or "Samantha"
    if (voiceName.contains('-')) {
      final parts = voiceName.split('-');
      if (parts.length >= 2) {
        // Try to get a readable name
        return voiceName;
      }
    }
    return voiceName;
  }

  String _getLanguageDisplayName(String languageCode) {
    // Map language codes to display names
    final languageMap = {
      'en-US': 'English (United States)',
      'en-GB': 'English (United Kingdom)',
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
    };
    return languageMap[languageCode] ?? languageCode;
  }

  Future<void> _showVoiceSelectionDialog() async {
    if (_isLoadingVoices) {
      // Show loading dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading voices...',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      );
      await _loadAvailableVoices();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }

    // Filter voices by selected language
    final filteredVoices = _availableVoices
        .where(
          (voice) =>
              voice['locale']?.startsWith(_selectedLanguage.split('-')[0]) ??
              false,
        )
        .toList();

    // Show voice selection dialog
    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Voice',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Language selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLanguageSelector(),
              ),
              const SizedBox(height: 16),
              // Voice list
              Flexible(
                child: filteredVoices.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No voices available for selected language',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount:
                            filteredVoices.length +
                            1, // +1 for "Default" option
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Default option
                            final isSelected = _selectedVoice == null;
                            return ListTile(
                              title: Text(
                                'Default - ${_getLanguageDisplayName(_selectedLanguage)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                              onTap: () {
                                _saveTTSVoice(null);
                                Navigator.of(context).pop();
                              },
                            );
                          }

                          final voice = filteredVoices[index - 1];
                          final voiceName = voice['name'] ?? '';
                          final isSelected = _selectedVoice == voiceName;

                          return ListTile(
                            title: Text(
                              _getVoiceDisplayName(voiceName),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.7),
                              ),
                            ),
                            subtitle: Text(
                              voice['locale'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                            onTap: () {
                              _saveTTSVoice(voiceName);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildLanguageSelector() {
    // Get unique languages from available voices
    final languages =
        _availableVoices
            .map((voice) => voice['locale']?.split('-')[0] ?? 'en')
            .toSet()
            .toList()
          ..sort();

    // Add common languages if not in list
    final commonLanguages = [
      'en',
      'es',
      'fr',
      'de',
      'it',
      'pt',
      'ja',
      'ko',
      'zh',
    ];
    for (final lang in commonLanguages) {
      if (!languages.contains(lang)) {
        languages.add(lang);
      }
    }
    languages.sort();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: DropdownButton<String>(
        value: _selectedLanguage.split('-')[0],
        isExpanded: true,
        dropdownColor: const Color(0xFF2E2E2E),
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
        underline: const SizedBox(),
        items: languages.map((lang) {
          return DropdownMenuItem<String>(
            value: lang,
            child: Text(_getLanguageDisplayName(lang)),
          );
        }).toList(),
        onChanged: (String? newLang) {
          if (newLang != null) {
            // Try to find a full locale (e.g., en-US) or use the language code
            final fullLocale = _availableVoices
                .map((v) => v['locale'])
                .firstWhere(
                  (locale) => locale?.startsWith(newLang) ?? false,
                  orElse: () => newLang == 'en' ? 'en-US' : newLang,
                );
            _saveTTSLanguage(fullLocale ?? newLang);
          }
        },
      ),
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
                  final newRate = (_ttsSpeechRate + 10).clamp(50, 200);
                  setState(() {
                    _ttsSpeechRate = newRate;
                  });
                  // Save speech rate preference
                  _saveTTSSpeechRate(newRate);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSpeechRateButton(
                label: '-',
                onTap: () {
                  final newRate = (_ttsSpeechRate - 10).clamp(50, 200);
                  setState(() {
                    _ttsSpeechRate = newRate;
                  });
                  // Save speech rate preference
                  _saveTTSSpeechRate(newRate);
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
