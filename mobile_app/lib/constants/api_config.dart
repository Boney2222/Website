class ApiConfig {
  ApiConfig._();

  // Android emulator URL for XAMPP running on this Windows machine.
  // For a physical phone, replace 10.0.2.2 with your PC's local IPv4 address.
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: defaultBaseUrl);

  static const String defaultBaseUrl =
      'http://10.0.2.2/stationery-shop-project/backend/api';
}
