import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart';

class WeekChartWidget extends StatelessWidget {
  final Map<String, List<dynamic>> buckets;
  final backgroundColor = Colors.grey.shade50;
  final barColor = const Color(0xff82ca9d);

  WeekChartWidget({super.key, required this.buckets});

  @override
  Widget build(BuildContext context) {
    int maxHeight = 0;
    for (var list in buckets.values) {
      if (list.length > maxHeight) {
        maxHeight = list.length;
      }
    }
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            width: 90,
            child: BarChart(
              mainBarData(maxHeight.toDouble()),
            ),
          ),
        ],
      ),
    );
  }

  BarChartData mainBarData(double maxHeight) {
    return BarChartData(
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 20,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getLeftTitles,
            reservedSize: 20,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(maxHeight),
      gridData: const FlGridData(show: false),
    );
  }

  BarChartGroupData makeGroupData(
    int x,
    double y,
    double toY,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor,
          width: 5,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: toY,
            color: backgroundColor,
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> showingGroups(double maxHeight) {
    return List.generate(7, (i) {
      switch (i) {
        case 0:
          return makeGroupData(
              0, buckets['Monday']!.length.toDouble(), maxHeight);
        case 1:
          return makeGroupData(
              1, buckets['Tuesday']!.length.toDouble(), maxHeight);
        case 2:
          return makeGroupData(
              2, buckets['Wednesday']!.length.toDouble(), maxHeight);
        case 3:
          return makeGroupData(
              3, buckets['Thursday']!.length.toDouble(), maxHeight);
        case 4:
          return makeGroupData(
              4, buckets['Friday']!.length.toDouble(), maxHeight);
        case 5:
          return makeGroupData(
              5, buckets['Saturday']!.length.toDouble(), maxHeight);
        case 6:
          return makeGroupData(
              6, buckets['Sunday']!.length.toDouble(), maxHeight);
        default:
          return throw Error();
      }
    });
  }

  Widget getTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: barColor,
      fontSize: 8,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = Text('M', style: style);
        break;
      case 1:
        text = Text('T', style: style);
        break;
      case 2:
        text = Text('W', style: style);
        break;
      case 3:
        text = Text('T', style: style);
        break;
      case 4:
        text = Text('F', style: style);
        break;
      case 5:
        text = Text('S', style: style);
        break;
      case 6:
        text = Text('S', style: style);
        break;
      default:
        text = Text('', style: style);
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 3,
      child: text,
    );
  }

  Widget getLeftTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: barColor,
      fontSize: 8,
    );
    Widget text = Text(value.toInt().toString(), style: style);
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 2,
      child: text,
    );
  }
}
