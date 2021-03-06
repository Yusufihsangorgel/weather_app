import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hava_durumu/pages/searchpage.dart';
import 'package:hava_durumu/widgets/card.dart';
import 'package:hava_durumu/widgets/sizedbox.dart';
import 'package:hava_durumu/widgets/spinKit.dart';
import 'package:intl/intl.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String sehir = 'London';
  var locationData;
  var woeid;
  var weather_state_name;

  late Position position;
  String userCountry = '';
  List arkaPlan = ['c', 'c', 'c', 'c', 'c'];
  List temps = ['', '', '', '', ''];
  List date = [
    '2022-02-23',
    '2022-02-24',
    '2022-02-25',
    '2022-02-26',
    '2022-02-27'
  ];

  Future<Position?> determinePosition() async {
    LocationPermission permission;
    await Geolocator.checkPermission();
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('burda takıldı yusuf');
      if (permission == LocationPermission.deniedForever) {
        return Future.error('Location Not Available');
      }
    } else {
      throw Exception('Error');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> getPosition() async {
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);
    } catch (e) {
      print('hata : $e');
    }
  }

  Future<void> getLocationData() async {
    if (userCountry == '') {
      locationData = await http.get(
          "https://www.metaweather.com/api/location/search/?lattlong=${position.latitude},${position.longitude}");
    } else {
      locationData = await http.get(
          "https://www.metaweather.com/api/location/search/?query=$userCountry");
    }

    print('location data : $locationData');
    var locationDataParsed = jsonDecode(utf8.decode(locationData.bodyBytes));
    woeid = locationDataParsed[0]['woeid'];
    print('woeid çağrıldı $woeid');

    sehir = locationDataParsed[0]['title'];
    print('şehir çağrıldı $sehir');
    weather_state_name = locationDataParsed[0]['weather_state_name'];
  }

  Future<void> getLocationTemperature() async {
    var response =
        await http.get('https://www.metaweather.com/api/location/$woeid/');
    var temperatureDataParsed = jsonDecode(response.body);
    setState(() {
      for (var i = 0; i < temps.length; i++) {
        temps[i] = temperatureDataParsed['consolidated_weather'][i]['the_temp']
            .round();
        date[i] =
            temperatureDataParsed['consolidated_weather'][i]['applicable_date'];
        arkaPlan[i] = temperatureDataParsed['consolidated_weather'][i]
            ["weather_state_abbr"];
      }
      print('tarih : $date');
      print('Sıcaklık = ${temps[0]}');
      print('hava kısaltması : ' + arkaPlan[0]);
    });
  }

  void konum() async {
    await determinePosition();
  }

  void yardimciFonksiyon() async {
    await getPosition();
    await getLocationData();
    await getLocationTemperature();
  }

  void initState() {
    konum();
    yardimciFonksiyon();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage("images/${arkaPlan[0]}.jpg"),
        ),
      ),
      child: temps[0] == null
          ? Center(child: (mySpinKit.spinkit))
          : Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      child: Image.network(
                          'https://www.metaweather.com/static/img/weather/png/${arkaPlan[0]}.png'),
                    ),
                    Text(
                      temps[0].toString() + "° C",
                      style: TextStyle(
                          fontSize: 70,
                          fontWeight: FontWeight.w600,
                          shadows: <Shadow>[
                            Shadow(
                                color: Colors.black38,
                                blurRadius: 5,
                                offset: Offset(-3, 3))
                          ]),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: sehir == 'Ä°zmir'
                              ? Text(
                                  'İzmir',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      shadows: <Shadow>[
                                        Shadow(
                                            color: Colors.black38,
                                            blurRadius: 5,
                                            offset: Offset(-3, 3))
                                      ]),
                                )
                              : Text(
                                  sehir.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      shadows: <Shadow>[
                                        Shadow(
                                            color: Colors.black38,
                                            blurRadius: 5,
                                            offset: Offset(-3, 3))
                                      ]),
                                ),
                        ),
                        IconButton(
                          onPressed: () async {
                            userCountry = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchPage(),
                              ),
                            );
                            yardimciFonksiyon();
                            setState(() {
                              sehir = sehir;
                              temps[0] = null;
                            });
                          },
                          icon: Icon(
                            Icons.search,
                            size: 30,
                          ),
                        )
                      ],
                    ),
                    Row(),
                    MySize(size: 30),
                    Container(
                      height: 200,
                      width: MediaQuery.of(context).size.width * 0.95,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (_, dynamic index) {
                          return MyCard(
                              transportImage: arkaPlan[index],
                              degree: temps[index].toString(),
                              date: date[index].toString());
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
