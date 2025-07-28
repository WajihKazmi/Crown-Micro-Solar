import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_live_signal_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_data_one_day_query_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_key_parameter_model.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  String selectedParameter = 'AC2 Output Voltage';
  DateTime selectedDate = DateTime.now();
  bool isGraphExpanded = true;
  
  // Live data
  DeviceLiveSignalModel? _liveSignalData;
  DeviceDataOneDayQueryModel? _deviceData;
  DeviceKeyParameterModel? _powerGenerationData;
  DeviceKeyParameterModel? _batteryData;
  DeviceKeyParameterModel? _loadData;
  DeviceKeyParameterModel? _gridData;
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
  }

  Future<void> _loadDeviceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deviceViewModel = context.read<DeviceViewModel>();
      
      // Load live signal data
      final liveSignal = await deviceViewModel.fetchDeviceLiveSignal(
        sn: widget.device.sn,
        pn: widget.device.pn,
        devcode: widget.device.devcode,
        devaddr: widget.device.devaddr,
      );
      
      // Load device data for one day
      final deviceData = await deviceViewModel.fetchDeviceDataOneDay(
        sn: widget.device.sn,
        pn: widget.device.pn,
        devcode: widget.device.devcode,
        devaddr: widget.device.devaddr,
        date: selectedDate.toString().split(' ')[0],
      );
      
      // Load key parameters for summary cards
      final powerGeneration = await deviceViewModel.fetchDeviceKeyParameterOneDay(
        sn: widget.device.sn,
        pn: widget.device.pn,
        devcode: widget.device.devcode,
        devaddr: widget.device.devaddr,
        parameter: 'PV_OUTPUT_POWER',
        date: selectedDate.toString().split(' ')[0],
      );
      
      final battery = await deviceViewModel.fetchDeviceKeyParameterOneDay(
        sn: widget.device.sn,
        pn: widget.device.pn,
        devcode: widget.device.devcode,
        devaddr: widget.device.devaddr,
        parameter: 'BATTERY_SOC',
        date: selectedDate.toString().split(' ')[0],
      );
      
      final load = await deviceViewModel.fetchDeviceKeyParameterOneDay(
        sn: widget.device.sn,
        pn: widget.device.pn,
        devcode: widget.device.devcode,
        devaddr: widget.device.devaddr,
        parameter: 'LOAD_POWER',
        date: selectedDate.toString().split(' ')[0],
      );
      
      final grid = await deviceViewModel.fetchDeviceKeyParameterOneDay(
        sn: widget.device.sn,
        pn: widget.device.pn,
        devcode: widget.device.devcode,
        devaddr: widget.device.devaddr,
        parameter: 'GRID_POWER',
        date: selectedDate.toString().split(' ')[0],
      );

      if (mounted) {
        setState(() {
          _liveSignalData = liveSignal;
          _deviceData = deviceData;
          _powerGenerationData = powerGeneration;
          _batteryData = battery;
          _loadData = load;
          _gridData = grid;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatPower(double? power) {
    if (power == null) return '0.0 kW';
    return '${(power / 1000).toStringAsFixed(1)} kW';
  }

  String _formatBattery(double? soc) {
    if (soc == null) return '0%';
    return '${soc.toStringAsFixed(0)}%';
  }

  String _getLastUpdatedTime() {
    if (_liveSignalData?.timestamp != null) {
      final time = _liveSignalData!.timestamp!;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.hour < 12 ? 'AM' : 'PM'}';
    }
    return '8:19 PM'; // Default fallback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
                        SliverAppBar(
                expandedHeight: 0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'SN Device Details',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Image.asset('assets/icons/download_report.png', width: 20),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Image.asset('assets/icons/download_report1.png', width: 20),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.grey[600], size: 20),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Stack(
                      children: [
                        Icon(Icons.notifications_none, color: Colors.grey[600], size: 20),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading 
                ? _buildLoadingState()
                : _error != null 
                  ? _buildErrorState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Energy System Diagram
                        _buildEnergySystemDiagram(),
                        SizedBox(height: 24),
                        
                        // Summary Cards
                        _buildSummaryCards(),
                        SizedBox(height: 24),
                        
                        // Voltage Graph
                        _buildVoltageGraph(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading device data...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error: $_error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDeviceData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergySystemDiagram() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Energy System Diagram
          Container(
            height: 180,
            child: Stack(
              children: [
                // Battery (left side - tall white rectangular device)
                Positioned(
                  left: 20,
                  bottom: 30,
                  child: Container(
                    width: 30,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[400]!, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        // Grey top
                        Container(
                          width: 30,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                        // Main battery area
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Grey bottom
                        Container(
                          width: 30,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // House (center - beige with brown door and solar panels on roof)
                Positioned(
                  left: 100,
                  bottom: 30,
                  child: Column(
                    children: [
                      // Solar panels on roof (two rows)
                      Row(
                        children: List.generate(3, (index) => 
                          Container(
                            width: 20,
                            height: 12,
                            margin: EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[400],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: List.generate(3, (index) => 
                          Container(
                            width: 20,
                            height: 12,
                            margin: EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[400],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      // House
                      Container(
                        width: 80,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F5DC), // Beige color
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[400]!, width: 1),
                        ),
                        child: Stack(
                          children: [
                            // Door
                            Positioned(
                              bottom: 0,
                              left: 25,
                              child: Container(
                                width: 30,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Colors.brown[600],
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(3),
                                    topRight: Radius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Central Crown device (attached to house)
                Positioned(
                  right: 20,
                  bottom: 30,
                  child: Container(
                    width: 60,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        // Red top section with Crown logo
                        Container(
                          width: 60,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'CROWN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Grey bottom section
                        Expanded(
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(6),
                                bottomRight: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Grid connection (utility pole)
                Positioned(
                  right: 90,
                  bottom: 30,
                  child: Column(
                    children: [
                      // Power lines
                      Container(
                        width: 40,
                        height: 2,
                        color: Colors.black,
                      ),
                      SizedBox(height: 4),
                      // Utility pole
                      Container(
                        width: 4,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Small blue device (bottom right of house)
                Positioned(
                  right: 70,
                  bottom: 20,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
                ),
                
                // Energy flow lines (yellow lines)
                // Solar panels to Crown device
                Positioned(
                  left: 140,
                  bottom: 100,
                  child: Container(
                    width: 2,
                    height: 20,
                    color: Colors.yellow,
                  ),
                ),
                // Battery to Crown device
                Positioned(
                  left: 50,
                  bottom: 55,
                  child: Container(
                    width: 50,
                    height: 2,
                    color: Colors.yellow,
                  ),
                ),
                // Crown device to Grid
                Positioned(
                  right: 80,
                  bottom: 55,
                  child: Container(
                    width: 20,
                    height: 2,
                    color: Colors.yellow,
                  ),
                ),
                // Crown device to Blue device
                Positioned(
                  right: 70,
                  bottom: 55,
                  child: Container(
                    width: 2,
                    height: 15,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
          ),
          
          // Last updated
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LAST UPDATED',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '8:19 PM',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    // Extract values from API data
    final powerGenerationValue = _powerGenerationData?.dat?.row?.firstOrNull?.field?.firstOrNull?.toString() ?? '1.0';
    final batteryValue = _batteryData?.dat?.row?.firstOrNull?.field?.firstOrNull?.toString() ?? '99';
    final loadValue = _loadData?.dat?.row?.firstOrNull?.field?.firstOrNull?.toString() ?? '1.0';
    final gridValue = _gridData?.dat?.row?.firstOrNull?.field?.firstOrNull?.toString() ?? '1.0';

    final cards = [
      {
        'title': 'Power Generation', 
        'value': '${_formatPower(double.tryParse(powerGenerationValue))} kW', 
        'icon': Icons.solar_power, 
        'color': Colors.red
      },
      {
        'title': 'Battery', 
        'value': '${_formatBattery(double.tryParse(batteryValue))}%', 
        'icon': Icons.battery_full, 
        'color': Colors.red
      },
      {
        'title': 'Load', 
        'value': '${_formatPower(double.tryParse(loadValue))} kW', 
        'icon': Icons.home, 
        'color': Colors.red
      },
      {
        'title': 'Grid', 
        'value': '${_formatPower(double.tryParse(gridValue))} kW', 
        'icon': Icons.power, 
        'color': Colors.red
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards.map((card) => Container(
          width: 100,
          margin: EdgeInsets.only(right: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(card['icon'] as IconData, color: card['color'] as Color, size: 20),
              SizedBox(height: 6),
              Text(
                card['title'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                card['value'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildVoltageGraph() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parameter dropdown
          Row(
            children: [
              Expanded(
                child: Text(
                  'AC2 Output Voltage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[600],
              ),
            ],
          ),
          
          if (isGraphExpanded) ...[
            SizedBox(height: 16),
            
            // Date navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.arrow_left, color: Colors.black54),
                Text(
                  'June 2024',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Icon(Icons.arrow_right, color: Colors.black54),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Graph placeholder (you mentioned to skip the graph)
            Container(
              height: 200,
              child: Center(
                child: Text(
                  'Graph data will be implemented separately',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class EnergyFlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Solar to inverter
    canvas.drawLine(Offset(80, 20), Offset(120, 40), paint);
    
    // Inverter to battery
    canvas.drawLine(Offset(120, 40), Offset(50, 60), paint);
    
    // Inverter to load
    canvas.drawLine(Offset(120, 40), Offset(150, 60), paint);
    
    // Inverter to grid
    canvas.drawLine(Offset(120, 40), Offset(180, 40), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 