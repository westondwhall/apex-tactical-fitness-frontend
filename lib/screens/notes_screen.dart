import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../services/storage_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, this.authToken});

  final String? authToken;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Map<String, dynamic>> _notes = <Map<String, dynamic>>[];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    _authToken ??= widget.authToken ?? await StorageService.getToken();
    return <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };
  }

  Future<void> _fetchNotes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notes'),
        headers: await _headers(),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawNotes = decoded is Map ? decoded['notes'] : decoded;
        setState(() {
          _notes
            ..clear()
            ..addAll(
              rawNotes is List
                  ? rawNotes.whereType<Map>().map(
                      (Map note) => Map<String, dynamic>.from(note),
                    )
                  : <Map<String, dynamic>>[],
            );
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Keep the empty state usable when the API is temporarily unavailable.
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notes'),
        headers: await _headers(),
        body: jsonEncode({
          'title': title.isEmpty ? 'Untitled Note' : title,
          'content': content,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _titleController.clear();
        _contentController.clear();
        if (!mounted) return;
        Navigator.of(context).pop();
        await _fetchNotes();
      } else {
        throw Exception('Failed to save note');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save note.')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/notes/$noteId'),
        headers: await _headers(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchNotes();
      } else {
        throw Exception('Failed to delete note');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete note.')));
      }
    }
  }

  void _showAddNoteDialog() {
    _titleController.clear();
    _contentController.clear();
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF23272D),
        title: const Text(
          'New Tactical Note',
          style: TextStyle(color: Color(0xFFE5A93B)),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Note Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Write or paste notes here...'),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A93B),
              foregroundColor: Colors.black,
            ),
            onPressed: _isSaving ? null : _saveNote,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : const Text(
                    'Save Note',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFE5A93B)),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white70),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE5A93B)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272D),
        title: const Text(
          'OPERATOR NOTEPAD',
          style: TextStyle(color: Color(0xFFE5A93B)),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5A93B)),
            )
          : _notes.isEmpty
          ? const Center(
              child: Text(
                'No notes recorded. Tap + to add.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (BuildContext context, int index) {
                final note = _notes[index];
                final String noteId = note['id']?.toString() ?? '';
                return Card(
                  color: const Color(0xFF23272D),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                note['title']?.toString() ?? 'Untitled Note',
                                style: const TextStyle(
                                  color: Color(0xFFE5A93B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete note',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: noteId.isEmpty
                                  ? null
                                  : () => _deleteNote(noteId),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (note['content']?.toString().isNotEmpty ?? false)
                          Text(
                            note['content'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add note',
        backgroundColor: const Color(0xFFE5A93B),
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
