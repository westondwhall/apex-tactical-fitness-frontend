import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'user_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ApiService apiService;
  const ProfileScreen({super.key, required this.apiService});

  @override
  State createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _agencyController = TextEditingController();
  final TextEditingController _sportsController = TextEditingController();
  final _goalsController = TextEditingController();
  final _limitationsController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.apiService.getProfile();
      if (!mounted) return;
      setState(() {
        _nameController.text = profile['full_name']?.toString() ?? '';
        _agencyController.text = profile['target_agency']?.toString() ?? '';
        _sportsController.text = profile['sports']?.toString() ?? '';
        _goalsController.text = profile['fitness_goals']?.toString() ?? '';
        _limitationsController.text =
            profile['medical_limitations']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await widget.apiService.postProfile({
        'full_name': _nameController.text,
        'target_agency': _agencyController.text,
        'sports': _sportsController.text,
        'fitness_goals': _goalsController.text,
        'medical_limitations': _limitationsController.text,
        'terms_accepted': true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile configuration updated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _profileInputDecoration({
    required String labelText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFFE5A93B)),
      floatingLabelStyle: const TextStyle(color: Color(0xFFE5A93B)),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF23272D),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _agencyController.dispose();
    _sportsController.dispose();
    _goalsController.dispose();
    _limitationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2228),
      appBar: AppBar(
        title: const Text(
          'OPERATOR PROFILE',
          style: TextStyle(color: Color(0xFFE5A93B)),
        ),
        backgroundColor: const Color(0xFF23272D),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings, color: Color(0xFFE5A93B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5A93B)),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: _profileInputDecoration(
                        labelText: 'Full Name',
                      ),
                      validator: (v) => v!.isEmpty ? 'Field required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _agencyController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: _profileInputDecoration(
                        labelText: 'Target Agency (e.g. FORCE, CPAT)',
                      ),
                      validator: (v) => v!.isEmpty ? 'Field required' : null,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        controller: _sportsController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                        decoration: _profileInputDecoration(
                          labelText: 'Sport(s) / Athletic Background',
                          hintText: 'e.g., Rugby, BJJ, Obstacle Course Racing',
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _goalsController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: _profileInputDecoration(
                        labelText: 'Fitness Goals',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _limitationsController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: _profileInputDecoration(
                        labelText: 'Medical Limitations / Injuries',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A93B),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: Text(
                        _isSaving ? 'SAVING...' : 'UPDATE PROFILE',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
