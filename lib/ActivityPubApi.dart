import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// TDO store values more safely.

class ActivityPubApi {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  SharedPreferences? prefs;

  final String _clientName = '11t';
  final String _clientWebsite = 'https://11t.nl/';
  final String _redirectUri = 'elevent://11t.nl/';
  final String _scope = 'read write follow push';

  String _baseUrl = '';

  ActivityPubApi() {
    loadBaseUrl();
  }

  void loadBaseUrl() async {
    _baseUrl = await getPrefValue('baseUrl') ?? '';
  }

  Future<String?> getPrefValue(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<bool> setPrefValue(String key, String value) async {
    final prefs = await _prefs;
    return prefs.setString(key, value);
  }

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl.toLowerCase();
    if ('https://' != _baseUrl.substring(0, 8) || ('' == _baseUrl)) {
      throw Exception('Base url not valid');
    }
    setPrefValue('baseUrl', _baseUrl);
    fetchClientIdSecret;
  }

  void redirectToOAuthScreen() async {
    final clientId = await getPrefValue('clientId');
    final redirect =
        '${_baseUrl}oauth/authorize?client_id=$clientId&redirect_uri=$_redirectUri&response_type=code&scope=$_scope';
    final redirectEncode = Uri.encodeFull(redirect);
    if (await canLaunch(redirectEncode)) {
      await launch(redirectEncode);
    } else {
      throw Exception('Cannot show login screen');
    }
  }

  // obtain client_id and client_secret
  Future<void> get fetchClientIdSecret async {
    final response =
        await http.post(Uri.parse('${_baseUrl}api/v1/apps'), body: {
      'client_name': _clientName,
      'redirect_uris': _redirectUri,
      'scopes': _scope,
      'website': _clientWebsite,
    });

    if (200 == response.statusCode) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      final result = json.decode(response.body);
      await setPrefValue('clientId', result['client_id'].toString());
      await setPrefValue('clientSecret', result['client_secret']);

      redirectToOAuthScreen();
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load client id and secret');
    }
  }

  // Exchange oauth code for tokens.
  Future<void> exchangeCodeForTokens(String code) async {
    final clientId = await getPrefValue('clientId');
    final clientSecret = await getPrefValue('clientSecret');

    final response =
        await http.post(Uri.parse('${_baseUrl}oauth/token'), body: {
      'grant_type': 'authorization_code',
      'redirect_uri': _redirectUri,
      'code': code,
      'client_id': clientId,
      'client_secret': clientSecret,
    });

    if (200 == response.statusCode) {
      final result = json.decode(response.body);
      print(result);
      // TODO store tokens.
    } else {
      // TODO handle error
    }
  }
}