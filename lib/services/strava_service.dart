import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class StravaService {
  static const String _clientId = '150848';
  static const String _clientSecret = '72af103d651584b37d751f899ef80d04f646b6e2';
  static const String _redirectUrl = 'http://localhost:8080';
  static const String _authUrl = 'https://www.strava.com/oauth/authorize';
  static const String _tokenUrl = 'https://www.strava.com/oauth/token';

  final SharedPreferences _prefs;

  StravaService(this._prefs);

  Future<bool> get isAuthenticated async {
    final token = _prefs.getString('strava_access_token');
    final expiresAt = _prefs.getInt('strava_expires_at');
    if (token == null || expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch < expiresAt;
  }

  Future<void> authenticate() async {
    try {
      print('Starting Strava authentication...');
      
      final state = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Construct the authorization URL with mobile-optimized parameters
      final authorizeUrl = Uri.parse(_authUrl).replace(queryParameters: {
        'client_id': _clientId,
        'redirect_uri': _redirectUrl,
        'response_type': 'code',
        'scope': 'read,activity:read,activity:read_all',
        'approval_prompt': 'auto',
        'state': state,
      });

      print('Authorization URL: ${authorizeUrl.toString()}');

      // Present the authorization page to the user
      final result = await FlutterWebAuth2.authenticate(
        url: authorizeUrl.toString(),
        callbackUrlScheme: 'http',
      );

      print('Received callback URL: $result');

      // Extract authorization code from response
      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      final returnedState = uri.queryParameters['state'];
      
      if (error != null) {
        print('Error received from Strava: $error');
        throw Exception('Authorization failed: $error');
      }
      
      if (code == null) {
        print('No authorization code received in callback');
        throw Exception('No authorization code received');
      }

      if (returnedState != state) {
        print('State mismatch. Expected: $state, Got: $returnedState');
        throw Exception('Invalid state parameter');
      }

      print('Exchanging code for token...');

      // Exchange authorization code for access token
      final tokenResponse = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': _redirectUrl,
        },
      );

      print('Token response status: ${tokenResponse.statusCode}');
      print('Token response body: ${tokenResponse.body}');

      if (tokenResponse.statusCode != 200) {
        throw Exception('Failed to get access token: ${tokenResponse.body}');
      }

      final tokenData = json.decode(tokenResponse.body);
      await _prefs.setString('strava_access_token', tokenData['access_token']);
      await _prefs.setInt('strava_expires_at', tokenData['expires_at'] * 1000);
      await _prefs.setString('strava_refresh_token', tokenData['refresh_token']);
      
      print('Authentication completed successfully');
    } catch (e) {
      print('Error during Strava authentication: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAthleteStats() async {
    try {
      final token = await _getValidToken();
      if (token == null) throw Exception('Not authenticated with Strava');

      // First get the athlete ID
      final athleteResponse = await http.get(
        Uri.parse('https://www.strava.com/api/v3/athlete'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (athleteResponse.statusCode != 200) {
        throw Exception('Failed to get athlete data');
      }

      final athleteData = json.decode(athleteResponse.body);
      final athleteId = athleteData['id'];

      // Then get the stats
      final statsResponse = await http.get(
        Uri.parse('https://www.strava.com/api/v3/athletes/$athleteId/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (statsResponse.statusCode != 200) {
        throw Exception('Failed to get athlete stats');
      }

      final stats = json.decode(statsResponse.body);
      return {
        'total_distance': stats['all_run_totals']['distance'] ?? 0,
        'total_runs': stats['all_run_totals']['count'] ?? 0,
        'recent_runs': stats['recent_run_totals']['count'] ?? 0,
        'ytd_distance': stats['ytd_run_totals']['distance'] ?? 0,
      };
    } catch (e) {
      print('Error getting athlete stats: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      final token = await _getValidToken();
      if (token == null) throw Exception('Not authenticated with Strava');

      final response = await http.get(
        Uri.parse('https://www.strava.com/api/v3/athlete/activities')
            .replace(queryParameters: {
          'per_page': '10',
          'after': (DateTime.now()
                      .subtract(const Duration(days: 30))
                      .millisecondsSinceEpoch ~/
                  1000)
              .toString(),
        }),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get activities');
      }

      final activities = json.decode(response.body) as List;
      return activities.map((activity) => activity as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting recent activities: $e');
      rethrow;
    }
  }

  Future<String?> _getValidToken() async {
    final token = _prefs.getString('strava_access_token');
    final expiresAt = _prefs.getInt('strava_expires_at');
    final refreshToken = _prefs.getString('strava_refresh_token');

    if (token == null || expiresAt == null || refreshToken == null) {
      return null;
    }

    // If token is expired, refresh it
    if (DateTime.now().millisecondsSinceEpoch >= expiresAt) {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode != 200) {
        await logout();
        return null;
      }

      final tokenData = json.decode(response.body);
      await _prefs.setString('strava_access_token', tokenData['access_token']);
      await _prefs.setInt('strava_expires_at', tokenData['expires_at'] * 1000);
      await _prefs.setString('strava_refresh_token', tokenData['refresh_token']);
      return tokenData['access_token'];
    }

    return token;
  }

  Future<void> logout() async {
    await _prefs.remove('strava_access_token');
    await _prefs.remove('strava_expires_at');
    await _prefs.remove('strava_refresh_token');
  }
} 