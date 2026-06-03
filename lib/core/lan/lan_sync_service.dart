import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../../data/database/app_database.dart';

/// Local LAN sync — Team Head hosts; joiners pull/push on same Wi-Fi.
class LanSyncService {
  LanSyncService(this._db);
  final AppDatabase _db;

  HttpServer? _server;
  String? _pairingCode;
  int _port = 8765;

  bool get isRunning => _server != null;
  String? get pairingCode => _pairingCode;
  int get port => _port;

  Future<String?> startHost() async {
    if (_server != null) return _pairingCode;
    _pairingCode = _generateCode();
    final router = Router()
      ..get('/status', _status)
      ..get('/export', _export)
      ..post('/import', _import);

    final handler = Pipeline()
        .addMiddleware(_cors)
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
    return _pairingCode;
  }

  Future<void> stopHost() async {
    await _server?.close(force: true);
    _server = null;
    _pairingCode = null;
  }

  Future<String?> getLocalIp() async {
    final info = NetworkInfo();
    return info.getWifiIP();
  }

  Future<void> syncFromHost(String hostIp, String code) async {
    final client = HttpClient();
    try {
      final statusReq =
          await client.getUrl(Uri.parse('http://$hostIp:$_port/status'));
      final statusRes = await statusReq.close();
      final statusBody = await statusRes.transform(utf8.decoder).join();
      final status = jsonDecode(statusBody) as Map<String, dynamic>;
      if (status['code'] != code) {
        throw Exception('Invalid pairing code');
      }
      final exportReq =
          await client.getUrl(Uri.parse('http://$hostIp:$_port/export'));
      final exportRes = await exportReq.close();
      final exportBody = await exportRes.transform(utf8.decoder).join();
      final data = jsonDecode(exportBody) as Map<String, dynamic>;
      await _db.replaceAllFromBackup(data);
    } finally {
      client.close();
    }
  }

  Response _status(Request req) {
    return Response.ok(
      jsonEncode({'ok': true, 'code': _pairingCode, 'app': 'Krmaazha Team Hub'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _export(Request req) async {
    final data = await _db.exportAll();
    return Response.ok(jsonEncode(data),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _import(Request req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    await _db.replaceAllFromBackup(data);
    return Response.ok(jsonEncode({'ok': true}));
  }

  Middleware get _cors => (Handler inner) {
        return (Request request) async {
          if (request.method == 'OPTIONS') {
            return Response.ok('', headers: _corsHeaders);
          }
          final response = await inner(request);
          return response.change(headers: _corsHeaders);
        };
      };

  Map<String, String> get _corsHeaders => {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      };

  String _generateCode() {
    final r = Random();
    return List.generate(6, (_) => r.nextInt(10)).join();
  }
}
