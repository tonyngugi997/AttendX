import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ===================== Models =====================

class User {
  final int? id;
  final String username;
  final String email;
  
  User({this.id, required this.username, required this.email});
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
    );
  }
}

class AuthResponse {
  final String? message;
  final User? user;
  final String? error;
  final String? token;
  
  AuthResponse({this.message, this.user, this.error, this.token});
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      error: json['error'],
      token: json['token'],
    );
  }
  
  bool get isSuccess => error == null && (message != null || token != null);
}

// ===================== Services =====================

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:5000';
  
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      
      final Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return AuthResponse(error: 'Invalid server response');
      }
      
      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        return AuthResponse(
          error: responseData['error'] ?? 'Invalid request',
        );
      } else if (response.statusCode == 401) {
        return AuthResponse(
          error: responseData['error'] ?? 'Invalid credentials',
        );
      } else if (response.statusCode >= 500) {
        return AuthResponse(error: 'Server error. Please try again later.');
      } else {
        return AuthResponse(
          error: responseData['error'] ?? 'Login failed',
        );
      }
    } catch (e) {
      if (e.toString().contains('Timeout')) {
        return AuthResponse(error: 'Connection timeout. Check your internet.');
      }
      return AuthResponse(error: 'Network error. Please try again.');
    }
  }
  
  Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/register');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      
      final Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return AuthResponse(error: 'Invalid server response');
      }
      
      if (response.statusCode == 201) {
        return AuthResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        return AuthResponse(
          error: responseData['error'] ?? 'Invalid request',
        );
      } else if (response.statusCode == 409) {
        return AuthResponse(
          error: responseData['error'] ?? 'User already exists',
        );
      } else if (response.statusCode >= 500) {
        return AuthResponse(error: 'Server error. Please try again later.');
      } else {
        return AuthResponse(
          error: responseData['error'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      if (e.toString().contains('Timeout')) {
        return AuthResponse(error: 'Connection timeout. Check your internet.');
      }
      return AuthResponse(error: 'Network error. Please try again.');
    }
  }
}

// ===================== Validators =====================

class Validator {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }
  
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 50) {
      return 'Username must be less than 50 characters';
    }
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'Include at least one uppercase letter';
    }
    if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
      return 'Include at least one number';
    }
    return null;
  }
}

// ===================== Custom Themes =====================

class AppTheme {
  static const Color primaryLight = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42B2);
  static const Color accentCyan = Color(0xFF00D2FF);
  static const Color accentPurple = Color(0xFF9D4EDD);
  static const Color surfaceLight = Color(0xFF1E1E2E);
  static const Color surfaceDark = Color(0xFF151522);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8D0);
  
  static final Gradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color(0xFF0A0A0F),
      const Color(0xFF1A1A2E),
      const Color(0xFF16213E),
      const Color(0xFF1A1A2E),
      const Color(0xFF0A0A0F),
    ],
    stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
  );
  
  static final Gradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.1),
      Colors.white.withOpacity(0.05),
    ],
  );
  
  static BoxDecoration glassmorphism({double borderRadius = 30}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 5,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: primaryLight.withOpacity(0.1),
          blurRadius: 30,
          spreadRadius: -5,
          offset: const Offset(-5, -5),
        ),
      ],
    );
  }
}

// ===================== Custom Widgets =====================

class AnimatedGradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  
  const AnimatedGradientText({
    super.key,
    required this.text,
    this.fontSize = 42,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          AppTheme.accentCyan,
          AppTheme.accentPurple,
          AppTheme.primaryLight,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: GoogleFonts.syne(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(duration: 3000.ms, color: Colors.white.withOpacity(0.3));
  }
}

class NeonContainer extends StatelessWidget {
  final Widget child;
  final bool isFocused;
  
  const NeonContainer({
    super.key,
    required this.child,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppTheme.accentCyan.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppTheme.accentPurple.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: -5,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class FloatingParticle extends StatefulWidget {
  final double left;
  final double top;
  final double size;
  final Duration duration;
  
  const FloatingParticle({
    super.key,
    required this.left,
    required this.top,
    required this.size,
    required this.duration,
  });

  @override
  State<FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(20, 20),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: widget.left + _animation.value.dx,
          top: widget.top + _animation.value.dy,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentCyan.withOpacity(0.3),
                  AppTheme.accentPurple.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(widget.size / 2),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? errorText;
  final bool isPassword;
  final VoidCallback? onVisibilityToggle;
  final bool obscureText;
  
  const AnimatedInput({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.errorText,
    this.isPassword = false,
    this.onVisibilityToggle,
    this.obscureText = false,
  });

  @override
  State<AnimatedInput> createState() => _AnimatedInputState();
}

class _AnimatedInputState extends State<AnimatedInput> {
  bool isFocused = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeonContainer(
      isFocused: isFocused,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? widget.obscureText : false,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                widget.icon,
                color: isFocused ? AppTheme.accentCyan : Colors.white.withOpacity(0.5),
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        widget.obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: widget.onVisibilityToggle,
                    )
                  : null,
              labelText: widget.label,
              labelStyle: GoogleFonts.inter(
                color: isFocused ? AppTheme.accentCyan : Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: isFocused ? FontWeight.w600 : FontWeight.normal,
              ),
              errorText: widget.errorText,
              errorStyle: GoogleFonts.inter(
                color: Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: widget.errorText != null
                      ? Colors.orangeAccent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: widget.errorText != null
                      ? Colors.orangeAccent
                      : AppTheme.accentCyan,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CyberButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  
  const CyberButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.text,
  });

  @override
  State<CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<CyberButton> with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isHovered
                      ? [AppTheme.accentPurple, AppTheme.accentCyan]
                      : [AppTheme.primaryLight, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isHovered ? AppTheme.accentCyan : AppTheme.primaryLight)
                        .withOpacity(0.3 + _pulseController.value * 0.2),
                    blurRadius: 20 + _pulseController.value * 10,
                    spreadRadius: isHovered ? 2 : 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated border
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  
                  // Glitch effect on hover
                  if (isHovered)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Content
                  Center(
                    child: widget.isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          )
                        : Text(
                            widget.text,
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ],
              ),
            ).animate().scale(
              duration: 200.ms,
              curve: Curves.easeInOut,
              alignment: Alignment.center,
            );
          },
        ),
      ),
    );
  }
}

// ===================== Main Widget =====================

class Authenticator extends StatefulWidget {
  const Authenticator({super.key});

  @override
  State<Authenticator> createState() => _AuthenticatorState();
}

class _AuthenticatorState extends State<Authenticator> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // Services
  final AuthService _authService = AuthService();
  
  // State
  bool isLoading = false;
  bool hidePassword = true;
  bool isLoginMode = false; // Toggle between login and register
  
  // Validation state
  String? emailError;
  String? usernameError;
  String? passwordError;
  
  // Animation controllers
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  
  @override
  void initState() {
    super.initState();
    
    // Setup main animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    // Add listeners for real-time validation
    emailController.addListener(_clearEmailError);
    usernameController.addListener(_clearUsernameError);
    passwordController.addListener(_clearPasswordError);
    
    // Set preferred orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
  
  void _clearEmailError() {
    if (emailError != null) {
      setState(() => emailError = null);
    }
  }
  
  void _clearUsernameError() {
    if (usernameError != null) {
      setState(() => usernameError = null);
    }
  }
  
  void _clearPasswordError() {
    if (passwordError != null) {
      setState(() => passwordError = null);
    }
  }
  
  bool _validateInputs() {
    setState(() {
      emailError = Validator.validateEmail(emailController.text);
      usernameError = isLoginMode ? null : Validator.validateUsername(usernameController.text);
      passwordError = Validator.validatePassword(passwordController.text);
    });
    
    return emailError == null && (isLoginMode || usernameError == null) && passwordError == null;
  }
  
  Future<void> loginUser() async {
    // Haptic feedback - using correct method for web
    HapticFeedback.lightImpact();
    
    if (!_validateInputs()) {
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      final response = await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      
      if (mounted) {
        setState(() => isLoading = false);
        
        if (response.isSuccess) {
          HapticFeedback.heavyImpact();
          
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: AppTheme.glassmorphism(borderRadius: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 80,
                    ).animate().scale(duration: 500.ms),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome Back!',
                      style: GoogleFonts.orbitron(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Login successful!',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          );
          
          // Clear form
          emailController.clear();
          passwordController.clear();
          
        } else {
          HapticFeedback.mediumImpact();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      response.error ?? 'Login failed',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.all(20),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> registerUser() async {
    // Haptic feedback - using correct method for web
    HapticFeedback.lightImpact();
    
    if (!_validateInputs()) {
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      final response = await _authService.register(
        email: emailController.text.trim(),
        username: usernameController.text.trim(),
        password: passwordController.text,
      );
      
      if (mounted) {
        setState(() => isLoading = false);
        
        if (response.isSuccess) {
          HapticFeedback.heavyImpact();
          
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: AppTheme.glassmorphism(borderRadius: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 80,
                    ).animate().scale(duration: 500.ms),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome Aboard!',
                      style: GoogleFonts.orbitron(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      response.message ?? 'Registration successful!',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          );
          
          // Clear form
          emailController.clear();
          usernameController.clear();
          passwordController.clear();
          
        } else {
          HapticFeedback.mediumImpact();
          
          // Special handling for user already exists error
          if (response.error?.contains('already exists') == true) {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: AppTheme.glassmorphism(borderRadius: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_circle,
                        color: Colors.orange,
                        size: 80,
                      ).animate().scale(duration: 500.ms),
                      const SizedBox(height: 20),
                      Text(
                        'Account Exists',
                        style: GoogleFonts.orbitron(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'An account with this email or username already exists.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Try Again',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                isLoginMode = true;
                                usernameController.clear();
                                emailError = null;
                                usernameError = null;
                                passwordError = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentCyan,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text('Go to Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        response.error ?? 'Registration failed',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.withOpacity(0.8),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.all(20),
              ),
            );
          }
        }
      }
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Try Again',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                isLoginMode = true;
                                usernameController.clear();
                                emailError = null;
                                usernameError = null;
                                passwordError = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentCyan,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text('Go to Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        response.error ?? 'Registration failed',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.withOpacity(0.8),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.all(20),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Animated background
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
            
            // Floating particles
            ...List.generate(10, (index) {
              return FloatingParticle(
                left: (index * 50.0) % size.width,
                top: (index * 70.0) % size.height,
                size: 80.0 + (index * 10) % 150,
                duration: Duration(seconds: 10 + index),
              );
            }),
            
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: ScaleTransition(
                        scale: _scaleController,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              padding: const EdgeInsets.all(30),
                              decoration: AppTheme.glassmorphism(borderRadius: 30),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Logo and title
                                  ElasticIn(
                                    delay: const Duration(milliseconds: 200),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                AppTheme.accentCyan.withOpacity(0.3),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.rocket_launch,
                                            color: Colors.white,
                                            size: 60,
                                          ).animate()
                                           .shake(duration: 2000.ms)
                                           .then()
                                           .rotate(duration: 20000.ms),
                                        ),
                                        const SizedBox(height: 20),
                                        AnimatedGradientText(
                                          text: "AttendX",
                                          fontSize: 48,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Employee Attendance Intelligence",
                                          style: GoogleFonts.inter(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 14,
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.w300,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 40),
                                  
                                  // Form fields
                                  FadeInLeft(
                                    delay: const Duration(milliseconds: 400),
                                    child: AnimatedInput(
                                      controller: emailController,
                                      label: "Email Address",
                                      icon: Icons.alternate_email,
                                      errorText: emailError,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Username field only for registration
                                  if (!isLoginMode)
                                    FadeInRight(
                                      delay: const Duration(milliseconds: 500),
                                      child: AnimatedInput(
                                        controller: usernameController,
                                        label: "Username",
                                        icon: Icons.person_outline,
                                        errorText: usernameError,
                                      ),
                                    ),
                                  
                                  if (!isLoginMode) const SizedBox(height: 20),
                                  
                                  FadeInLeft(
                                    delay: const Duration(milliseconds: 600),
                                    child: AnimatedInput(
                                      controller: passwordController,
                                      label: "Password",
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      obscureText: hidePassword,
                                      onVisibilityToggle: () {
                                        setState(() {
                                          hidePassword = !hidePassword;
                                        });
                                      },
                                      errorText: passwordError,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Action button
                                  FadeInUp(
                                    delay: const Duration(milliseconds: 800),
                                    child: CyberButton(
                                      onPressed: isLoading ? null : (isLoginMode ? loginUser : registerUser),
                                      isLoading: isLoading,
                                      text: isLoginMode ? "LOGIN" : "CREATE ACCOUNT",
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Toggle between login and register
                                  FadeInUp(
                                    delay: const Duration(milliseconds: 900),
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          isLoginMode = !isLoginMode;
                                          // Clear errors when switching modes
                                          emailError = null;
                                          usernameError = null;
                                          passwordError = null;
                                          // Clear username field when switching to login
                                          if (isLoginMode) {
                                            usernameController.clear();
                                          }
                                        });
                                      },
                                      child: Text(
                                        isLoginMode 
                                          ? "Don't have an account? Sign up"
                                          : "Already have an account? Login",
                                        style: GoogleFonts.inter(
                                          color: AppTheme.accentCyan,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Password strength indicator (only for registration)
                                  if (!isLoginMode && passwordController.text.isNotEmpty)
                                    FadeInUp(
                                      delay: const Duration(milliseconds: 700),
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 10),
                                          Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(2),
                                              color: Colors.white.withOpacity(0.1),
                                            ),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: _getPasswordStrength(),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(2),
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Colors.red,
                                                      Colors.orange,
                                                      Colors.green,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            _getPasswordStrengthText(),
                                            style: GoogleFonts.inter(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 12,
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  double _getPasswordStrength() {
    final password = passwordController.text;
    if (password.isEmpty) return 0.0;
    
    double strength = 0.0;
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.3;
    
    return strength.clamp(0.0, 1.0);
  }
  
  String _getPasswordStrengthText() {
    final strength = _getPasswordStrength();
    if (strength < 0.3) return 'Weak password';
    if (strength < 0.6) return 'Medium password';
    if (strength < 0.8) return 'Strong password';
    return 'Very strong password';
  }
}