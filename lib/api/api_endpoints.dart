class ApiEndpoints {
  static const String baseUrl = "http://api.dessmonitor.com/public/?sign=";
  
  // Auth endpoints
  static const String login = "&action=login";
  static const String register = "&action=reg";
  static const String verify = "&action=verify";
  
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
  
  // New endpoints
  static const String webQueryPlants = "&action=webQueryPlants";
  static const String webQueryDeviceEs = "&action=webQueryDeviceEs";
  static const String webQueryPlantsWarning = "&action=webQueryPlantsWarning";
  static const String queryPlantActiveOuputPowerOneDay = "&action=queryPlantActiveOuputPowerOneDay";
  static const String queryPlantsProfitStatisticOneDay = "&action=queryPlantsProfitStatisticOneDay";
  static const String queryDeviceParsEs = "&action=queryDeviceParsEs";
  static const String queryDeviceCtrlField = "&action=queryDeviceCtrlField";
  static const String queryDeviceDataOneDayPaging = "&action=queryDeviceDataOneDayPaging";
  static const String addCollectorEs = "&action=addCollectorEs";
  static const String delCollectorFromPlant = "&action=delCollectorFromPlant";
  static const String editCollector = "&action=editCollector";
  static const String delDeviceFromPlant = "&action=delDeviceFromPlant";
  static const String ignorePlantWarning = "&action=ignorePlantWarning";
} 