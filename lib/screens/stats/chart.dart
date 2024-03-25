import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HskChart extends StatelessWidget {
  final List<Map<String, dynamic>>? timelineList;
  final int numDays;
  const HskChart({Key? key, this.timelineList, required this.numDays}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
        mainData(timelineList: timelineList, numDays: numDays)
    );
  }
}

List<Color> gradientColors = [
  Colors.cyan,
  Colors.blue,
];

LineChartData mainData({List<Map<String, dynamic>>? timelineList, required int numDays}) {
  List<FlSpot> flSpots = [];
  double maxY = 0;
  int timelineListIndex = 0;
  if(timelineList != null){
    final today = DateTime.timestamp();
    for (int i = 1; i < numDays+1; i++) {
      double x = -1;
      if(timelineListIndex < timelineList.length){
        DateTime date = DateTime.parse(timelineList[timelineListIndex]["string_date"]);
        x = numDays - daysBetween(date, today);
      }
      if (x == i){
        double value = timelineList[timelineListIndex]["total"].toDouble();
        flSpots.add(FlSpot(x-1, value));
        if (value > maxY){ maxY = value;}
        timelineListIndex++;
      }else{
        flSpots.add(FlSpot(i.toDouble()-1, 0));
      }
    }
    maxY++;
    maxY =( (maxY / 10).ceil() * 10);
    if(timelineList.isEmpty  || timelineList[0]["string_date"] == "2022-10-26"){
      maxY = 0;
    }
  }
  return LineChartData(
    gridData: FlGridData(
      show: false,
    ),
    titlesData: FlTitlesData(
      show: true,
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),

      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),

      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: bottomTitleWidgets,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: leftTitleWidgets,
          reservedSize: 35,
        ),
      ),
    ),
    borderData: FlBorderData(
      show: false,
      border: Border.all(color: const Color(0xff37434d)),
    ),
    minX: 0,
    maxX: numDays.toDouble()-1,
    minY: 0,
    maxY: maxY,
    lineBarsData: [
      LineChartBarData(
        spots: flSpots,
        isCurved: false,
        gradient: LinearGradient(
          colors: gradientColors,
        ),
        barWidth: 5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: false,
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: gradientColors
                .map((color) => color.withOpacity(0.3))
                .toList(),
          ),
        ),
      ),
    ],
  );
}


Widget leftTitleWidgets(double value, TitleMeta meta) {
  double max = meta.max;
  const style = TextStyle(
    //fontWeight: FontWeight.bold,
    fontSize: 15,
  );
  String text;
  if (max < 1){
    return const Text("10", style: TextStyle(color: Colors.transparent), textAlign: TextAlign.left);
  } else if (value == max){
    text = "${max.toInt()}";
  }else if(value == max * 2~/3){
    text = "${max * 2~/3}";
  }else if(value == max * 1~/3){
    text = "${max * 1~/3}";
  } else if (value == 0 ){
    text = "0";
  }
  else{return Container();}

  return Text(text, style: style, textAlign: TextAlign.left);
}



Widget bottomTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(
    //fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  Widget text;
  switch (value.toInt()) {
    case 0:
      text = const Text('0', style: style);
      break;
    case 1:
      text = const Text('1', style: style);
      break;
    case 2:
      text = const Text('2', style: style);
      break;
    case 3:
      text = const Text('3', style: style);
      break;
    case 4:
      text = const Text('4', style: style);
      break;
    case 5:
      text = const Text('5', style: style);
      break;
    case 6:
      text = const Text('6', style: style);
      break;
    case 7:
      text = const Text('7', style: style);
      break;
    case 8:
      text = const Text('8', style: style);
      break;
    default:
      text = const Text('', style: style);
      break;
  }

  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: text,
  );
}

double daysBetween(DateTime from, DateTime to) {
  from = DateTime(from.year, from.month, from.day);
  to = DateTime(to.year, to.month, to.day);
  return (to.difference(from).inHours / 24).round().toDouble();
}