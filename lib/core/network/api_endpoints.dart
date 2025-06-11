class ApiEndpoints {
  // Authentication API endpoints
  static const String authBaseUrl = 'https://apis.crown-micro.net/api/MonitoringApp';
  static const String login = '/Login';
  static const String register = '/Register';
  static const String verifyShortCode = '/VerifyShortCode';
  static const String pushShortCode = '/PushShortCode';
  static const String updatePassword = '/UpdatePassword';
  static const String getUserID = '/GetUserID';
  static const String updateAgentCode = '/UpdateAgentCode';
  static const String deactivateAccount = '/DeactivateAccount';

  // Monitor API endpoints
  static const String monitorBaseUrl = 'http://api.dessmonitor.com/public';
  
  // Monitor API actions (tested and correct)
  static const String webQueryPlants = '&action=webQueryPlants';
  static const String webQueryDeviceEs = '&action=webQueryDeviceEs';
  static const String webQueryPlantsWarning = '&action=webQueryPlantsWarning';
  static const String queryPlantActiveOuputPowerOneDay = '&action=queryPlantActiveOuputPowerOneDay';
  static const String queryPlantsProfitStatisticOneDay = '&action=queryPlantsProfitStatisticOneDay';
  static const String queryDeviceParsEs = '&action=queryDeviceParsEs';
  static const String queryDeviceCtrlField = '&action=queryDeviceCtrlField';
  static const String queryDeviceDataOneDayPaging = '&action=queryDeviceDataOneDayPaging';
  static const String addCollectorEs = '&action=addCollectorEs';
  static const String delCollectorFromPlant = '&action=delCollectorFromPlant';
  static const String editCollector = '&action=editCollector';
  static const String delDeviceFromPlant = '&action=delDeviceFromPlant';
  static const String ignorePlantWarning = '&action=ignorePlantWarning';
  
  // API Key
  static const String apiKey = 'C5BFF7F0-B4DF-475E-A331-F737424F013C';
  
  // Plant endpoints
  static const String createPowerStation = "&action=reg";
  static const String getPlants = "&action=queryPlantList";
  static const String getPlantDetails = "&action=queryPlantCurrentData";
  
  // Device endpoints
  static const String getDevices = "&action=queryDeviceList";
  static const String getDeviceStatus = "&action=queryDeviceStatus";
  static const String getDeviceData = "&action=queryDeviceData";
  
  // Energy endpoints
  static const String getDailyGeneration = "&action=queryDeviceEnergyDay";
  static const String getMonthlyGeneration = "&action=queryDeviceEnergyMonth";
  static const String getYearlyGeneration = "&action=queryDeviceEnergyYear";
  
  // Alarm endpoints
  static const String getAlarms = "&action=queryAlarms";
  static const String getWarnings = "&action=queryPlantWarning";
} 