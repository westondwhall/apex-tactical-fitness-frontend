import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _agencyController = TextEditingController();
  final TextEditingController _goalsController = TextEditingController();
  final TextEditingController _metricsController = TextEditingController();
  final TextEditingController _coreStatsController = TextEditingController();
  final TextEditingController _injuriesController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _agencyController.dispose();
    _goalsController.dispose();
    _metricsController.dispose();
    _coreStatsController.dispose();
    _injuriesController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  Map<String, String> get _headers => <String, String>{
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.authToken}',
  };

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/profile'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _nameController.text = _value(data, 'full_name');
          _agencyController.text = _value(data, 'target_agency');
          _goalsController.text = _value(data, 'fitness_goals');
          _metricsController.text = _value(data, 'physical_metrics');
          _coreStatsController.text = _value(data, 'core_stats');
          _injuriesController.text = _value(
            data,
            'injuries_limitations',
            fallbackKey: 'medical_limitations',
          );
          _equipmentController.text = _value(data, 'equipment');
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Keep the form available for first-time profile setup.
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String _value(Map<String, dynamic> data, String key, {String? fallbackKey}) {
    return data[key]?.toString() ??
        (fallbackKey == null ? null : data[fallbackKey]?.toString()) ??
        '';
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/profile'),
        headers: _headers,
        body: jsonEncode({
          'full_name': _nameController.text.trim(),
          'target_agency': _agencyController.text.trim(),
          'fitness_goals': _goalsController.text.trim(),
          'physical_metrics': _metricsController.text.trim(),
          'core_stats': _coreStatsController.text.trim(),
          'injuries_limitations': _injuriesController.text.trim(),
          'equipment': _equipmentController.text.trim(),
          'terms_accepted': true,
          'billing_accepted': true,
          'privacy_accepted': true,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Profile update failed');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile & Core Metrics updated successfully!'),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile data.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272D),
        title: const Text(
          'Edit Profile & Tactical Metrics',
          style: TextStyle(color: Color(0xFFE5A93B)),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5A93B)),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    _buildTextField(
                      _nameController,
                      'Full Name',
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _agencyController,
                      'Target Agency / Standard',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(_goalsController, 'Fitness Goals'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _metricsController,
                      'Physical Metrics (Height, Weight, Body Comp)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _coreStatsController,
                      'Core Stats (VO2 Max, Benchmarks, Ruck Pace)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _injuriesController,
                      'Injuries & Limitations',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _equipmentController,
                      'Available Equipment (Gym, Ruck, Plate Carrier)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A93B),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Save & Sync with Apex Coach',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFE5A93B)),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE5A93B)),
        ),
      ),
      validator: required
          ? (String? value) =>
                value == null || value.trim().isEmpty ? 'Required field' : null
          : null,
    );
  }
}
