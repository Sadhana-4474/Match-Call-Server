import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'dart:io';

Future<String> getAccessToken(String serviceAccountPath) async {
  final file = File(serviceAccountPath);

  if(!await file.exists()) {
    throw Exception("Service account file not found at $serviceAccountPath");
  }

  final jsonString = await file.readAsString();
  final Map<String, dynamic> jsonData = json.decode(jsonString);

  if (!jsonData.containsKey('private_key') || !jsonData.containsKey('client_email')) {
    throw Exception("Invalid service account JSON: missing private_key or client_email");
  }

  final String privateKeyPem = jsonData['private_key'];
  final String clientEmail = jsonData['client_email'];
  final String tokenUri = jsonData['token_uri'];

  final now = DateTime.now().toUtc();
  final iat = (now.millisecondsSinceEpoch / 1000).round();
  final exp = iat + 3600; // 1 hour expiry

  final claims = JsonWebTokenClaims.fromJson({
    'iss': clientEmail,
    'scope': 'https://www.googleapis.com/auth/firebase.messaging',
    'aud': tokenUri,
    'iat': iat,
    'exp': exp,
  });

  ///convert PEM private key to JsonWebKey
  final builder = JsonWebSignatureBuilder()
    ..jsonContent = claims.toJson()
    ..addRecipient(JsonWebKey.fromPem(privateKeyPem), algorithm: 'RS256');

  final jws = builder.build();
  final assertion = jws.toCompactSerialization();

  final uri = Uri.parse(tokenUri);
  final httpClient = HttpClient();
  final request = await httpClient.postUrl(uri);
  request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
  request.write('grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=$assertion');
  final response = await request.close();
  final respBody = await response.transform(utf8.decoder).join();

  if (response.statusCode == 200) {
    try {
      final data = json.decode(respBody);
      return data['access_token'];
    } catch (e) {
      throw Exception("Failed to parse token response: $respBody");
    }
  } else {
    throw Exception('Failed to get access token: ${respBody}');
  }
}
