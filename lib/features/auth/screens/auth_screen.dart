import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surf_practice_chat_flutter/features/auth/models/token_dto.dart';
import 'package:surf_practice_chat_flutter/features/auth/repository/auth_repository.dart';
import 'package:surf_practice_chat_flutter/features/chat/repository/chat_repository.dart';
import 'package:surf_practice_chat_flutter/features/chat/screens/chat_screen.dart';
import 'package:surf_study_jam/surf_study_jam.dart';
import 'package:flutter_flushbar/flutter_flushbar.dart';
import 'package:surf_practice_chat_flutter/features/auth/exceptions/auth_exception.dart';

/// Screen for authorization process.
///
/// Contains [IAuthRepository] to do so.
class AuthScreen extends StatefulWidget {
  /// Repository for auth implementation.
  final IAuthRepository authRepository;

  /// Constructor for [AuthScreen].
  const AuthScreen({
    required this.authRepository,
    Key? key,
  }) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // TODO(task): Implement Auth screen.

  late final TextEditingController _login;
  late final TextEditingController _password;

  bool isLoading = false;
  static const tokenKey = 'USR_TOKEN';

  @override
  void initState() {
    _login = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  void showSnackBar(BuildContext context, String msg) {
    Flushbar(
      message: msg,
      duration: const Duration(seconds: 3),
      leftBarIndicatorColor: Theme.of(context).colorScheme.error,
      icon: Icon(
        Icons.warning,
        color: Theme.of(context).colorScheme.error,
      ),
    ).show(context);
  }

  void login() async {
    setState(() {
      isLoading = true;
    });
    final login = _login.text;
    final password = _password.text;
    if (login.isNotEmpty && password.isNotEmpty) {
      try {
        TokenDto token = await widget.authRepository.signIn(login: login, password: password);
        saveToken(token);
        if (!mounted) return;
        _pushToChat(context, token);
        setState(() {
          isLoading = false;
        });
      } on AuthException catch (e) {
        showSnackBar(context, e.message);
      }
    } else {
      showSnackBar(context, 'Поля должны быть заполнены');
      setState(() {
        isLoading = false;
      });
    }
  }

  void saveToken(TokenDto token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _login,
              keyboardType: TextInputType.emailAddress,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                  labelText: 'Логин',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  border: OutlineInputBorder(
                    borderSide:  BorderSide(width: 3, color: Theme.of(context).colorScheme.primary),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 3, color: Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),

              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Пароль',
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                border: OutlineInputBorder(
                    borderSide:  BorderSide(width: 1, color: Theme.of(context).colorScheme.primary),
                    borderRadius: BorderRadius.circular(8)
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock),

              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
                onPressed: () {
                  login();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)
                ),
                child: const Text('ДАЛЕЕ')
            ),
            const SizedBox(height: 10),
            if(isLoading)
              const LinearProgressIndicator()
          ],
        ),
      ),
    );
  }

  void _pushToChat(BuildContext context, TokenDto token) {
    Navigator.push<ChatScreen>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ChatScreen(
            chatRepository: ChatRepository(
              StudyJamClient().getAuthorizedClient(token.token),
            ),
          );
        },
      ),
    );
  }
}