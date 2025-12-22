import 'package:crown_micro_solar/presentation/viewmodels/overview_graph_view_model.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class OverviewSyncfusionChart extends StatelessWidget {
  final OverviewGraphState state;
  final String
      period; // 'Day', 'Month', 'Year', 'Total' - inferred from labels/state usually, but can be passed helper or derived

  OverviewSyncfusionChart({
    Key? key,
    required this.state,
  })  : period = state.labels.length == 24 &&
                (state.labels.first.contains(':') ||
                    state.labels.last.contains(':'))
            ? 'Day'
            : 'Other',
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // CRITICAL: Don't render chart until data is actually loaded
    // This prevents incorrect Y-axis scaling with default values
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
    // Ensure we have actual data before rendering the chart
    if (state.labels.isEmpty ||
        state.series.isEmpty ||
        state.series.first.data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Prepare data source
    final series = state.series.first;

    // IMPORTANT: Only use DateTime axis if we have actual timestampData
    final bool hasTimestampData =
        series.timestampData != null && series.timestampData!.isNotEmpty;
    final bool isDay = period == 'Day' && hasTimestampData;

    final List<dynamic> dataSource = hasTimestampData
        ? series.timestampData!
        : List.generate(state.labels.length, (index) {
            return _ChartData(
              state.labels[index],
              series.data.length > index ? series.data[index] : 0.0,
            );
          });

    // Debug: print data source info with full detail
    print(
        'OverviewSyncfusionChart: period=$period, hasTimestampData=$hasTimestampData, isDay=$isDay, dataSource.length=${dataSource.length}');
    if (dataSource.isNotEmpty) {
      final first = dataSource.first;
      final last = dataSource.last;
      if (first is OverviewGraphDataPoint) {
        print('  First point: ${first.timestamp} -> ${first.value}');
        print(
            '  Last point: ${last is OverviewGraphDataPoint ? "${(last as OverviewGraphDataPoint).timestamp} -> ${(last as OverviewGraphDataPoint).value}" : "N/A"}');
        print('  Total timestamp points: ${series.timestampData?.length ?? 0}');
        // Show min/max values for verification
        final values = series.timestampData!.map((p) => p.value).toList();
        final minVal = values.reduce((a, b) => a < b ? a : b);
        final maxVal = values.reduce((a, b) => a > b ? a : b);
        print('  Value range: $minVal to $maxVal ${state.unit}');
      } else if (first is _ChartData) {
        print('  First point: ${first.label} -> ${first.value}');
        print(
            '  Last point: ${last is _ChartData ? "${(last as _ChartData).label} -> ${(last as _ChartData).value}" : "N/A"}');
      }
    }

    // Capture data for trackball builder (builder closures can't access outer scope easily)
    final capturedDataSource = dataSource;
    final capturedUnit = state.unit;
    final capturedIsDay = isDay;

    return SfCartesianChart(
      enableAxisAnimation: true,
      tooltipBehavior: TooltipBehavior(
        enable: false, // Disabled - using trackballBehavior instead
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        tooltipDisplayMode: TrackballDisplayMode
            .nearestPoint, // Changed from groupAllPoints to fix xValue=null
        tooltipSettings: InteractiveTooltip(
          enable: true,
          color: Colors.white,
          textStyle: TextStyle(color: Colors.black),
        ),
        activationMode: ActivationMode.singleTap,
        markerSettings: const TrackballMarkerSettings(
          markerVisibility: TrackballVisibilityMode.visible,
        ),
        lineType: TrackballLineType.vertical,
        builder: (BuildContext context, TrackballDetails trackballDetails) {
          // Custom tooltip showing timestamp and value
          final xValue = trackballDetails.point?.x;

          // Get Y value from the captured data source
          // Note: pointIndex is null in groupAllPoints mode, so we search by X value
          double yValue = 0.0;

          if (xValue != null && capturedDataSource.isNotEmpty) {
            // Search for matching data point by X value
            for (var point in capturedDataSource) {
              bool matches = false;

              if (point is OverviewGraphDataPoint && xValue is DateTime) {
                // For timestamp data, compare DateTime (match by hour and minute)
                matches = point.timestamp.year == xValue.year &&
                    point.timestamp.month == xValue.month &&
                    point.timestamp.day == xValue.day &&
                    point.timestamp.hour == xValue.hour &&
                    point.timestamp.minute == xValue.minute;
                if (matches) {
                  yValue = point.value;
                  break;
                }
              } else if (point is _ChartData) {
                // For categorical data, compare label
                matches = point.label == xValue.toString();
                if (matches) {
                  yValue = point.value;
                  break;
                }
              }
            }
          }

          // Fallback to trackballDetails.point.y if we couldn't find a match
          if (yValue == 0.0 && trackballDetails.point?.y != null) {
            yValue = trackballDetails.point!.y as double;
          }

          print(
              'DEBUG Tooltip: xValue=$xValue, found yValue=$yValue, unit=$capturedUnit');

          String timeLabel;
          if (xValue is DateTime) {
            // Format DateTime as HH:mm
            timeLabel =
                '${xValue.hour.toString().padLeft(2, '0')}:${xValue.minute.toString().padLeft(2, '0')}';
          } else {
            // For non-DateTime X axis (month/year labels)
            timeLabel = xValue?.toString() ?? '';
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${yValue.toStringAsFixed(2)} $capturedUnit',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      series: <CartesianSeries>[
        // Area Series with gradient fill (water effect)
        AreaSeries<dynamic, dynamic>(
          name: 'Power',
          color: primaryColor.withOpacity(0.3),
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.5),
              primaryColor.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          dataSource: dataSource,
          xValueMapper: (dynamic data, _) {
            if (data is OverviewGraphDataPoint) {
              return data.timestamp;
            } else if (data is _ChartData) {
              return data.label;
            }
            return isDay ? DateTime.now() : '';
          },
          yValueMapper: (dynamic data, _) {
            if (data is OverviewGraphDataPoint) {
              return data.value;
            } else if (data is _ChartData) {
              return data.value;
            }
            return 0.0;
          },
          animationDuration: 1500,
          enableTooltip:
              false, // Hide from trackball to prevent duplicate tooltips
        ),

        // Smooth curved line overlay
        SplineSeries<dynamic, dynamic>(
          splineType: SplineType.natural,
          name: 'Power Line',
          color: primaryColor,
          width: 2.5,
          dataSource: dataSource,
          xValueMapper: (dynamic data, _) {
            if (data is OverviewGraphDataPoint) {
              return data.timestamp;
            } else if (data is _ChartData) {
              return data.label;
            }
            return isDay ? DateTime.now() : '';
          },
          yValueMapper: (dynamic data, _) {
            if (data is OverviewGraphDataPoint) {
              return data.value;
            } else if (data is _ChartData) {
              return data.value;
            }
            return 0.0;
          },
          markerSettings: MarkerSettings(
            isVisible: false, // Hide markers for smooth line appearance
            height: 6,
            width: 6,
            color: primaryColor,
            borderColor: Colors.white,
            borderWidth: 2,
            shape: DataMarkerType.circle,
          ),
          animationDuration: 1500,
        ),
      ],
      primaryXAxis: isDay
          ? DateTimeAxis(
              majorGridLines: MajorGridLines(
                width: 0.5,
                color: theme.dividerColor.withOpacity(0.3),
                dashArray: <double>[5, 5],
              ),
              labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
              dateFormat: DateFormat.Hm(),
              intervalType: DateTimeIntervalType.hours,
              desiredIntervals: 12, // Show ~12 time labels (every 2 hours)
              edgeLabelPlacement: EdgeLabelPlacement.shift,
            )
          : CategoryAxis(
              majorGridLines: MajorGridLines(
                width: 0.5,
                color: theme.dividerColor.withOpacity(0.3),
                dashArray: <double>[5, 5],
              ),
              labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
              labelPlacement: LabelPlacement.betweenTicks,
            ),
      primaryYAxis: NumericAxis(
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: theme.dividerColor.withOpacity(0.2),
          dashArray: <double>[5, 5],
        ),
        labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
        title: AxisTitle(
          text: '${state.unit}',
          textStyle: TextStyle(
            color: primaryColor,
            fontFamily: 'Roboto',
            fontSize: 12,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  _ChartData(this.label, this.value);
}
