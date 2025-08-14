import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_weather_service.dart';
import 'package:intl/intl.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchLocationWeather();
  }

  Future<void> fetchLocationWeather() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMessage = 'Location services are disabled.';
          isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = 'Location permission denied.';
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage =
              'Location permissions are permanently denied. Enable them in settings.';
          isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final data = await LocationWeatherService.getCompleteWeather(
        position.latitude,
        position.longitude,
      );

      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching location/weather: $e';
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
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                weatherData?['city'] ?? 'Current Location',
                style: const TextStyle(color: Colors.white, fontSize: 22),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent))
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${(weatherData!['temp'] - 273.15).toStringAsFixed(1)}°C",
                            style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Image.network(
                            "https://openweathermap.org/img/wn/${weatherData!['icon']}@2x.png",
                            width: 80,
                            height: 80,
                          ),
                        ],
                      ),
                      Text(
                        weatherData!['condition'] ?? '--',
                        style: const TextStyle(
                            fontSize: 18, color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.water_drop, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text("${weatherData!['humidity']}%",
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.air,
                                  color: Colors.greenAccent),
                              const SizedBox(width: 4),
                              Text("${weatherData!['wind_speed']} m/s",
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.wb_sunny_outlined,
                                  color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                "Sunrise: ${formatTimeFromUnix(weatherData!['sunrise'], weatherData!['timezone'])}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.nightlight_round,
                                  color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(
                                "Sunset: ${formatTimeFromUnix(weatherData!['sunset'], weatherData!['timezone'])}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text("Hourly Forecast",
                          style:
                              TextStyle(fontSize: 18, color: Colors.white)),
                      const SizedBox(height: 8),
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
                                .add(Duration(
                                    seconds: weatherData!['timezone']));
                            final timeStr =
                                DateFormat('HH:mm').format(dt);
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
                                      style: const TextStyle(
                                          color: Colors.white)),
                                  Image.network(
                                    "https://openweathermap.org/img/wn/${hour['icon']}@2x.png",
                                    width: 40,
                                  ),
                                  Text(
                                      "${(hour['temp'] - 273.15).toStringAsFixed(1)}°C",
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Weekly Forecast",
                          style:
                              TextStyle(fontSize: 18, color: Colors.white)),
                      const SizedBox(height: 8),
                      Column(
                        children: weatherData!['weekly'].map<Widget>((day) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.network(
                                      "https://openweathermap.org/img/wn/${day['icon']}@2x.png",
                                      width: 40,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(day['day'],
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ],
                                ),
                                Text(
                                  "${(day['min'] - 273.15).toStringAsFixed(1)}°C / ${(day['max'] - 273.15).toStringAsFixed(1)}°C",
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
    );
  }
}
