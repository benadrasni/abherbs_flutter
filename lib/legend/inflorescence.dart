import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:flutter/material.dart';

class InflorescenceLegendScreen extends StatefulWidget {
  final List<String> highlighted;

  InflorescenceLegendScreen({this.highlighted = const <String>[]});

  @override
  State<InflorescenceLegendScreen> createState() => _InflorescenceLegendScreenState();
}

class _InflorescenceLegendScreenState extends State<InflorescenceLegendScreen> {
  final GlobalKey _primaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _primaryKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.25, duration: const Duration(milliseconds: 280));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.highlighted;
    final primary = highlighted.isNotEmpty ? highlighted.first : null;
    final items = [
      _InflorescenceItem('raceme', 'res/images/inflorescence_raceme.webp', S.of(context).legend_inflorescence_raceme),
      _InflorescenceItem('spike', 'res/images/inflorescence_spike.webp', S.of(context).legend_inflorescence_spike),
      _InflorescenceItem('spadix', 'res/images/inflorescence_spadix.webp', S.of(context).legend_inflorescence_spadix),
      _InflorescenceItem('corymb', 'res/images/inflorescence_corymb.webp', S.of(context).legend_inflorescence_corymb),
      _InflorescenceItem('umbel', 'res/images/inflorescence_umbel.webp', S.of(context).legend_inflorescence_umbel),
      _InflorescenceItem('compound_umbel', 'res/images/inflorescence_compound_umbel.webp', S.of(context).legend_inflorescence_compound_umbel),
      _InflorescenceItem('capitulum', 'res/images/inflorescence_capitulum.webp', S.of(context).legend_inflorescence_capitulum),
      _InflorescenceItem('head', 'res/images/inflorescence_head.webp', S.of(context).legend_inflorescence_head),
      _InflorescenceItem('panicle', 'res/images/inflorescence_panicle.webp', S.of(context).legend_inflorescence_panicle),
      _InflorescenceItem('compound_spike', 'res/images/inflorescence_compound_spike.webp', S.of(context).legend_inflorescence_compound_spike),
      _InflorescenceItem('cyme', 'res/images/inflorescence_cyme.webp', S.of(context).legend_inflorescence_cyme),
      _InflorescenceItem('helicoid', 'res/images/inflorescence_helicoid.webp', S.of(context).legend_inflorescence_helicoid),
      _InflorescenceItem('rhipidium', 'res/images/inflorescence_rhipidium.webp', S.of(context).legend_inflorescence_rhipidium),
      _InflorescenceItem('scorpioid', 'res/images/inflorescence_scorpioid.webp', S.of(context).legend_inflorescence_scorpioid),
      _InflorescenceItem('scorpioid_thyrse', 'res/images/inflorescence_scorpioid_thyrse.webp', S.of(context).legend_inflorescence_scorpioid_thyrse),
      _InflorescenceItem('dichasial_thyrse', 'res/images/inflorescence_dichasial_thyrse.webp', S.of(context).legend_inflorescence_dichasial_thyrse),
      _InflorescenceItem('double_scorpioid_thyrse', 'res/images/inflorescence_double_scorpioid_thyrse.webp', S.of(context).legend_inflorescence_double_scorpioid_thyrse),
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
          final matched = highlighted.contains(item.key);
          final isPrimary = item.key == primary;
          return Container(
            key: isPrimary ? _primaryKey : null,
            decoration: BoxDecoration(
              color: matched ? const Color(0xFFE7EFE8) : Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: matched ? const Color(0xFF3E5344) : const Color(0xFFE6E6E6),
                width: isPrimary ? 2.5 : 1.0,
              ),
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
                  style: TextStyle(
                    fontSize: 13.0,
                    height: 1.2,
                    fontWeight: matched ? FontWeight.w600 : FontWeight.w400,
                    color: matched ? const Color(0xFF3E5344) : null,
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
  final String key;
  final String asset;
  final String label;

  _InflorescenceItem(this.key, this.asset, this.label);
}
