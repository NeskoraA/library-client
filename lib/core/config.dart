const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

const inactivityTimeout = Duration(
  seconds: int.fromEnvironment('INACTIVITY_SECONDS', defaultValue: 180),
);

const inactivityWarning = Duration(seconds: 30);

const sessionMaxDuration = Duration(
  minutes: int.fromEnvironment('SESSION_MAX_MINUTES', defaultValue: 60),
);
