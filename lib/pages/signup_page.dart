import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/validation_service.dart';
import '../navigation/app_navigator.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to collections page using centralized navigator
        AppNavigator.navigateToCollections(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle(forceAccountPicker: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed up with Google!'),
            backgroundColor: Colors.green,
          ),
        );
        AppNavigator.navigateToCollections(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleLogIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            children: [
              // Artefacto Title
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 48),
                child: Text(
                  'Artefacto',
                  style: GoogleFonts.tangerine(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5A7A73),
                    height: 1.0,
                  ),
                ),
              ),

              Container(
                constraints: const BoxConstraints(maxWidth: 448),
                decoration: BoxDecoration(
                  color: const Color(0xFFB4C7BD),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F1F1F),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // First Name Input
                      _buildTextField(
                        controller: _firstNameController,
                        hintText: 'First name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) =>
                            ValidationService.validateName(value, 'First name'),
                      ),
                      const SizedBox(height: 16),

                      // Last Name Input
                      _buildTextField(
                        controller: _lastNameController,
                        hintText: 'Last name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) =>
                            ValidationService.validateName(value, 'Last name'),
                      ),
                      const SizedBox(height: 16),

                      // Email Input
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: ValidationService.validateEmail,
                      ),
                      const SizedBox(height: 16),

                      // Password Input
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        isPassword: true,
                        validator: (value) =>
                            ValidationService.validatePassword(
                              value,
                              minLength: 8,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Input
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        isPassword: true,
                        validator: (value) =>
                            ValidationService.validateConfirmPassword(
                              value,
                              _passwordController.text,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A5A53),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            disabledBackgroundColor: const Color(
                              0xFF3A5A53,
                            ).withOpacity(0.6),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFF8A9D95),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Continue with',
                                style: TextStyle(
                                  color: Color(0xFF5A7A73),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFF8A9D95),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Social Sign Up Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google Button
                          _SocialSignUpButton(
                            onPressed: _handleGoogleSignUp,
                            child: Image.network(
                              'https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),

                      // Log In Link
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF3A5A53),
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(text: 'Already have account ? '),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: _handleLogIn,
                                    child: const Text(
                                      'Log in',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF3A5A53),
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool? obscureText,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    bool isPassword = false,
  }) {
    bool isHidden = isPassword
        ? (controller == _passwordController
              ? _isPasswordHidden
              : _isConfirmPasswordHidden)
        : (obscureText ?? false);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !_isLoading,
      obscureText: isHidden,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(
          prefixIcon ??
              (keyboardType == TextInputType.emailAddress
                  ? Icons.email_outlined
                  : isPassword
                  ? Icons.lock_outline
                  : Icons.person_outline),
          color: const Color(0xFF5A7A73),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isHidden ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF5A7A73),
                ),
                onPressed: () {
                  setState(() {
                    if (controller == _passwordController) {
                      _isPasswordHidden = !_isPasswordHidden;
                    } else if (controller == _confirmPasswordController) {
                      _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                    }
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A5A53), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}

class _SocialSignUpButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _SocialSignUpButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 96,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
