import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  static showToast(text) {
    return Fluttertoast.showToast(
      msg: "" + text,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      fontSize: 16.0,
    );
  }
}
