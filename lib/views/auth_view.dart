import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/gharkilist_logo.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoginTab = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedEmoji = '👨';

  final List<String> _avatars = ['👨‍👩‍👧‍👦', '👨', '👩', '🧒', '👵', '👴', '🏠', '🍕', '🍳', '🛒'];

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchTab(bool isLogin) {
    if (_isLoginTab == isLogin) return;
    setState(() {
      _isLoginTab = isLogin;
      _formKey.currentState?.reset();
      _usernameController.clear();
      _displayNameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _handleSubmit(bool isHindi) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();

    try {
      if (_isLoginTab) {
        await authProvider.login(
          _usernameController.text,
          _passwordController.text,
        );
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw Exception(isHindi ? 'दोनों पासवर्ड मेल नहीं खाते' : 'Passwords do not match');
        }
        await authProvider.register(
          _usernameController.text,
          _displayNameController.text,
          _passwordController.text,
          _selectedEmoji,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception:', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final isHindi = settings.isHindi;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryGreen = const Color(0xFF00C853);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: textColor,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Premium Slate Logo
                GharkiListLogoWidget(language: settings.language, fontSize: 32, iconSize: 38),
                const SizedBox(height: 8),
                Text(
                  isHindi ? 'परिवार का सामान लेखा-जोखा' : 'Smart Household Inventory',
                  style: TextStyle(fontSize: 14, color: subtextColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 36),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Custom Tab Switcher
                        Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(
                                label: isHindi ? 'लॉगिन' : 'Login',
                                isSelected: _isLoginTab,
                                onTap: () => _switchTab(true),
                                primaryGreen: primaryGreen,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTabButton(
                                label: isHindi ? 'रजिस्टर' : 'Register',
                                isSelected: !_isLoginTab,
                                onTap: () => _switchTab(false),
                                primaryGreen: primaryGreen,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        Text(
                          isHindi ? 'यूज़रनेम' : 'Username',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: _buildInputDecoration(
                            hint: isHindi ? 'जैसे: papa, mummy' : 'e.g. papa, mummy',
                            isDark: isDark,
                            borderColor: borderColor,
                            prefixIcon: Icons.alternate_email,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isHindi ? 'कृपया यूज़रनेम दर्ज करें' : 'Please enter username';
                            }
                            if (val.contains(' ')) {
                              return isHindi ? 'स्पेस की अनुमति नहीं है' : 'Spaces are not allowed';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        if (!_isLoginTab) ...[
                          Text(
                            isHindi ? 'नाम (दिखने वाला)' : 'Display Name',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _displayNameController,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: _buildInputDecoration(
                              hint: isHindi ? 'जैसे: पापा, राहुल' : 'e.g. Papa, Rahul',
                              isDark: isDark,
                              borderColor: borderColor,
                              prefixIcon: Icons.person_outline,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return isHindi ? 'कृपया अपना नाम दर्ज करें' : 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        Text(
                          isHindi ? 'पासवर्ड' : 'Password',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: _buildInputDecoration(
                            hint: isHindi ? '••••••' : '••••••',
                            isDark: isDark,
                            borderColor: borderColor,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: subtextColor,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isHindi ? 'कृपया पासवर्ड दर्ज करें' : 'Please enter password';
                            }
                            if (val.length < 4) {
                              return isHindi ? 'पासवर्ड कम से कम 4 अक्षरों का होना चाहिए' : 'Password must be at least 4 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        if (!_isLoginTab) ...[
                          Text(
                            isHindi ? 'पासवर्ड की पुष्टि' : 'Confirm Password',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: _buildInputDecoration(
                              hint: isHindi ? '••••••' : '••••••',
                              isDark: isDark,
                              borderColor: borderColor,
                              prefixIcon: Icons.lock_outline,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return isHindi ? 'कृपया पासवर्ड की दोबारा पुष्टि करें' : 'Please confirm password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Avatar/Emoji Picker
                          Text(
                            isHindi ? 'प्रोफ़ाइल आइकॉन चुनें' : 'Choose Profile Icon',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 48,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _avatars.length,
                              itemBuilder: (context, idx) {
                                final emoji = _avatars[idx];
                                final isSelected = _selectedEmoji == emoji;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedEmoji = emoji),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryGreen.withValues(alpha: 0.15)
                                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? primaryGreen : borderColor,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        const SizedBox(height: 12),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : () => _handleSubmit(isHindi),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    _isLoginTab
                                        ? (isHindi ? 'लॉग इन करें' : 'Log In')
                                        : (isHindi ? 'प्रोफ़ाइल बनाएं' : 'Create Profile'),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryGreen,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryGreen : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required bool isDark,
    required Color borderColor,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      prefixIcon: Icon(prefixIcon, size: 18, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
      suffixIcon: suffixIcon,
      errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: const Color(0xFF00C853), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
