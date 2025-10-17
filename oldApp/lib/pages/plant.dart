
import 'package:crownmonitor/pages/plantinformation.dart';
import 'package:flutter/material.dart';

import '../Models/Powerstation_Query_Response.dart';
import 'list.dart';

class Plant extends StatefulWidget {
  int? passedindex;
  bool? collector_callback;
  //plantinfoqueryvariables
 
  String? Plantname, Plant_status, PlantID, Country, province, City, County, town, village, address, lon, lat, timezone, Unitprofit, currency, coalsaved, so2emission, co2emission, DesignCompany, picbig, picsmall;

  double? DesignPower;
  double? Annual_Planned_Power;
  DateTime? installed_date;

  int? Average_troublefree_operationtime;
  int? Continuous_troublefree_operationtime;

  Plant({Key? key, this.collector_callback, this.passedindex, this.Plantname, this.Plant_status, this.Country, this.province, this.City, this.County, this.town, this.village, this.address, this.lon, this.lat, this.timezone, this.Unitprofit, this.currency, this.coalsaved, this.so2emission, this.co2emission, this.DesignPower, this.DesignCompany, this.Annual_Planned_Power, this.Average_troublefree_operationtime, this.Continuous_troublefree_operationtime, this.installed_date, this.picbig, this.picsmall, this.PlantID}) : super(key: key);

  @override
  _PlantState createState() => _PlantState();
}

class _PlantState extends State<Plant> {

  bool isLoading = false;

  TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Overide data to single plant otherwise it will come from list.dart plant list page
    loadPlant();
  }

  Future<void> loadPlant() async {
    setState(() { isLoading = !isLoading; });

    final data = await ListofPowerStationQuery(context, status: 5, orderby: 'ascPlantName', Plantname: '');

    Response result = Response.fromJson(data);

    final PSINFO = result.dat?.plant?[0];

    widget.PlantID = PSINFO!.pid.toString();
    widget.Plantname = PSINFO.name;
    widget.Plant_status = PSINFO.status.toString();
    widget.Country = PSINFO.address?.country;
    widget.province = PSINFO.address?.province;
    widget.City = PSINFO.address?.city;
    widget.County = PSINFO.address?.country;
    widget.town = PSINFO.address?.town;
    widget.village = PSINFO.address?.village;
    widget.address = PSINFO.address?.address;
    widget.lon = PSINFO.address?.lon;
    widget.lat = PSINFO.address?.lat;
    widget.timezone = PSINFO.address?.timezone.toString();
    widget.Unitprofit = PSINFO.profit?.unitProfit;
    widget.currency = PSINFO.profit?.currency;
    widget.coalsaved = PSINFO.profit?.coal;
    widget.so2emission = PSINFO.profit?.so2;
    widget.co2emission = PSINFO.profit?.co2;
    widget.DesignPower = double.parse(PSINFO.nominalPower!);
    widget.Annual_Planned_Power = double.parse(PSINFO.energyYearEstimate!);
    widget.DesignCompany = PSINFO.designCompany;
    widget.picsmall = PSINFO.picBig;
    widget.installed_date = PSINFO.install;

    setState(() { isLoading = !isLoading; });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: !isLoading ? Center(
        child: PlantInformation(PID: widget.PlantID, Plantname: widget.Plantname, Plant_status: widget.Plant_status, Country: widget.Country, province: widget.province, City: widget.City, County: widget.County, town: widget.town, village: widget.village, address: widget.address, lon: widget.lon, lat: widget.lat, timezone: widget.timezone, Unitprofit: widget.Unitprofit, currency: widget.currency, coalsaved: widget.coalsaved, so2emission: widget.so2emission, co2emission: widget.co2emission, DesignPower: widget.DesignPower, Annual_Planned_Power: widget.Annual_Planned_Power, DesignCompany: widget.DesignCompany, picsmall: widget.picsmall, installed_date: widget.installed_date),
      ): Center(child: CircularProgressIndicator()),
      
    );
  }
}
