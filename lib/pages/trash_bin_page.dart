import 'package:flutter/material.dart';
import '../services/password_storage_service.dart';

class TrashBinPage extends StatefulWidget {
  @override
  _TrashBinPageState createState() => _TrashBinPageState();
}

class _TrashBinPageState extends State<TrashBinPage> {
  final _passwordService = PasswordStorageService();
  List<Map<String, dynamic>> _deletedPasswords = [];

  @override
  void initState() {
    super.initState();
    _loadDeletedPasswords();
  }

  Future<void> _loadDeletedPasswords() async {
    try {
      final deletedPasswords = await _passwordService.getDeletedPasswords();
      setState(() {
        _deletedPasswords = deletedPasswords;
      });
    } catch (e) {
      _showSnackBar('Failed to load deleted passwords: ${e.toString()}');
    }
  }

  Future<void> _restorePassword(Map<String, dynamic> password) async {
    try {
      await _passwordService.restorePassword(password['id']);
      _loadDeletedPasswords();
      _showSnackBar('Password restored successfully');
    } catch (e) {
      _showSnackBar('Failed to restore password: ${e.toString()}');
    }
  }

  Future<void> _permanentlyDeletePassword(Map<String, dynamic> password) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF191647),
          title: Text('Confirm Permanent Deletion',
              style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to permanently delete this password? This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.white60)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Color(0xFF0073e6))),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await _passwordService.permanentlyDeletePassword(password['id']);
        _loadDeletedPasswords();
        _showSnackBar('Password permanently deleted');
      } catch (e) {
        _showSnackBar('Failed to delete password: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash Bin'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _deletedPasswords.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No deleted passwords',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _deletedPasswords.length,
              itemBuilder: (context, index) {
                final password = _deletedPasswords[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.lock, color: Colors.red),
                    title: Text(
                      password['label'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Deleted on: ${DateTime.parse(password['timestamp']).toLocal()}',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.restore, color: Colors.blue),
                          onPressed: () => _restorePassword(password),
                          tooltip: 'Restore Password',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () => _permanentlyDeletePassword(password),
                          tooltip: 'Permanently Delete',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
