import 'package:flutter/material.dart';
import '../services/city_weather_service.dart';
import 'package:intl/intl.dart';

class ResultScreen extends StatefulWidget {
  final String cityName;
  const ResultScreen({super.key, required this.cityName});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchCityWeather();
  }

  Future<void> fetchCityWeather() async {
    try {
      final data = await CityWeatherService.getCompleteWeather(widget.cityName);
      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String formatTimeFromUnix(int timestamp, int timezoneOffset) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true)
        .add(Duration(seconds: timezoneOffset));
    return DateFormat('HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.cityName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Navigate to search screen
            },
          )
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade900,
              Colors.black87,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
            : errorMessage != null
                ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 120, 16, 16), // top padding separates AppBar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Temperature and icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${(weatherData!['temp'] - 273.15).toStringAsFixed(1)}°C",
                                  style: const TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  weatherData!['condition'] ?? '--',
                                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                                ),
                              ],
                            ),
                            Image.network(
                              "https://openweathermap.org/img/wn/${weatherData!['icon']}@2x.png",
                              width: 80,
                              height: 80,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Humidity and Wind
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.water_drop, color: Colors.blueAccent),
                                const SizedBox(width: 4),
                                Text("${weatherData!['humidity']}%",
                                    style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.air, color: Colors.greenAccent),
                                const SizedBox(width: 4),
                                Text("${weatherData!['wind_speed']} m/s",
                                    style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Sunrise & Sunset
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.wb_sunny_outlined, color: Colors.orangeAccent),
                                const SizedBox(width: 4),
                                Text(
                                  "Sunrise: ${formatTimeFromUnix(weatherData!['sunrise'], weatherData!['timezone'])}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.nightlight_round, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Text(
                                  "Sunset: ${formatTimeFromUnix(weatherData!['sunset'], weatherData!['timezone'])}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Hourly Forecast
                        const Text("Hourly Forecast",
                            style: TextStyle(fontSize: 18, color: Colors.white)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: weatherData!['hourly'].length,
                            itemBuilder: (context, index) {
                              final hour = weatherData!['hourly'][index];
                              final dt = DateTime.fromMillisecondsSinceEpoch(
                                      hour['timestamp'] * 1000,
                                      isUtc: true)
                                  .add(Duration(seconds: weatherData!['timezone']));
                              final timeStr = DateFormat('HH:mm').format(dt);
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(timeStr,
                                        style: const TextStyle(color: Colors.white)),
                                    Image.network(
                                      "https://openweathermap.org/img/wn/${hour['icon']}@2x.png",
                                      width: 40,
                                    ),
                                    Text("${(hour['temp'] - 273.15).toStringAsFixed(1)}°C",
                                        style: const TextStyle(color: Colors.white)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Weekly Forecast
                        const Text("Weekly Forecast",
                            style: TextStyle(fontSize: 18, color: Colors.white)),
                        const SizedBox(height: 10),
                        Column(
                          children: weatherData!['weekly'].map<Widget>((day) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Image.network(
                                        "https://openweathermap.org/img/wn/${day['icon']}@2x.png",
                                        width: 40,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(day['day'],
                                          style: const TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                  Text(
                                    "${(day['min'] - 273.15).toStringAsFixed(1)}°C / ${(day['max'] - 273.15).toStringAsFixed(1)}°C",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
