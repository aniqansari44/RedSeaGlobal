class StationData {
  final int? id;
  final String stationName;
  final String stationCity;
  final double stationLatitude;
  final double stationLongitude;
  final double stationPM25;
  final double stationPM10;
  final double stationO3;
  final double stationNO2;
  final double stationAQI;
  final double stationPAQI;
  final String fillColor;
  final String pFillColor;
  final String aqiTitle;
  final String paqiTitle;
  final double stationSO2;
  final double stationNO;
  final double stationSR;
  final double stationNOX;
  final double stationH2;
  final double? stationCO;      // Nullable double
  final double? stationCH4;     // Nullable double
  final double? stationNMHC;    // Nullable double
  final double? stationTHC;     // Nullable double
  final double temp;
  final double rain;
  final double humidity;
  final double windspeed;
  final double winddirection;
  final double pressure;
  final String lastUpdate;

  StationData({
    required this.id,
    required this.stationName,
    required this.stationCity,
    required this.stationLatitude,
    required this.stationLongitude,
    required this.stationPM25,
    required this.stationPM10,
    required this.stationO3,
    required this.stationNO2,
    required this.stationAQI,
    required this.stationPAQI,
    required this.fillColor,
    required this.pFillColor,
    required this.aqiTitle,
    required this.paqiTitle,
    required this.stationSO2,
    required this.stationNO,
    required this.stationSR,
    required this.stationNOX,
    required this.stationH2,
    this.stationCO,        // Nullable double
    this.stationCH4,       // Nullable double
    this.stationNMHC,      // Nullable double
    this.stationTHC,       // Nullable double
    required this.temp,
    required this.rain,
    required this.humidity,
    required this.windspeed,
    required this.winddirection,
    required this.pressure,
    required this.lastUpdate,
  });

  factory StationData.fromJson(Map<String, dynamic> json) {
    return StationData(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      stationName: json['station_name'] ?? 'Unknown',
      stationCity: json['station_city'] ?? 'Unknown',
      stationLatitude: double.tryParse(json['station_latitude'].toString()) ?? 0,
      stationLongitude: double.tryParse(json['station_longitude'].toString()) ?? 0,
      stationPM25: double.tryParse(json['stationPM25'].toString()) ?? 0,
      stationPM10: double.tryParse(json['stationPM10'].toString()) ?? 0,
      stationO3: double.tryParse(json['stationO3'].toString()) ?? 0,
      stationNO2: double.tryParse(json['stationNO2'].toString()) ?? 0,
      stationAQI: double.tryParse(json['stationAQI'].toString()) ?? 0,
      stationPAQI: double.tryParse(json['stationPAQI'].toString()) ?? 0,
      fillColor: json['fillColor'] ?? '#000000',
      pFillColor: json['pFillColor'] ?? '#000000',
      aqiTitle: json['aqiTitle'] ?? 'Unknown',
      paqiTitle: json['paqiTitle'] ?? 'Unknown',
      stationSO2: double.tryParse(json['stationSO2'].toString()) ?? 0,
      stationNO: double.tryParse(json['stationNO'].toString()) ?? 0,
      stationSR: double.tryParse(json['stationSR'].toString()) ?? 0,
      stationNOX: double.tryParse(json['stationNOX'].toString()) ?? 0,
      stationH2: double.tryParse(json['stationH2'].toString()) ?? 0,
      stationCO: json['stationCO'] != null ? double.tryParse(json['stationCO'].toString()) : null,
      stationCH4: json['stationCH4'] != null ? double.tryParse(json['stationCH4'].toString()) : null,
      stationNMHC: json['stationNMHC'] != null ? double.tryParse(json['stationNMHC'].toString()) : null,
      stationTHC: json['stationTHC'] != null ? double.tryParse(json['stationTHC'].toString()) : null,
      temp: double.tryParse(json['temp'].toString()) ?? 0,
      rain: double.tryParse(json['rain'].toString()) ?? 0,
      humidity: double.tryParse(json['humidity'].toString()) ?? 0,
      windspeed: double.tryParse(json['windspeed'].toString()) ?? 0,
      winddirection: double.tryParse(json['winddirection'].toString()) ?? 0,
      pressure: double.tryParse(json['pressure'].toString()) ?? 0,
      lastUpdate: json['last_update'] ?? 'Unknown',
    );
  }
}
