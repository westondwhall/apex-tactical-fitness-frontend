import 'package:flutter/material.dart';

import '../services/api_service.dart';

class WorkoutScreen extends StatefulWidget {
  final ApiService apiService;

  const WorkoutScreen({super.key, required this.apiService});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _agencyController = TextEditingController(
    text: 'FORCE',
  );
  final TextEditingController _timelineController = TextEditingController(
    text: '4',
  );
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedProgram;

  final List<Map<String, String>> _exercises = [
    {
      'name': 'Barbell Squat',
      'sets': '4 sets x 5 reps',
      'target': 'Strength / 80% 1RM',
    },
    {'name': 'Bench Press', 'sets': '4 sets x 6 reps', 'target': 'Hypertrophy'},
    {
      'name': 'Trap Bar Deadlift',
      'sets': '3 sets x 5 reps',
      'target': 'Posterior Chain',
    },
    {
      'name': '1 Mile Run',
      'sets': '1 set x Distance',
      'target': 'Aerobic Capacity',
    },
  ];

  final Map<int, bool> _expandedCards = {};
  // Each exercise keeps its own entry fields while cards are expanded.
  final Map<int, Map<String, TextEditingController>> _controllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2) {
        setState(() {}); // Forces FutureBuilder to re-fetch history when History tab is selected
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _agencyController.dispose();
    _timelineController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var controllers in _controllers.values) {
      controllers['weight']?.dispose();
      controllers['time']?.dispose();
      controllers['reps']?.dispose();
      controllers['rpe']?.dispose();
      controllers['date']?.dispose();
    }
    _controllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2228),
      appBar: AppBar(
        title: const Text(
          'TACTICAL WORKOUT SUITE',
          style: TextStyle(
            color: Color(0xFFE5A93B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF23272D),
        iconTheme: const IconThemeData(color: Color(0xFFE5A93B)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE5A93B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE5A93B),
          tabs: const [
            Tab(text: 'GENERATOR', icon: Icon(Icons.flash_on)),
            Tab(text: 'ACTIVE SESSION', icon: Icon(Icons.fitness_center)),
            Tab(text: 'HISTORY', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneratorTab(),
          _buildActiveSessionTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildGeneratorTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'CONFIGURE PROTOCOL',
            style: TextStyle(
              color: Color(0xFFE5A93B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _agencyController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText:
                  'Target Agency / Standard (e.g. FORCE, CPAT, or any goal)',
              labelStyle: TextStyle(color: Color(0xFFE5A93B)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5A93B)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timelineController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Timeline (Weeks)'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isGenerating ? null : _generateProgram,
            child: Text(_isGenerating ? 'GENERATING PLAN...' : 'GENERATE PLAN'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF23272D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE5A93B).withValues(alpha: 0.3),
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _generatedProgram != null
                      ? (_generatedProgram!['workout_plan'] ??
                            _generatedProgram.toString())
                      : 'Awaiting parameter input to generate schedule...',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          if (_generatedProgram != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  final planText =
                      _generatedProgram!['workout_plan'] ??
                      _generatedProgram.toString();
                  await widget.apiService.saveWorkoutPlan(
                    _agencyController.text,
                    int.tryParse(_timelineController.text) ?? 4,
                    planText,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tactical program saved to database successfully!',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save plan: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text(
                'SAVE GENERATED PLAN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveSessionTab() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2228),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE5A93B),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _showAddExerciseDialog(context),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _exercises.length,
        itemBuilder: (context, index) {
          final exercise = _exercises[index];
          final isExpanded = _expandedCards[index] ?? false;

          _controllers.putIfAbsent(index, () {
            return {
              'weight': TextEditingController(),
              'time': TextEditingController(),
              'reps': TextEditingController(),
              'rpe': TextEditingController(),
              'date': TextEditingController(
                text: DateTime.now().toIso8601String().split('T')[0],
              ),
            };
          });

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF23272D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5A93B).withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    exercise['name']!,
                    style: const TextStyle(
                      color: Color(0xFFE5A93B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Protocol: ${exercise['sets']} | Target: ${exercise['target']}",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () =>
                            _showEditExerciseDialog(context, index),
                      ),
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: const Color(0xFFE5A93B),
                        ),
                        onPressed: () =>
                            setState(() => _expandedCards[index] = !isExpanded),
                      ),
                    ],
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controllers[index]!['date'],
                          decoration: const InputDecoration(
                            labelText: 'Date Completed (YYYY-MM-DD)',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controllers[index]!['weight'],
                                decoration: const InputDecoration(
                                  labelText: 'Weight (lbs)',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _controllers[index]!['time'],
                                decoration: const InputDecoration(
                                  labelText: 'Time (e.g. 5:30)',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controllers[index]!['reps'],
                                decoration: const InputDecoration(
                                  labelText: 'Reps Completed',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _controllers[index]!['rpe'],
                                decoration: const InputDecoration(
                                  labelText: 'Perceived Exertion (RPE 1-10)',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitBlock(exercise['name']!, index),
                          child: const Text('LOG EXERCISE BLOCK'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<dynamic>>(
      future: widget.apiService.getWorkoutHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE5A93B)),
          );
        }

        if (snapshot.hasError) {
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No saved tactical programs found.',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93B),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => setState(() {}),
                  child: const Text('REFRESH HISTORY'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFFE5A93B),
          backgroundColor: const Color(0xFF23272D),
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final agency = item['target_agency'] ?? 'Unknown Agency';
              final weeks = item['timeline_weeks'] ?? 4;
              final planText = item['plan_text'] ?? '';
              final createdAt = item['created_at'] ?? '';

              return InkWell(
                onTap: () => _showPlanDetailDialog(context, item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23272D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE5A93B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'AGENCY: ${agency.toString().toUpperCase()}',
                            style: const TextStyle(
                              color: Color(0xFFE5A93B),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFFE5A93B),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Timeline: $weeks weeks protocol | Saved: ${createdAt.toString().split('T')[0]}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const Divider(color: Colors.grey, height: 20),
                      Text(
                        planText,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showPlanDetailDialog(BuildContext context, Map item) {
    final agency = item['target_agency'] ?? 'Unknown Agency';
    final weeks = item['timeline_weeks'] ?? 4;
    final planText = item['plan_text'] ?? '';
    final createdAt = item['created_at'] ?? '';
    final planId =
        item['id']; // Assumes your history record has a unique 'id' field

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23272D),
        title: Text(
          'AGENCY: ${agency.toUpperCase()}',
          style: const TextStyle(color: Color(0xFFE5A93B)),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Timeline: $weeks Weeks | Saved: ${createdAt.toString().split('T')[0]}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Divider(color: Colors.grey, height: 20),
                Text(
                  planText,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                // The API contract may expose this method dynamically at runtime.
                await (widget.apiService as dynamic).deleteWorkoutPlan(planId);
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {}); // Refresh state to update the history list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tactical program deleted successfully.'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete plan: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A93B),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    final nameController = TextEditingController();
    final setsController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23272D),
        title: const Text(
          'Add Exercise Card',
          style: TextStyle(color: Color(0xFFE5A93B)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name (e.g. Bench Press)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: setsController,
              decoration: const InputDecoration(
                labelText: 'Sets/Scheme (e.g. 4 sets x 8 reps)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: targetController,
              decoration: const InputDecoration(labelText: 'Target / Focus'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _exercises.add({
                    'name': nameController.text,
                    'sets': setsController.text.isNotEmpty
                        ? setsController.text
                        : '3 sets',
                    'target': targetController.text.isNotEmpty
                        ? targetController.text
                        : 'Standard',
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditExerciseDialog(BuildContext context, int index) {
    final nameController = TextEditingController(
      text: _exercises[index]['name'],
    );
    final setsController = TextEditingController(
      text: _exercises[index]['sets'],
    );
    final targetController = TextEditingController(
      text: _exercises[index]['target'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23272D),
        title: const Text(
          'Modify Exercise Card',
          style: TextStyle(color: Color(0xFFE5A93B)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Exercise Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: setsController,
              decoration: const InputDecoration(labelText: 'Sets/Scheme'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: targetController,
              decoration: const InputDecoration(labelText: 'Target / Focus'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _exercises.removeAt(index);
                _disposeControllers();
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _exercises[index] = {
                  'name': nameController.text,
                  'sets': setsController.text,
                  'target': targetController.text,
                };
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future _generateProgram() async {
    setState(() => _isGenerating = true);
    try {
      final response = await (widget.apiService as dynamic).generateProgram(
        _agencyController.text,
        int.tryParse(_timelineController.text) ?? 4,
      );
      setState(() => _generatedProgram = response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Generation failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future _submitBlock(String exerciseName, int index) async {
    final date = _controllers[index]!['date']!.text;
    final weight = _controllers[index]!['weight']!.text;
    final time = _controllers[index]!['time']!.text;
    final reps = _controllers[index]!['reps']!.text;
    final rpe = _controllers[index]!['rpe']!.text;

    if (date.isEmpty ||
        weight.isEmpty ||
        time.isEmpty ||
        reps.isEmpty ||
        rpe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill out all metric fields including weight, time, and date.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await (widget.apiService as dynamic).postWorkoutLog({
        'exercise': exerciseName,
        'weight': double.tryParse(weight) ?? 0.0,
        'time': time,
        'reps': int.tryParse(reps) ?? 0,
        'rpe': int.tryParse(rpe) ?? 0,
        'timestamp':
            DateTime.tryParse(date)?.toIso8601String() ??
            DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged $exerciseName successfully for $date!'),
          ),
        );
        _controllers[index]!['weight']!.clear();
        _controllers[index]!['time']!.clear();
        _controllers[index]!['reps']!.clear();
        _controllers[index]!['rpe']!.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
