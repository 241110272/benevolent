import 'package:flutter/widgets.dart';
import 'cloud.dart';

class AppScope extends InheritedWidget {
  const AppScope({super.key, required super.child, this.cloud});
  final CloudController? cloud;
  static CloudController? cloudOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()?.cloud;
  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.cloud != cloud;
}
