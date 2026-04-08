class ApiConfig {
  static const String defaultBaseUrl =
      'http://tartelea-backend-qfc3zc-c3d74b-72-62-41-242.traefik.me/api/v1';
  static const String defaultLivekitBaseUrl =
      'https://tartelea-nodejs-ncyno3-ed08c5-72-62-41-242.traefik.me';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );
  static const String livekitBaseUrl = String.fromEnvironment(
    'LIVEKIT_API_BASE_URL',
    defaultValue: defaultLivekitBaseUrl,
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '199107182598-d9b1anek3f57ij2427c14h8d05blfg3e.apps.googleusercontent.com',
  );

  // Auth endpoints
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String verifyEmail = '/auth/verify-email';
  static const String googleLogin = '/auth/google';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String health = '/health';

  // Content endpoints
  static const String contents = '/contents';
  static const String contentDetail = '/contents/';

  // User & Social endpoints
  static const String profiles = '/profiles/';
  static const String posts = '/posts';
  static const String workshops = '/workshops';
  static const String subscriptions = '/subscriptions/';
  static const String livekitToken = '/livekit/token';
}
