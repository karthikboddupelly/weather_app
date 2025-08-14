import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_key.dart';

class LocationWeatherService {
  static Future<Map<String, dynamic>> getCompleteWeather(double lat, double lon) async {
    final uri = Uri.parse(
        'https://open-weather13.p.rapidapi.com/latlon?latitude=$lat&longitude=$lon&lang=EN&units=metric'); // added units=metric

    final response = await http.get(uri, headers: {
      'x-rapidapi-host': rapidApiHost,
      'x-rapidapi-key': rapidApiKey,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch current weather');
    }

    final data = jsonDecode(response.body);

    // Hourly & Weekly forecast
    final forecastUri = Uri.parse(
        'https://open-weather13.p.rapidapi.com/fivedaysforcast?latitude=$lat&longitude=$lon&lang=EN&units=metric'); // added units=metric

    final forecastResp = await http.get(forecastUri, headers: {
      'x-rapidapi-host': rapidApiHost,
      'x-rapidapi-key': rapidApiKey,
    });

    if (forecastResp.statusCode != 200) {
      throw Exception('Failed to fetch forecast');
    }

    final forecastData = jsonDecode(forecastResp.body);

    // Map hourly
    final hourly = (forecastData['list'] as List).map((e) => {
          "timestamp": e['dt'],
          "temp": e['main']['temp'],
          "icon": e['weather'][0]['icon'],
          "wind_speed": e['wind']['speed'],
          "humidity": e['main']['humidity'],
        }).toList();

    // Map weekly (daily)
    final dailyMap = <String, Map<String, dynamic>>{};
    for (var e in forecastData['list']) {
      final date = e['dt_txt'].split(' ')[0];
      final temp = e['main']['temp'];
      final icon = e['weather'][0]['icon'];
      if (!dailyMap.containsKey(date)) {
        dailyMap[date] = {"min": temp, "max": temp, "icon": icon};
      } else {
        dailyMap[date]!['min'] = (temp < dailyMap[date]!['min']) ? temp : dailyMap[date]!['min'];
        dailyMap[date]!['max'] = (temp > dailyMap[date]!['max']) ? temp : dailyMap[date]!['max'];
      }
    }

    final weekly = dailyMap.entries.map((e) {
      final dayName = DateTime.parse(e.key).weekday;
      return {
        "day": ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"][dayName-1],
        "min": e.value['min'],
        "max": e.value['max'],
        "icon": e.value['icon'],
      };
    }).toList();

    return {
      "city": data['name'],
      "temp": data['main']['temp'],
      "humidity": data['main']['humidity'],
      "wind_speed": data['wind']['speed'],
      "condition": data['weather'][0]['main'],
      "icon": data['weather'][0]['icon'],
      "sunrise": data['sys']['sunrise'],
      "sunset": data['sys']['sunset'],
      "timezone": data['timezone'],
      "hourly": hourly,
      "weekly": weekly,
    };
  }
}
