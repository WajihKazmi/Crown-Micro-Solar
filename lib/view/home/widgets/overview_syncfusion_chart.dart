import 'package:crown_micro_solar/presentation/viewmodels/overview_graph_view_model.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class OverviewSyncfusionChart extends StatelessWidget {
  final OverviewGraphState state;
  final String period; // 'Day', 'Month', 'Year', 'Total' - inferred from labels/state usually, but can be passed helper or derived

   OverviewSyncfusionChart({
    Key? key,
    required this.state,
  }) : period = state.labels.length == 24 && (state.labels.first.contains(':') || state.labels.last.contains(':')) 
      ? 'Day' 
      : 'Other', super(key: key);

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            state.error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (state.labels.isEmpty || state.series.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Prepare data source
    // matching Chartinfo structure from old app: DateTime? and String value
    // We map from state.series to a list of objects or direct mapping
    
    // Check if we are in Day mode (has timestampData)
    final series = state.series.first;
    
    // For Day view, we prefer timestampData if available
    // IMPORTANT: Only use DateTime axis if we have actual timestampData
    final bool hasTimestampData = series.timestampData != null && series.timestampData!.isNotEmpty;
    final bool isDay = period == 'Day' && hasTimestampData;
    
    final List<dynamic> dataSource = hasTimestampData
        ? series.timestampData!
        : List.generate(state.labels.length, (index) {
            return _ChartData(
              state.labels[index],
              series.data.length > index ? series.data[index] : 0.0,
            );
          });
    
    // Debug: print data source info
    print('OverviewSyncfusionChart: period=$period, hasTimestampData=$hasTimestampData, isDay=$isDay, dataSource.length=${dataSource.length}');
    if (dataSource.isNotEmpty) {
      final first = dataSource.first;
      if (first is OverviewGraphDataPoint) {
        print('  First point: ${first.timestamp} -> ${first.value}');
      } else if (first is _ChartData) {
        print('  First point: ${first.label} -> ${first.value}');
      }
    }

    return SafeArea(
      child: SfCartesianChart(
        enableAxisAnimation: true,
        // zoomPanBehavior: ZoomPanBehavior(enablePanning: true), // Matching old app
        tooltipBehavior: TooltipBehavior(
          enable: true,
          header: '',
          format: 'point.y ${state.unit}',
        ),
        trackballBehavior: TrackballBehavior(
          enable: true,
          tooltipSettings: const InteractiveTooltip(
            enable: true,
            color: Colors.white,
            textStyle: TextStyle(color: Colors.black),
          ),
          activationMode: ActivationMode.singleTap,
          markerSettings: const TrackballMarkerSettings(
            markerVisibility: TrackballVisibilityMode.visible,
          ),
        ),
        series: <CartesianSeries>[
          // Area and Spline Series (Only for Day option)
          if (isDay) ...[
            // Area Series
            AreaSeries<dynamic, DateTime>(
              name: 'Power',
              color: Colors.red.withOpacity(0.6),
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.6),
                  Colors.orange.withOpacity(0.2),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              dataSource: dataSource,
              xValueMapper: (dynamic data, _) => data is OverviewGraphDataPoint 
                  ? data.timestamp 
                  : DateTime.now(), // Fallback
              yValueMapper: (dynamic data, _) => data is OverviewGraphDataPoint 
                  ? data.value 
                  : 0.0,
              animationDuration: 1500,
            ),

            // Spline Series for Overlay
            SplineSeries<dynamic, DateTime>(
              splineType: SplineType.natural, // Smooth Line
              name: 'Power Line',
              color: Colors.orange,
              width: 2,
              dataSource: dataSource,
              xValueMapper: (dynamic data, _) => data is OverviewGraphDataPoint 
                  ? data.timestamp 
                  : DateTime.now(),
              yValueMapper: (dynamic data, _) => data is OverviewGraphDataPoint 
                  ? data.value 
                  : 0.0,
              markerSettings: const MarkerSettings(isVisible: false),
              animationDuration: 1500,
            ),
          ] else ...[
             // Bar Series (Only for Month, Year, Total options)
             ColumnSeries<dynamic, String>(
                name: 'Power Column',
                color: Colors.orange,
                dataSource: dataSource,
                xValueMapper: (dynamic data, _) => data is _ChartData ? data.label : '',
                yValueMapper: (dynamic data, _) => data is _ChartData ? data.value : 0.0,
                dataLabelSettings: const DataLabelSettings(isVisible: true, textStyle: TextStyle(fontSize: 10)),
                borderRadius: const BorderRadius.all(Radius.circular(5)),
             ),
          ],
        ],
        primaryXAxis: isDay 
            ? DateTimeAxis(
                majorGridLines: const MajorGridLines(
                  width: 0.5,
                  color: Colors.white30,
                  dashArray: <double>[5, 5],
                ),
                labelStyle: const TextStyle(color: Colors.black54), // Old app had white70 but background was black. Here background is white.
                // Reverting to black for visibility on white card
                dateFormat: DateFormat.Hm(), // HH:mm
                intervalType: DateTimeIntervalType.hours,
            )
            : CategoryAxis(
                majorGridLines: const MajorGridLines(
                  width: 0.5,
                  color: Colors.white30,
                  dashArray: <double>[5, 5],
                ),
                labelStyle: const TextStyle(color: Colors.black54),
                labelPlacement: LabelPlacement.betweenTicks,
            ),
        primaryYAxis: NumericAxis(
          majorGridLines: const MajorGridLines(
            width: 0.5,
            color: Colors.black12, // Adapted for white background
            dashArray: <double>[5, 5],
          ),
          labelStyle: const TextStyle(color: Colors.black54),
          title: AxisTitle(
            text: '${state.unit}',
            textStyle: const TextStyle(
              color: Colors.deepOrange,
              fontFamily: 'Roboto',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        backgroundColor: Colors.transparent, // Let parent container background show
        plotAreaBorderWidth: 0,
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  _ChartData(this.label, this.value);
}
