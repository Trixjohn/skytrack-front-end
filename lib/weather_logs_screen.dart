import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_theme.dart';

const _kBase = 'http://127.0.0.1:8000/api';

class WeatherLogsScreen extends StatefulWidget {
  const WeatherLogsScreen({super.key});

  @override
  State<WeatherLogsScreen> createState() => _WeatherLogsScreenState();
}

class _WeatherLogsScreenState extends State<WeatherLogsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  // ── GET /weather ──────────────────────────────────────────────────────────

  Future<void> _fetchLogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http
          .get(
            Uri.parse('$_kBase/weather'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        setState(() {
          _logs = jsonDecode(res.body) as List<dynamic>;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load logs (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Could not connect — is the server running?';
        _loading = false;
      });
    }
  }

  // ── POST /weather ─────────────────────────────────────────────────────────

  Future<void> _addLog(Map<String, dynamic> data) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_kBase/weather'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        await _fetchLogs();
        _showSnack('Log added successfully!', icon: Icons.check_circle_outline);
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['message'] ?? 'Failed to add log');
      }
    } catch (_) {
      _showSnack('Could not connect to server');
    }
  }

  // ── PUT /weather/{id} ─────────────────────────────────────────────────────

  Future<void> _updateLog(int id, Map<String, dynamic> data) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_kBase/weather/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        await _fetchLogs();
        _showSnack('Log updated!', icon: Icons.edit_outlined);
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['message'] ?? 'Failed to update log');
      }
    } catch (_) {
      _showSnack('Could not connect to server');
    }
  }

  // ── DELETE /weather/{id} ──────────────────────────────────────────────────

  Future<void> _deleteLog(int id, String city) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$_kBase/weather/$id'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        await _fetchLogs();
        _showSnack('$city log deleted', icon: Icons.delete_outline);
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['message'] ?? 'Failed to delete log');
      }
    } catch (_) {
      _showSnack('Could not connect to server');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, {IconData? icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(msg)),
        ]),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _conditionIcon(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('sun') || d.contains('clear')) return '☀️';
    if (d.contains('thunder')) return '⛈';
    if (d.contains('heavy rain')) return '🌧';
    if (d.contains('rain') || d.contains('shower')) return '🌦';
    if (d.contains('fog')) return '🌫';
    if (d.contains('wind')) return '🌬';
    if (d.contains('cloud') || d.contains('overcast')) return '⛅';
    return '🌤';
  }

  // ── Add / Edit Dialog ─────────────────────────────────────────────────────

  void _showFormDialog([Map<String, dynamic>? existing]) {
    final isEdit = existing != null;
    final cityCtrl =
        TextEditingController(text: existing?['city']?.toString() ?? '');
    final tempCtrl = TextEditingController(
        text: existing?['temperature']?.toString() ?? '');
    final humidCtrl = TextEditingController(
        text: existing?['humidity']?.toString() ?? '');
    final descCtrl = TextEditingController(
        text: existing?['description']?.toString() ?? '');
    final windCtrl = TextEditingController(
        text: existing?['wind_speed']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Log' : 'Add Weather Log'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formField(cityCtrl, 'City', Icons.location_city_outlined),
                _formField(tempCtrl, 'Temperature (°C)', Icons.thermostat_outlined,
                    isNum: true),
                _formField(humidCtrl, 'Humidity (%)', Icons.water_drop_outlined,
                    isNum: true),
                _formField(descCtrl, 'Description', Icons.cloud_outlined),
                _formField(windCtrl, 'Wind Speed (km/h)', Icons.air,
                    isNum: true, isLast: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final data = {
                'city': cityCtrl.text.trim(),
                'temperature': double.parse(tempCtrl.text.trim()),
                'humidity': int.parse(humidCtrl.text.trim()),
                'description': descCtrl.text.trim(),
                'wind_speed': double.parse(windCtrl.text.trim()),
              };
              Navigator.pop(ctx);
              if (isEdit) {
                _updateLog(existing['id'] as int, data);
              } else {
                _addLog(data);
              }
            },
            child: Text(isEdit ? 'Update' : 'Add Log'),
          ),
        ],
      ),
    );
  }

  Widget _formField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNum = false,
    bool isLast = false,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
        child: TextFormField(
          controller: ctrl,
          keyboardType: isNum
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return '$label is required';
            if (isNum && double.tryParse(v.trim()) == null) {
              return 'Enter a valid number';
            }
            return null;
          },
        ),
      );

  // ── Delete confirm ────────────────────────────────────────────────────────

  Future<bool> _confirmDelete(Map<String, dynamic> log) async {
    final city = log['city'] ?? 'this entry';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Log'),
        content: Text('Remove the weather log for "$city"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weather Logs',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
            Text('${_logs.length} entries',
                style: TextStyle(fontSize: 11, color: c.textTertiary)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: c.textSecondary),
            onPressed: _fetchLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Log'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_outlined,
                            size: 64, color: c.textTertiary),
                        const SizedBox(height: 16),
                        Text(_error!,
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 14),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _fetchLogs,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_outlined,
                              size: 72, color: c.textTertiary),
                          const SizedBox(height: 16),
                          Text('No weather logs yet',
                              style: TextStyle(
                                  color: c.textSecondary, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Tap "Add Log" to create your first entry',
                              style: TextStyle(
                                  color: c.textTertiary, fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchLogs,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: _logs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _buildLogCard(_logs[i] as Map<String, dynamic>),
                      ),
                    ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final c = context.ac;
    final city = log['city']?.toString() ?? 'Unknown';
    final temp = log['temperature'];
    final humid = log['humidity'];
    final desc = log['description']?.toString() ?? '';
    final wind = log['wind_speed'];
    final id = log['id'] as int;

    return Dismissible(
      key: Key('log_$id'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(log),
      onDismissed: (_) => _deleteLog(id, city),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 22),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _showFormDialog(log),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Row(
            children: [
              // Weather icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.blueLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _conditionIcon(desc),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text(desc,
                        style: TextStyle(
                            fontSize: 12, color: c.textSecondary)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _chip('💧 $humid%', c),
                      const SizedBox(width: 6),
                      _chip('💨 ${wind}km/h', c),
                    ]),
                  ],
                ),
              ),
              // Temp + edit hint
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$temp°C',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          color: c.blue)),
                  const SizedBox(height: 6),
                  Icon(Icons.edit_outlined,
                      size: 14, color: c.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, AC c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.blueLight,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(text, style: TextStyle(fontSize: 10, color: c.blue)),
      );
}
