import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:flutter/material.dart';

Future<void> infoDialog(BuildContext mainContext, String title, String content) async {
  return showDialog(
      context: mainContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: Text(S.of(context).close.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  )),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
}

Future<bool> notificationPopup(BuildContext context, String? title, String? body) async {
  final heading = (title != null && title.isNotEmpty) ? title : S.of(context).notification;
  final detail = (body != null && body.isNotEmpty && body != heading) ? body : null;
  final opened = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: Image.asset(
                'res/images/app_icon.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 6),
                    Text(detail, style: TextStyle(fontSize: 14.0, color: Colors.grey[800])),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).notification_open,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                )),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          TextButton(
            child: Text(S.of(context).notification_close,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                )),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    },
  );
  return opened == true;
}
