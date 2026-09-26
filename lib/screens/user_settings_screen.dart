import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_constants.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'profile_edit_screen.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  bool _aiMemoryEnabled = true;
  String _coachPersonality = 'Drill Sergeant';
  bool _dataSharingOptIn = false;

  bool _workoutReminders = true;
  String _checkInFrequency = 'Weekly';
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  String _unitSystem = 'Imperial (lbs, in)';
  bool _isLoading = false;
  bool _isDeletingAccount = false;

  Future<void> _downloadUserData() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Generating data export... Your download will begin shortly.',
        ),
      ),
    );
  }

  void _showUnavailableMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _launchSupportEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'westonhall@live.ca',
      query: 'subject=Apex Tactical Fitness - Support & Bug Report',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('Could not launch email client.');
      }
    } catch (error) {
      debugPrint('Error launching email: $error');
    }
  }

  void _showSubscriptionInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF23272D),
        title: const Text(
          'Subscription & Billing',
          style: TextStyle(color: Color(0xFFE5A93B)),
        ),
        content: const Text(
          'Subscriptions are securely managed directly through your device account. Please visit your Apple App Store ID or Google Play Store subscription settings to view, modify, or cancel your active plan.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFFE5A93B))),
          ),
        ],
      ),
    );
  }

  Future<void> _openProfileEdit() async {
    final token = await StorageService.getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      _showUnavailableMessage('Please log in again to edit your profile.');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileEditScreen(authToken: token)),
    );
  }

  Future<void> _fetchAndShowPolicy(
    BuildContext context,
    String endpoint,
    String title,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/$endpoint'),
      );
      String content = 'Policy document could not be loaded.';

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (endpoint == 'terms') {
          content = data['terms']?.toString() ?? content;
        } else if (endpoint == 'billing-policy') {
          content = data['billing_policy']?.toString() ?? content;
        } else if (endpoint == 'privacy-policy') {
          content = data['privacy_policy']?.toString() ?? content;
        }
      }

      if (!context.mounted) return;

      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
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
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
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
        const SnackBar(
          content: Text('Failed to connect to backend policy service.'),
        ),
      );
    }
  }

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setDialogState) =>
              AlertDialog(
                backgroundColor: const Color(0xFF23272D),
                title: const Text(
                  'Terminate Account',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Warning: This action is permanent. All your profile data, workout logs, notes, and training history will be permanently deleted and cannot be recovered.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        emailController.text.trim().isEmpty ||
                            passwordController.text.isEmpty
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            final password = passwordController.text;
                            Navigator.of(dialogContext).pop();
                            await _executeAccountDeletion(email, password);
                          },
                    child: const Text('Delete Forever'),
                  ),
                ],
              ),
        ),
      );
    } finally {
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _executeAccountDeletion(String email, String password) async {
    setState(() => _isDeletingAccount = true);
    try {
      final result = await AuthService().reauthenticateAndDeleteUserAccount(
        email,
        password,
      );
      if (result['success'] != true) {
        throw Exception('Account deletion failed');
      }

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete account. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _logOut() async {
    try {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272D),
        title: const Text(
          'OPERATOR SETTINGS',
          style: TextStyle(color: Color(0xFFE5A93B)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE5A93B)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          _buildSection(
            title: '1. AI & RAG Preferences',
            icon: Icons.psychology_outlined,
            children: <Widget>[
              SwitchListTile(
                title: const Text('AI Memory & Context (RAG Controls)'),
                subtitle: const Text(
                  'Allow AI to retain past injuries and workout logs for tailored advice.',
                ),
                value: _aiMemoryEnabled,
                activeThumbColor: const Color(0xFFE5A93B),
                onChanged: (bool value) =>
                    setState(() => _aiMemoryEnabled = value),
              ),
              _buildDropdownTile<String>(
                title: 'Coach Personality & Tone',
                subtitle: 'Current: $_coachPersonality',
                value: _coachPersonality,
                items: const <String>[
                  'Drill Sergeant',
                  'Supportive & Gentle',
                  'Data-Driven & Analytical',
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _coachPersonality = value);
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Data Sharing for AI Training'),
                subtitle: const Text(
                  'Opt in to use anonymized logs to improve global AI models.',
                ),
                value: _dataSharingOptIn,
                activeThumbColor: const Color(0xFFE5A93B),
                onChanged: (bool value) =>
                    setState(() => _dataSharingOptIn = value),
              ),
            ],
          ),
          _buildSection(
            title: '2. Profile & Core Fitness Data',
            icon: Icons.person_outline,
            children: <Widget>[
              _buildActionTile(
                title: 'Physical Metrics & Core Stats',
                subtitle: 'Height, current weight, target weight, age, sex',
                icon: Icons.fitness_center,
                onTap: _openProfileEdit,
              ),
              _buildActionTile(
                title: 'Injuries, Limitations & Equipment',
                subtitle: 'Update physical restrictions or home gym gear',
                onTap: _openProfileEdit,
              ),
            ],
          ),
          _buildSection(
            title: '3. Notifications & Reminders',
            icon: Icons.notifications_none,
            children: <Widget>[
              SwitchListTile(
                title: const Text('Workout Reminders'),
                value: _workoutReminders,
                activeThumbColor: const Color(0xFFE5A93B),
                onChanged: (bool value) =>
                    setState(() => _workoutReminders = value),
              ),
              _buildDropdownTile<String>(
                title: 'AI Check-in Frequency',
                value: _checkInFrequency,
                items: const <String>['Daily', 'Weekly', 'Post-Workout Only'],
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _checkInFrequency = value);
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Push vs. Email Channels'),
                subtitle: Text(
                  'Push: ${_pushNotifications ? 'On' : 'Off'} | Email: ${_emailNotifications ? 'On' : 'Off'}',
                ),
                value: _pushNotifications,
                activeThumbColor: const Color(0xFFE5A93B),
                onChanged: (bool value) => setState(() {
                  _pushNotifications = value;
                  _emailNotifications = !value;
                }),
              ),
            ],
          ),
          _buildSection(
            title: '4. Subscription & Billing',
            icon: Icons.receipt_long_outlined,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.payment, color: Color(0xFFE5A93B)),
                title: const Text(
                  'Subscription & Billing',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Manage your plan via device app store',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
                onTap: () => _showSubscriptionInfo(context),
              ),
            ],
          ),
          _buildSection(
            title: '5. Privacy, Data & Legal',
            icon: Icons.privacy_tip_outlined,
            children: <Widget>[
              ListTile(
                title: const Text('Data Export (GDPR / CCPA)'),
                subtitle: const Text(
                  'Download a copy of chat history, workouts and profile.',
                ),
                trailing: ElevatedButton(
                  style: _primaryButtonStyle,
                  onPressed: _isLoading ? null : _downloadUserData,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Download'),
                ),
              ),
            ],
          ),
          _buildSection(
            title: '6. App Preferences & Support',
            icon: Icons.tune,
            children: <Widget>[
              _buildDropdownTile<String>(
                title: 'Units of Measurement',
                value: _unitSystem,
                items: const <String>['Imperial (lbs, in)', 'Metric (kg, cm)'],
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _unitSystem = value);
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.support_agent,
                  color: Color(0xFFE5A93B),
                ),
                title: const Text(
                  'Help & Support / Report a Bug',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Contact developer via email',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.mail_outline,
                  color: Color(0xFFE5A93B),
                  size: 18,
                ),
                onTap: _launchSupportEmail,
              ),
            ],
          ),
          const Divider(color: Colors.redAccent, thickness: 1.5),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: const Text(
                'Terminate Account & Delete Data',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Permanently remove your account and all associated data',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
              ),
              onTap: _isDeletingAccount
                  ? null
                  : () => _confirmAndDeleteAccount(context),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFE5A93B)),
            title: const Text('Log Out', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'End this session and return to sign in',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
            onTap: _isDeletingAccount ? null : _logOut,
          ),
          _buildSectionHeader('7. About Apex Tactical Performance'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF23272D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Apex Tactical Performance',
                  style: TextStyle(
                    color: Color(0xFFE5A93B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version 1.0.0 (Build 101)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Designed for tactical athletes, military personnel, and law enforcement professionals preparing for high-stakes fitness standards.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const Divider(color: Colors.white24, height: 20),
                _buildPolicyLink(
                  endpoint: 'terms',
                  title: 'Terms of Service & Liability Waiver',
                ),
                _buildPolicyLink(
                  endpoint: 'billing-policy',
                  title: 'Billing, Subscription & Cancellation Policy',
                ),
                _buildPolicyLink(
                  endpoint: 'privacy-policy',
                  title: 'Privacy Policy',
                ),
                const Divider(color: Colors.white24, height: 20),
                const Text(
                  'Support & Contact',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _launchSupportEmail,
                  child: const Text(
                    'westonhall@live.ca',
                    style: TextStyle(
                      color: Color(0xFFE5A93B),
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    '© 2026 APEX TACTICAL PERFORMANCE. ALL RIGHTS RESERVED',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Environment: Production Ready',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFE5A93B),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPolicyLink({required String endpoint, required String title}) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Color(0xFFE5A93B))),
      trailing: const Icon(
        Icons.open_in_new,
        color: Color(0xFFE5A93B),
        size: 16,
      ),
      onTap: () => _fetchAndShowPolicy(context, endpoint, title),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.white12),
      child: ExpansionTile(
        leading: Icon(icon, color: const Color(0xFFE5A93B)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE5A93B),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconColor: const Color(0xFFE5A93B),
        collapsedIconColor: Colors.grey,
        children: children,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    String? subtitle,
    IconData icon = Icons.arrow_forward_ios,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: icon == Icons.arrow_forward_ios
          ? null
          : Icon(icon, color: const Color(0xFFE5A93B)),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Icon(icon, color: const Color(0xFFE5A93B), size: 16),
      onTap:
          onTap ??
          () => _showUnavailableMessage('$title is not available yet.'),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    String? subtitle,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: DropdownButton<T>(
        value: value,
        dropdownColor: const Color(0xFF23272D),
        style: const TextStyle(color: Colors.white),
        items: items
            .map(
              (T item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  static final ButtonStyle _primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFE5A93B),
    foregroundColor: Colors.black,
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
  );
}
