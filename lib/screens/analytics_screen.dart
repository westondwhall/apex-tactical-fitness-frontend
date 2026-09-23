import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, required this.apiService, this.authToken});

  final ApiService apiService;
  final String? authToken;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  double _completionRate = 0;
  int _totalWorkouts = 0;
  String _readinessStatus = 'Optimal Range';
  String _aiPerformanceBrief = 'Analyzing telemetry...';
  String? _authToken;

  List<Map<String, dynamic>> _personalRecords = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _agencyBenchmarks = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<Map<String, String>> _headers() async {
    _authToken ??= widget.authToken ?? await StorageService.getToken();
    return <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };
  }

  Future<void> _fetchAnalytics() async {
    try {
      final headers = await _headers();
      final responses = await Future.wait<HttpResponseData>([
        _get('/analytics', headers),
        _get('/personal-records', headers),
        _get('/agency-benchmarks', headers),
      ]);

      if (!mounted) return;
      final analytics = responses[0];
      final records = responses[1];
      final benchmarks = responses[2];

      if (analytics.statusCode == 200 && analytics.body is Map) {
        final data = Map<String, dynamic>.from(analytics.body as Map);
        _completionRate = _asDouble(data['completion_rate']);
        _totalWorkouts = _asInt(data['total_workouts']);
        _readinessStatus =
            data['readiness_status']?.toString() ??
            _derivedReadiness(_completionRate);
        _aiPerformanceBrief =
            "Operator, your training volume is currently classified as '$_readinessStatus'. "
            'Maintain consistent recovery protocols and adjust intensity based on your target agency benchmarks.';
      }

      if (records.statusCode == 200 && records.body is Map) {
        _personalRecords = _asMapList((records.body as Map)['records']);
      }

      if (benchmarks.statusCode == 200 && benchmarks.body is Map) {
        _agencyBenchmarks = _asMapList((benchmarks.body as Map)['benchmarks']);
      }
      if (_agencyBenchmarks.isEmpty) {
        _agencyBenchmarks = _defaultBenchmarks();
      }

      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _readinessStatus = _derivedReadiness(_completionRate);
        _aiPerformanceBrief =
            'Offline Mode: AI Performance brief temporarily unavailable.';
        _agencyBenchmarks = _defaultBenchmarks();
        _isLoading = false;
      });
    }
  }

  Future<HttpResponseData> _get(
    String path,
    Map<String, String> headers,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: headers,
    );
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {}
    return HttpResponseData(response.statusCode, body);
  }

  Future<void> _saveOrUpdateBenchmark(
    String? id,
    String category,
    String target,
    double progress,
  ) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/agency-benchmarks'),
        headers: await _headers(),
        body: jsonEncode({
          'id': id,
          'category': category,
          'target': target,
          'progress': progress,
        }),
      );
      await _fetchAnalytics();
    } catch (_) {
      _showError('Failed to save benchmark.');
    }
  }

  Future<void> _deleteBenchmark(String? id) async {
    if (id == null || id.isEmpty) return;
    try {
      await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/agency-benchmarks/$id'),
        headers: await _headers(),
      );
      await _fetchAnalytics();
    } catch (_) {
      _showError('Failed to delete benchmark.');
    }
  }

  Future<void> _addPersonalRecord(
    String exercise,
    String metric,
    String date,
  ) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/personal-records'),
        headers: await _headers(),
        body: jsonEncode({
          'exercise': exercise,
          'metric': metric,
          'date': date,
        }),
      );
      await _fetchAnalytics();
    } catch (_) {
      _showError('Failed to add personal record.');
    }
  }

  Future<void> _deletePersonalRecord(String id) async {
    try {
      await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/personal-records/$id'),
        headers: await _headers(),
      );
      await _fetchAnalytics();
    } catch (_) {
      _showError('Failed to delete personal record.');
    }
  }

  void _showEditBenchmarkDialog([Map<String, dynamic>? benchmark]) {
    final bool isEditing = benchmark != null;
    final categoryController = TextEditingController(
      text: benchmark?['category']?.toString() ?? '',
    );
    final targetController = TextEditingController(
      text: benchmark?['target']?.toString() ?? '',
    );
    final progressController = TextEditingController(
      text: isEditing
          ? (_asDouble(benchmark['progress']) * 100).round().toString()
          : '50',
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF23272D),
        title: Text(
          isEditing ? 'Edit Benchmark Standard' : 'Add Benchmark Standard',
          style: const TextStyle(color: Color(0xFFE5A93B)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _dialogField(categoryController, 'Category Title'),
            TextField(
              controller: targetController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Target'),
            ),
            TextField(
              controller: progressController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Progress % (0-100)',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          if (benchmark != null && benchmark['id'] != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteBenchmark(benchmark['id']?.toString());
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: _goldButtonStyle,
            onPressed: () {
              final progress = ((_asDouble(progressController.text)) / 100)
                  .clamp(0.0, 1.0);
              if (categoryController.text.trim().isEmpty ||
                  targetController.text.trim().isEmpty) {
                return;
              }
              Navigator.of(dialogContext).pop();
              _saveOrUpdateBenchmark(
                benchmark?['id']?.toString(),
                categoryController.text.trim(),
                targetController.text.trim(),
                progress,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(() {
      categoryController.dispose();
      targetController.dispose();
      progressController.dispose();
    });
  }

  void _showAddPRDialog() {
    final exerciseController = TextEditingController();
    final metricController = TextEditingController();
    final dateController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF23272D),
        title: const Text(
          'Add Personal Record',
          style: TextStyle(color: Color(0xFFE5A93B)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _dialogField(exerciseController, 'Exercise / Movement'),
            _dialogField(metricController, 'Metric (e.g. 425 lbs)'),
            _dialogField(dateController, 'Date (YYYY-MM-DD)'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: _goldButtonStyle,
            onPressed: () {
              if (exerciseController.text.trim().isEmpty ||
                  metricController.text.trim().isEmpty) {
                return;
              }
              Navigator.of(dialogContext).pop();
              _addPersonalRecord(
                exerciseController.text.trim(),
                metricController.text.trim(),
                dateController.text.trim(),
              );
            },
            child: const Text('Add PR'),
          ),
        ],
      ),
    ).whenComplete(() {
      exerciseController.dispose();
      metricController.dispose();
      dateController.dispose();
    });
  }

  Widget _dialogField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label),
    );
  }

  String _derivedReadiness(double completionRate) {
    if (completionRate >= 80) return 'Optimal Range';
    if (completionRate < 40) return 'Undertraining Risk';
    return 'Overtraining Risk';
  }

  Color _readinessColor() {
    if (_readinessStatus == 'Optimal Range') return Colors.greenAccent;
    if (_readinessStatus == 'Overtraining Risk') return Colors.redAccent;
    return Colors.orangeAccent;
  }

  List<Map<String, dynamic>> _defaultBenchmarks() {
    return <Map<String, dynamic>>[
      {
        'id': null,
        'category': 'Cardio Endurance',
        'target': '< 10:30 min',
        'progress': 0.85,
      },
      {
        'id': null,
        'category': 'Upper Body Strength',
        'target': '250 lbs / 20 Reps',
        'progress': 0.90,
      },
      {
        'id': null,
        'category': 'Work Capacity Circuit',
        'target': 'Sub 3-min',
        'progress': 0.75,
      },
    ];
  }

  List<Map<String, dynamic>> _asMapList(Object? value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList();
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272D),
        title: const Text(
          'OPERATOR ANALYTICS',
          style: TextStyle(color: Color(0xFFE5A93B)),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5A93B)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _buildCard(
                  title: 'AI Coach Performance Brief',
                  icon: Icons.psychology,
                  child: Text(
                    _aiPerformanceBrief,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Training Readiness & Volume Range',
                  icon: Icons.speed,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              'Status Indicator:',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          Chip(
                            backgroundColor: _readinessColor().withValues(
                              alpha: 0.2,
                            ),
                            label: Text(
                              _readinessStatus,
                              style: TextStyle(
                                color: _readinessColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          _buildMetricColumn(
                            'Total Workouts',
                            '$_totalWorkouts',
                          ),
                          _buildMetricColumn(
                            'Completion Rate',
                            '${_completionRate.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Agency Benchmark Standards (Tap to Edit)',
                  icon: Icons.track_changes,
                  child: Column(
                    children: <Widget>[
                      ..._agencyBenchmarks.map((
                        Map<String, dynamic> benchmark,
                      ) {
                        final progress = _asDouble(benchmark['progress'])
                            .clamp(0.0, 1.0);
                        return InkWell(
                          onTap: () => _showEditBenchmarkDialog(benchmark),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        benchmark['category']?.toString() ??
                                            'Benchmark',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      benchmark['target']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFFE5A93B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: const Color(0xFF1A1D23),
                                  color: const Color(0xFFE5A93B),
                                  minHeight: 8,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: _goldButtonStyle,
                        onPressed: () => _showEditBenchmarkDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Benchmark Standard'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Personal Records & Milestones',
                  icon: Icons.military_tech,
                  child: Column(
                    children: <Widget>[
                      ..._personalRecords.map((Map<String, dynamic> record) {
                        final id = record['id']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  record['exercise']?.toString() ?? 'Exercise',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              Text(
                                record['metric']?.toString() ?? '',
                                style: const TextStyle(
                                  color: Color(0xFFE5A93B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (id.isNotEmpty)
                                IconButton(
                                  tooltip: 'Delete personal record',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  onPressed: () => _deletePersonalRecord(id),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: _goldButtonStyle,
                        onPressed: _showAddPRDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add New PR'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF23272D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: const Color(0xFFE5A93B), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFE5A93B),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE5A93B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  static final ButtonStyle _goldButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFE5A93B),
    foregroundColor: Colors.black,
  );
}

class HttpResponseData {
  const HttpResponseData(this.statusCode, this.body);

  final int statusCode;
  final dynamic body;
}
