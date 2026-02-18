import 'package:url_launcher/url_launcher.dart';

Future<void> openDialer(String phoneNumber) async {
  final Uri uri = Uri(scheme: 'tel', path: phoneNumber);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Could not open dialer';
  }
}
