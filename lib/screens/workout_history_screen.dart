import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'active_workout_screen.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  final ApiService apiService;

  const WorkoutHistoryScreen({super.key, required this.apiService});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late Future<List<dynamic>> _historyFuture;
  final Color tacticalGold = const Color(0xFFE5A93B);
  final Color cardBg = const Color(0xFF23272D);

  @override
  void initState() {
    super.initState();
    // Keep this call dynamic so the screen remains compatible with the
    // service implementation's history method without requiring a duplicate
    // API declaration in this file.
    _historyFuture = (widget.apiService as dynamic).getWorkoutHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SAVED TACTICAL PROGRAMS'),
        backgroundColor: Colors.black,
        foregroundColor: tacticalGold,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: tacticalGold));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading history: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            );
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const Center(
              child: Text(
                'No saved workout plans found in database.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final plan = history[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActiveWorkoutScreen(
                        apiService: widget.apiService,
                        workoutPlan: plan,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tacticalGold.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'AGENCY: ${plan['target_agency']?.toUpperCase() ?? 'UNKNOWN'}',
                            style: TextStyle(color: tacticalGold, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Timeline: ${plan['timeline_weeks']} Weeks',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const Divider(color: Colors.white24, height: 20),
                      Text(
                        plan['plan_text'] ?? '',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}