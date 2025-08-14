import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_key.dart';
import 'location_weather_service.dart';

class CityWeatherService {
  static Future<Map<String, dynamic>> getCompleteWeather(String cityName) async {
    final uri = Uri.parse(
        'https://open-weather13.p.rapidapi.com/city?city=$cityName&lang=EN');

    final response = await http.get(uri, headers: {
      'x-rapidapi-host': rapidApiHost,
      'x-rapidapi-key': rapidApiKey,
    });

    if (response.statusCode != 200) {
      throw Exception('City not found');
    }

    final data = jsonDecode(response.body);

    final lat = data['coord']['lat'];
    final lon = data['coord']['lon'];

    // LocationWeatherService now returns temp in Celsius
    return await LocationWeatherService.getCompleteWeather(lat, lon);
  }
}
