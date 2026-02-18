import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _businessNameController = TextEditingController();

  int _step = 0; // 0: phone, 1: otp, 2: details, 3: pin

  String get _fullPhone {
    final phone = _phoneController.text.trim();
    if (phone.startsWith('0')) return '254${phone.substring(1)}';
    if (phone.startsWith('+254')) return phone.substring(1);
    return phone;
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.requestOtp(_fullPhone);

    if (auth.error == null && mounted) {
      setState(() => _step = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent! Check your phone.'), backgroundColor: AppColors.success),
      );
    } else if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error),
      );
    }
  }

  void _verifyOtp() {
    if (_otpController.text.length == 6) {
      setState(() => _step = 2);
    }
  }

  void _proceedToPin() {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _businessNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() => _step = 3);
  }

  Future<void> _register() async {
    if (_pinController.text.length != 4) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      phoneNumber: _fullPhone,
      otp: _otpController.text,
      pin: _pinController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      businessName: _businessNameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i <= _step ? AppColors.primaryLight : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              if (_step == 0) _buildPhoneStep(auth),
              if (_step == 1) _buildOtpStep(),
              if (_step == 2) _buildDetailsStep(),
              if (_step == 3) _buildPinStep(auth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(AuthProvider auth) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phone Number', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text("We'll send you a verification code", style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 18, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: '0712 345 678',
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Text('+254', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _sendOtp,
              child: auth.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send OTP'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verification Code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Enter the 6-digit code sent to ${_phoneController.text}', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 16, color: AppColors.textPrimary),
            decoration: const InputDecoration(counterText: '', hintText: '------', hintStyle: TextStyle(letterSpacing: 16)),
            onChanged: (v) {
              if (v.length == 6) _verifyOtp();
            },
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _verifyOtp, child: const Text('Verify')),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Tell us about you and your business', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            TextField(
              controller: _firstNameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'First Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Last Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _businessNameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Business Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _proceedToPin, child: const Text('Continue')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinStep(AuthProvider auth) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set Your PIN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Create a 4-digit PIN to secure your account', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 40),
          Center(
            child: TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 24, color: AppColors.textPrimary),
              decoration: const InputDecoration(counterText: '', hintText: '----', hintStyle: TextStyle(letterSpacing: 24)),
              onChanged: (v) {
                if (v.length == 4) _register();
              },
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _register,
              child: auth.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Account'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }
}
