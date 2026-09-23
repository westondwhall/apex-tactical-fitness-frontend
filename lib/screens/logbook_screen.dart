import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LogbookScreen extends StatefulWidget {
  final ApiService apiService;

  const LogbookScreen({super.key, required this.apiService});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  late Future<List<Map<String, dynamic>>> _logsFuture;
  List<Map<String, dynamic>>? _logs;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _logsFuture = widget.apiService.getWorkoutLogbook().then((logs) {
      _logs = logs;
      return logs;
    });
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _logsFuture;
  }

  Future<void> _deleteLog(String id) async {
    try {
      await widget.apiService.deleteWorkoutLog(id);
      if (!mounted) return;
      setState(() {
        _logs?.removeWhere((item) => item['id'].toString() == id);
        _logsFuture = Future.value(List<Map<String, dynamic>>.from(_logs ?? []));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout log deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete log: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2228),
      appBar: AppBar(
        title: const Text(
          'TRAINING LOGBOOK',
          style: TextStyle(color: Color(0xFFE5A93B), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF23272D),
        iconTheme: const IconThemeData(color: Color(0xFFE5A93B)),
        actions: [
          IconButton(
            tooltip: 'Refresh logbook',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93B)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load training logbook.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return RefreshIndicator(
              color: const Color(0xFFE5A93B),
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 220),
                  Icon(Icons.menu_book_outlined, color: Colors.white38, size: 56),
                  SizedBox(height: 16),
                  Center(
                    child: Text('No exercise blocks logged yet.', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFE5A93B),
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildLogEntry(logs[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    final timestamp = log['timestamp'] ?? log['created_at'] ?? '';
    final date = timestamp.toString().split('T').first;
    final weight = log['weight'] ?? 0;
    final time = log['time'] ?? '-';
    final reps = log['reps'] ?? 0;
    final rpe = log['rpe'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF23272D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5A93B).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Color(0xFFE5A93B), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (log['exercise'] ?? 'Exercise').toString(),
                  style: const TextStyle(color: Color(0xFFE5A93B), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text(date, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              if (log['id'] != null)
                IconButton(
                  tooltip: 'Delete log',
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  onPressed: () => _deleteLog(log['id'].toString()),
                ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric('LOAD', '$weight'),
              _metric('TIME', '$time'),
              _metric('REPS', '$reps'),
              _metric('RPE', '$rpe / 10'),
              _metric('STATUS', (log['status'] ?? 'completed').toString().toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}