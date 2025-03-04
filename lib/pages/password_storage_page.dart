import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secuprime_mobile/pages/trash_bin_page.dart';
import '../services/password_storage_service.dart';

class PasswordStoragePage extends StatefulWidget {
  @override
  _PasswordStoragePageState createState() => _PasswordStoragePageState();
}

class _PasswordStoragePageState extends State<PasswordStoragePage> {
  final _passwordService = PasswordStorageService();
  List<Map<String, dynamic>> _passwords = [];
  final Map<int, bool> _passwordVisibility = {};
  final _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    setState(() => _isLoading = true);
    try {
      final passwords = await _passwordService.getSavedPasswords();
      setState(() {
        _passwords = passwords;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load passwords');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF191647),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white70,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _deletePassword(Map<String, dynamic> password) async {
    try {
      await _passwordService.deletePassword(password['id']);
      _loadPasswords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password moved to trash successfully'),
            backgroundColor: Color(0xFF191647),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white70,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete password');
    }
  }

  Future<void> _editLabel(Map<String, dynamic> password) async {
    final textController = TextEditingController(text: password['label']);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF191647),
        title: Text('Edit Label', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Label',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white60),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0073e6)),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: Text('Save', style: TextStyle(color: Color(0xFF0073e6))),
          ),
        ],
      ),
    );

    if (newLabel != null && newLabel.isNotEmpty) {
      try {
        await _passwordService.updatePasswordLabel(password['id'], newLabel);
        _loadPasswords();
      } catch (e) {
        _showErrorSnackBar('Failed to update label');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF191647),
      appBar: AppBar(
        title: const Text('Saved Passwords',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF191647),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white70, size: 26),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TrashBinPage()),
              );
              _loadPasswords();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search passwords...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF191647).withOpacity(0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: (value) async {
                if (value.isEmpty) {
                  _loadPasswords();
                } else {
                  final results = await _passwordService.searchPasswords(value);
                  setState(() => _passwords = results);
                }
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.white70,
                strokeWidth: 2.5,
              ),
            )
          : _passwords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No passwords saved yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: Colors.white70,
                  backgroundColor: Color(0xFF191647),
                  onRefresh: _loadPasswords,
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: _passwords.length,
                    itemBuilder: (context, index) {
                      final password = _passwords[index];
                      return Dismissible(
                        key: Key(password['id'].toString()),
                        background: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          color: Color(0xFFB00020),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete,
                              color: Colors.white, size: 28),
                        ),
                        onDismissed: (direction) => _deletePassword(password),
                        child: Card(
                          color: Color(0xFF191647).withOpacity(0.7),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: InkWell(
                            onTap: () {},
                            splashColor: Colors.white.withOpacity(0.1),
                            highlightColor: Colors.transparent,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              title: Text(
                                password['label'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 6),
                                  Text(
                                    _passwordVisibility[password['id']] == true
                                        ? password['password']
                                        : '•' * password['password'].length,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: Colors.white,
                                      fontSize: 14,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Length: ${password['password'].length} | Metrics: ${password['metrics']}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedScale(
                                    scale:
                                        _passwordVisibility[password['id']] ??
                                                false
                                            ? 1.1
                                            : 1.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: IconButton(
                                      icon: Icon(
                                        _passwordVisibility[password['id']] ==
                                                true
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white70,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _passwordVisibility[password['id']] =
                                              !(_passwordVisibility[
                                                      password['id']] ??
                                                  false);
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.copy,
                                      color: Colors.white70,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                            text: password['password']),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Password copied!'),
                                          backgroundColor: Color(0xFF191647),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: Colors.white70,
                                      size: 24,
                                    ),
                                    onPressed: () => _editLabel(password),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
