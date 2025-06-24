class ApiEndpoints {
  static const String baseUrl = "https://apis.crown-micro.net/";
  
  // Auth endpoints
  static const String login = "api/MonitoringApp/Login";
  static const String register = "api/MonitoringApp/Register";
  static const String verify = "api/MonitoringApp/Verify";
  
  // Plant endpoints
  static const String createPowerStation = "api/MonitoringApp/CreatePowerStation";
  static const String getPlants = "api/MonitoringApp/GetPlants";
  static const String getPlantDetails = "api/MonitoringApp/GetPlantDetails";
  
  // Device endpoints
  static const String getDevices = "api/MonitoringApp/GetDevices";
  static const String getDeviceStatus = "api/MonitoringApp/GetDeviceStatus";
  static const String getDeviceData = "api/MonitoringApp/GetDeviceData";
  
  // Energy endpoints
  static const String getDailyGeneration = "api/MonitoringApp/GetDailyGeneration";
  static const String getMonthlyGeneration = "api/MonitoringApp/GetMonthlyGeneration";
  static const String getYearlyGeneration = "api/MonitoringApp/GetYearlyGeneration";
  
  // Alarm endpoints
  static const String getAlarms = "api/MonitoringApp/GetAlarms";
  static const String getWarnings = "api/MonitoringApp/GetWarnings";
  
  // Legacy DESS Monitor endpoints (for reference, not used in new implementation)
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