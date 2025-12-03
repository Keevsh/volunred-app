import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_module.dart';
import 'app_widget.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-initialize SharedPreferences to ensure it works in release builds
  await SharedPreferences.getInstance();
  
  return runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
