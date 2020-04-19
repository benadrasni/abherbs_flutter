import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:flutter/material.dart';

import 'flower.dart';

class LegendScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    TextStyle legendTextStyle = TextStyle(
      fontSize: 18.0,
    );

    TextStyle _highlightLegendTextStyle = TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: Colors.lightBlue,
    );


    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).legend),
      ),
      body: ListView(shrinkWrap: true, padding: const EdgeInsets.all(10.0), children: [
        ListTile(
          title: Text(
            S.of(context).toxicity1,
            style: legendTextStyle,
          ),
          leading: Image(
            image: AssetImage('res/images/toxicity1.png'),
            width: 50.0,
            height: 50.0,
          ),
          onTap: () {},
        ),
        ListTile(
          title: Text(
            S.of(context).toxicity2,
            style: legendTextStyle,
          ),
          leading: Image(
            image: AssetImage('res/images/toxicity2.png'),
            width: 50.0,
            height: 50.0,
          ),
          onTap: () {},
        ),
        ListTile(
          title: Text(
            S.of(context).plant_inflorescence,
            style: legendTextStyle,
          ),
          leading: Container( padding: EdgeInsets.all(13.0), child: Image(
            image: AssetImage('res/images/ic_inflorescence_grey_24dp.png'),
            width: 24.0,
            height: 24.0,
          ),),
          onTap: () {},
        ),
        ListTile(
          title: Text(
            S.of(context).plant_flower,
            style: _highlightLegendTextStyle,
          ),
          leading: Container( padding: EdgeInsets.all(13.0), child: Image(
            image: AssetImage('res/images/ic_flower_grey_24dp.png'),
            width: 24.0,
            height: 24.0,
          ),),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FlowerLegendScreen()),
            );
          },
        ),
        ListTile(
          title: Text(
            S.of(context).plant_fruit,
            style: legendTextStyle,
          ),
          leading: Container( padding: EdgeInsets.all(13.0), child: Image(
            image: AssetImage('res/images/ic_fruit_grey_24dp.png'),
            width: 24.0,
            height: 24.0,
          ),),
          onTap: () {},
        ),
        ListTile(
          title: Text(
            S.of(context).plant_leaf,
            style: legendTextStyle,
          ),
          leading: Container( padding: EdgeInsets.all(13.0), child: Image(
            image: AssetImage('res/images/ic_leaf_grey_24dp.png'),
            width: 24.0,
            height: 24.0,
          ),),
          onTap: () {},
        ),
        ListTile(
          title: Text(
            S.of(context).plant_stem,
            style: legendTextStyle,
          ),
          leading: Container( padding: EdgeInsets.all(13.0), child: Image(
            image: AssetImage('res/images/ic_stem_grey_24dp.png'),
            width: 24.0,
            height: 24.0,
          ),),
          onTap: () {},
        ),
        ListTile(
          title: Text(
            S.of(context).plant_habitat,
            style: legendTextStyle,
          ),
          leading: Container( padding: EdgeInsets.all(13.0), child: Image(
            image: AssetImage('res/images/ic_home_grey_24dp.png'),
            width: 24.0,
            height: 24.0,
          ),),
          onTap: () {},
        ),
        ListTile(
          title: Text(
            S.of(context).plant_toxicity,
            style: legendTextStyle,
          ),
          leading: Container( padding: EdgeInsets.all(13.0), child: Image(
            image: AssetImage('res/images/ic_toxicity_grey_24dp.png'),
            width: 24.0,
            height: 24.0,
          ),),
          onTap: () {},
        ),
        ListTile(
          title: Text(
            S.of(context).plant_herbalism,
            style: legendTextStyle,
          ),
          leading: Container( padding: EdgeInsets.all(13.0), child: Image(
            image: AssetImage('res/images/ic_local_pharmacy_grey_24dp.png'),
            width: 24.0,
            height: 24.0,
          ),),
          onTap: () {},
        ),
        ListTile(
          title: Text(
            S.of(context).plant_trivia,
            style: legendTextStyle,
          ),
          leading: Container( padding: EdgeInsets.all(13.0), child: Image(
            image: AssetImage('res/images/ic_question_mark_grey_24dp.png'),
            width: 24.0,
            height: 24.0,
          ),),
          onTap: () {},
        ),
      ]),
    );
  }
}
