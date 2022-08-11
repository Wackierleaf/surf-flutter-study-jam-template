import 'package:flutter/material.dart';
import 'package:surf_practice_chat_flutter/features/auth/repository/auth_repository.dart';
import 'package:surf_practice_chat_flutter/features/auth/screens/auth_screen.dart';
import 'package:surf_study_jam/surf_study_jam.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

/// App,s main widget.
class MyApp extends StatelessWidget {
  /// Constructor for [MyApp].
  const MyApp({Key? key}) : super(key: key);

  final Color borderColor = const Color.fromRGBO(2, 110, 24, 1);
  final Color errorColor = const Color.fromRGBO(211, 109, 109, 1);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: borderColor,
          background: Colors.white,
          error: errorColor
        )
      ),
      home: AuthScreen(
        authRepository: AuthRepository(StudyJamClient()),
      ),
    );
  }
}
