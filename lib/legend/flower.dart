import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:flutter/material.dart';

class FlowerLegendScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextStyle legendTextStyle = TextStyle(
      fontSize: 18.0,
    );
    double screenWidth = MediaQuery.of(context).size.width - 20;

    List<Widget> legends = [];
    legends.addAll([
      S.of(context).legend_flower_1,
      S.of(context).legend_flower_2,
      S.of(context).legend_flower_3,
      S.of(context).legend_flower_4,
      S.of(context).legend_flower_5,
      S.of(context).legend_flower_6,
      S.of(context).legend_flower_7,
      S.of(context).legend_flower_8,
      S.of(context).legend_flower_9,
      S.of(context).legend_flower_10,
      S.of(context).legend_flower_11,
      S.of(context).legend_flower_12,
      S.of(context).legend_flower_13,
      S.of(context).legend_flower_14,
      S.of(context).legend_flower_15,
      S.of(context).legend_flower_16,
      S.of(context).legend_flower_17
    ].asMap().entries.map((entry) {
      return ListTile(
        title: Text(
          entry.value,
          style: legendTextStyle,
        ),
        leading: Text(
          (entry.key + 1).toString(),
          style: legendTextStyle,
        ),
      );
    }));

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).plant_flower),
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(10.0),
          child: Image(
            image: AssetImage('res/images/Mature_flower_numbered.webp'),
            width: screenWidth,
            fit: BoxFit.fitWidth,
          ),
        ),
        Expanded(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(10.0),
            children: legends,
          ),
        )
      ]),
    );
  }
}
