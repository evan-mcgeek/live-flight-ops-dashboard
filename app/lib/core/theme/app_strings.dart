// Centralized UI copy — every static label/title/message in the app, so
// none of it is scattered as inline string literals in widgets. Runtime
// value formatting (units, timestamps, computed labels) stays local to the
// widget producing it; this class holds copy only.
class AppStrings {
  const AppStrings._();

  // Nav
  static const navMap = 'Map';
  static const navList = 'List';
  static const navSettings = 'Settings';

  // Shared error state
  static const somethingWentWrong = 'Something went wrong';
  static const tryAgain = 'Try again';
  static const errorLoadingAircraft =
      'We hit an unexpected error loading aircraft. Please try again.';
  static const errorLoadingDetail =
      "We couldn't load this aircraft. Please try again.";

  // Live status chip
  static const connecting = 'Connecting…';
  static const connected = 'Connected';
  static const error = 'Error';
  static const live = 'Live';

  // Splash
  static const connectingToLiveFeed = 'Connecting to live traffic feed…';
  static const appNameEyebrow = 'LIVE FLIGHT OPS';
  static const appNameWordmark = 'Dashboard';

  // Settings page
  static const settingsTitle = 'Settings';
  static const appearance = 'APPEARANCE';
  static const theme = 'Theme';
  static const themeDark = 'Dark';
  static const themeLight = 'Light';
  static const dataSource = 'DATA SOURCE';
  static const connection = 'Connection';
  static const snapshotInterval = 'Snapshot interval';
  static const pushLive = 'push · live';
  static const liveUpdates = 'LIVE UPDATES';
  static const modeStandard = 'Standard';
  static const modeRealtime = 'Real-time';
  static const modeStandardDescription =
      'Standard polls a fresh snapshot every few seconds — lighter on battery and network.';
  static const modeRealtimeDescription =
      'Real-time keeps a push connection open, streaming position updates the moment they arrive.';
  static const updateInterval = 'UPDATE INTERVAL';
  static const saveAndRestart = 'Save & restart';

  // Aircraft list page
  static const aircraftListTitle = 'Aircraft';
  static const searchHint = 'Search callsign or country';
  static const noAircraftInArea = 'No aircraft in this area';
  static const onGroundTrailing = 'ground';

  // Stale data banner
  static const staleSnapshot = 'Cached snapshot · live feed unavailable';

  // Aircraft detail page
  static const aircraftNotFound = 'Aircraft not found';
  static const onGround = 'On ground';
  static const airborne = 'Airborne';
  static const labelAltitude = 'Altitude';
  static const labelVelocity = 'Velocity';
  static const labelHeading = 'Heading';
  static const labelIcao24 = 'ICAO24 address';
  static const labelOriginCountry = 'Origin country';
  static const labelOnGround = 'On ground';
  static const labelPosition = 'Position';
  static const labelLastUpdate = 'Last update';
}
