import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:flutter/material.dart';

class InflorescenceLegendScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _InflorescenceItem('res/images/inflorescence_raceme.webp', S.of(context).legend_inflorescence_raceme),
      _InflorescenceItem('res/images/inflorescence_spike.webp', S.of(context).legend_inflorescence_spike),
      _InflorescenceItem('res/images/inflorescence_spadix.webp', S.of(context).legend_inflorescence_spadix),
      _InflorescenceItem('res/images/inflorescence_corymb.webp', S.of(context).legend_inflorescence_corymb),
      _InflorescenceItem('res/images/inflorescence_umbel.webp', S.of(context).legend_inflorescence_umbel),
      _InflorescenceItem('res/images/inflorescence_compound_umbel.webp', S.of(context).legend_inflorescence_compound_umbel),
      _InflorescenceItem('res/images/inflorescence_capitulum.webp', S.of(context).legend_inflorescence_capitulum),
      _InflorescenceItem('res/images/inflorescence_head.webp', S.of(context).legend_inflorescence_head),
      _InflorescenceItem('res/images/inflorescence_panicle.webp', S.of(context).legend_inflorescence_panicle),
      _InflorescenceItem('res/images/inflorescence_compound_spike.webp', S.of(context).legend_inflorescence_compound_spike),
      _InflorescenceItem('res/images/inflorescence_cyme.webp', S.of(context).legend_inflorescence_cyme),
      _InflorescenceItem('res/images/inflorescence_helicoid.webp', S.of(context).legend_inflorescence_helicoid),
      _InflorescenceItem('res/images/inflorescence_rhipidium.webp', S.of(context).legend_inflorescence_rhipidium),
      _InflorescenceItem('res/images/inflorescence_scorpioid.webp', S.of(context).legend_inflorescence_scorpioid),
      _InflorescenceItem('res/images/inflorescence_scorpioid_thyrse.webp', S.of(context).legend_inflorescence_scorpioid_thyrse),
      _InflorescenceItem('res/images/inflorescence_dichasial_thyrse.webp', S.of(context).legend_inflorescence_dichasial_thyrse),
      _InflorescenceItem('res/images/inflorescence_double_scorpioid_thyrse.webp', S.of(context).legend_inflorescence_double_scorpioid_thyrse),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).plant_inflorescence),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.68,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFFE6E6E6)),
            ),
            padding: const EdgeInsets.fromLTRB(6.0, 8.0, 6.0, 6.0),
            child: Column(
              children: [
                Expanded(
                  child: Image(
                    image: AssetImage(item.asset),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.0,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InflorescenceItem {
  final String asset;
  final String label;

  _InflorescenceItem(this.asset, this.label);
}
