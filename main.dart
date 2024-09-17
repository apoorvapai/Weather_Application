import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String currentCityName = '';
  String searchedCityName = '';
  double temperature = 0.0;
  String weatherDescription = '';
  int humidity = 0;
  double windSpeed = 0.0;
  double uvIndex = 0.0;
  DateTime sunrise = DateTime.now();
  DateTime sunset = DateTime.now();
  int aqi = 0;
  String error = '';
  List<dynamic> forecast = [];

  @override
  void initState() {
    super.initState();
    getLocationWeather();
  }

  Future<void> getLocationWeather() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
    await getWeather(position.latitude, position.longitude);
    await getForecast(position.latitude, position.longitude);
  }

  Future<void> getWeather(double lat, double lon) async {
    final apiKey = 'b875909b4d8c3a6ae13abb47b7139eb2';
    final url =
        'http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));
    final jsonData = json.decode(response.body);
    setState(() {
      currentCityName = jsonData['name'];
      temperature = jsonData['main']['temp'];
      humidity = jsonData['main']['humidity'];
      windSpeed = jsonData['wind']['speed'];
      weatherDescription = jsonData['weather'][0]['main'];
      uvIndex = 5.0; // Placeholder for UV Index
      sunrise = DateTime.fromMillisecondsSinceEpoch(
          jsonData['sys']['sunrise'] * 1000);
      sunset =
          DateTime.fromMillisecondsSinceEpoch(jsonData['sys']['sunset'] * 1000);
      aqi = 50; // Placeholder for AQI
    });
  }

  Future<void> getForecast(double lat, double lon) async {
    final apiKey = 'b875909b4d8c3a6ae13abb47b7139eb2';
    final url =
        'http://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));
    final jsonData = json.decode(response.body);
    setState(() {
      forecast = jsonData['list'];
    });
  }

  Future<void> searchWeather(String cityName) async {
    final apiKey = 'b875909b4d8c3a6ae13abb47b7139eb2';
    final weatherUrl =
        'http://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric';
    final uvIndexUrl =
        'http://api.openweathermap.org/data/2.5/uvi?appid=$apiKey&lat=';
    final aqiUrl =
        'http://api.openweathermap.org/data/2.5/air_pollution?appid=$apiKey&lat=';

    try {
      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      final weatherData = json.decode(weatherResponse.body);
      final lat = weatherData['coord']['lat'];
      final lon = weatherData['coord']['lon'];

      final uvIndexResponse =
          await http.get(Uri.parse('$uvIndexUrl$lat&lon=$lon'));
      final uvIndexData = json.decode(uvIndexResponse.body);

      final aqiResponse = await http.get(Uri.parse('$aqiUrl$lat&lon=$lon'));
      final aqiData = json.decode(aqiResponse.body);

      await getForecast(lat, lon);

      setState(() {
        searchedCityName = weatherData['name'];
        temperature = weatherData['main']['temp'];
        humidity = weatherData['main']['humidity'];
        windSpeed = weatherData['wind']['speed'];
        weatherDescription = weatherData['weather'][0]['main'];
        uvIndex = uvIndexData['value'].toDouble();
        sunrise = DateTime.fromMillisecondsSinceEpoch(
            weatherData['sys']['sunrise'] * 1000);
        sunset = DateTime.fromMillisecondsSinceEpoch(
            weatherData['sys']['sunset'] * 1000);
        aqi = aqiData['list'][0]['main']['aqi'];
        error = '';
      });
    } catch (e) {
      setState(() {
        searchedCityName = '';
        error = 'Error fetching weather data for $cityName';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.cloud),
            SizedBox(width: 10),
            Text('WeatherWhiz'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF64B5F6), Color(0xFF2196F3)],
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                onChanged: (value) => searchedCityName = value,
                decoration: InputDecoration(
                  hintText: 'Enter City Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      if (searchedCityName.isNotEmpty) {
                        searchWeather(searchedCityName);
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                currentCityName.isEmpty
                    ? 'Current Location: '
                    : 'Current Location: $currentCityName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                searchedCityName.isEmpty
                    ? ''
                    : 'Searched City: $searchedCityName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                children: [
                  _buildInfoCard(
                      'Temperature', '$temperature°C', Icons.thermostat),
                  _buildInfoCard('Humidity', '$humidity%', Icons.water),
                  _buildInfoCard('Wind Speed', '$windSpeed m/s', Icons.air),
                  _buildInfoCard('UV Index', '$uvIndex', Icons.wb_sunny),
                  _buildInfoCard('Sunrise', '${sunrise.hour}:${sunrise.minute}',
                      Icons.wb_sunny_outlined),
                  _buildInfoCard('Sunset', '${sunset.hour}:${sunset.minute}',
                      Icons.nights_stay),
                  _buildInfoCard('AQI', '$aqi', Icons.air),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Weather: $weatherDescription',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              SizedBox(height: 20),
              if (error.isNotEmpty)
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 20),
              Text(
                'Forecast:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              SizedBox(height: 10),
              Container(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: forecast.length,
                  itemBuilder: (context, index) {
                    final item = forecast[index];
                    final DateTime dateTime =
                        DateTime.fromMillisecondsSinceEpoch(
                      item['dt'] * 1000,
                    );
                    final temperature = item['main']['temp'];
                    final weatherDescription =
                        item['weather'][0]['description'];
                    return _buildForecastCard(
                      '${dateTime.hour}:00',
                      '$temperature°C',
                      weatherDescription,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData iconData) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 40,
              color: Colors.blue,
            ),
            SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(
      String time, String temperature, String weatherDescription) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              time,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              temperature,
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 5),
            Text(
              weatherDescription,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
