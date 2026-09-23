import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final ApiService apiService;
  final Map workoutPlan;

  const ActiveWorkoutScreen({
    super.key,
    required this.apiService,
    required this.workoutPlan,
  });

  @override
  State createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final Color tacticalGold = const Color(0xFFE5A93B);
  final Color cardBg = const Color(0xFF23272D);
  bool _isFinished = false;

  void _finishWorkout() {
    setState(() {
      _isFinished = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout session logged successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final agency = widget.workoutPlan['target_agency'] ?? 'CUSTOM';
    final planText = widget.workoutPlan['plan_text'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('ACTIVE SESSION: $agency'),
        backgroundColor: Colors.black,
        foregroundColor: tacticalGold,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tacticalGold.withValues(alpha: 0.35)),
              ),
              child: Text(
                'Timeline: ${widget.workoutPlan['timeline_weeks']} Weeks Protocol',
                style: TextStyle(color: tacticalGold, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    planText,
                    style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isFinished ? null : _finishWorkout,
                icon: const Icon(Icons.check_circle, color: Colors.black),
                style: ElevatedButton.styleFrom(backgroundColor: tacticalGold),
                label: const Text('COMPLETE WORKOUT SESSION'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}