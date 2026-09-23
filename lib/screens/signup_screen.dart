import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _targetAgencyController = TextEditingController();
  final TextEditingController _sportsController = TextEditingController();
  final TextEditingController _goalsController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();

  bool _acceptedTerms = false;
  bool _acceptedBilling = false;
  bool _acceptedPrivacy = false;
  bool _isLoading = false;

  Future<void> _fetchAndShowPolicy(
    BuildContext context,
    String endpoint,
    String title,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/$endpoint'),
      );
      String content = 'Policy could not be loaded.';

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        content =
            data[endpoint.replaceAll('-', '_')]?.toString() ??
            (data.isNotEmpty ? data.values.first.toString() : content);
      }

      if (!context.mounted) return;

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF23272D),
          title: Text(title, style: const TextStyle(color: Color(0xFFE5A93B))),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFFE5A93B)),
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load policy document.')),
      );
    }
  }

  Future<void> _registerUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptedTerms || !_acceptedBilling || !_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept all mandatory policies to register.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'full_name': _fullNameController.text.trim(),
          'target_agency': _targetAgencyController.text.trim(),
          'fitness_goals': _goalsController.text.trim(),
          'sports': _sportsController.text.trim(),
          'medical_limitations': _medicalController.text.trim(),
          'terms_accepted': _acceptedTerms,
          'billing_accepted': _acceptedBilling,
          'privacy_accepted': _acceptedPrivacy,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['detail'] ?? 'Registration failed');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please log in.'),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _targetAgencyController.dispose();
    _sportsController.dispose();
    _goalsController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272D),
        title: const Text(
          'APEX OPERATOR REGISTRATION',
          style: TextStyle(color: Color(0xFFE5A93B)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE5A93B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                _emailController,
                'Email Address',
                'Enter your email',
              ),
              _buildTextField(
                _passwordController,
                'Password',
                'Enter secure password',
                obscureText: true,
              ),
              _buildTextField(
                _fullNameController,
                'Full Name',
                'e.g., John Doe',
              ),
              _buildTextField(
                _targetAgencyController,
                'Target Agency / Standard',
                'e.g., FORCE, CPAT, Army ACFT',
              ),
              _buildTextField(
                _sportsController,
                'Sport(s) / Athletic Background',
                'e.g., Rugby, BJJ, Hyrox',
              ),
              _buildTextField(
                _goalsController,
                'Fitness Goals',
                'e.g., Maximize cardio & grip strength',
              ),
              _buildTextField(
                _medicalController,
                'Medical Limitations / Injuries',
                'e.g., Previous right knee surgery (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildPolicyCheckbox(
                value: _acceptedTerms,
                label: 'I accept the Terms of Service & Liability Waiver',
                onChanged: (value) =>
                    setState(() => _acceptedTerms = value ?? false),
                onTap: () => _fetchAndShowPolicy(
                  context,
                  'terms',
                  'Terms of Service & Liability Waiver',
                ),
              ),
              _buildPolicyCheckbox(
                value: _acceptedBilling,
                label: 'I accept the Billing & Cancellation Policy',
                onChanged: (value) =>
                    setState(() => _acceptedBilling = value ?? false),
                onTap: () => _fetchAndShowPolicy(
                  context,
                  'billing-policy',
                  'Billing, Subscription & Cancellation Policy',
                ),
              ),
              _buildPolicyCheckbox(
                value: _acceptedPrivacy,
                label: 'I accept the Privacy Policy',
                onChanged: (value) =>
                    setState(() => _acceptedPrivacy = value ?? false),
                onTap: () => _fetchAndShowPolicy(
                  context,
                  'privacy-policy',
                  'Privacy Policy',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _registerUser,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'COMPLETE REGISTRATION',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyCheckbox({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          activeColor: const Color(0xFFE5A93B),
          onChanged: onChanged,
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE5A93B),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        keyboardType: label == 'Email Address'
            ? TextInputType.emailAddress
            : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFE5A93B)),
          floatingLabelStyle: const TextStyle(color: Color(0xFFE5A93B)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          filled: true,
          fillColor: const Color(0xFF23272D),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required field' : null,
      ),
    );
  }
}
