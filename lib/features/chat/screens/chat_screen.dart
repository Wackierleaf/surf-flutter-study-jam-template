import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:surf_practice_chat_flutter/features/chat/models/chat_geolocation_geolocation_dto.dart';
import 'package:surf_practice_chat_flutter/features/chat/models/chat_message_dto.dart';
import 'package:surf_practice_chat_flutter/features/chat/models/chat_message_location_dto.dart';
import 'package:surf_practice_chat_flutter/features/chat/models/chat_user_dto.dart';
import 'package:surf_practice_chat_flutter/features/chat/models/chat_user_local_dto.dart';
import 'package:surf_practice_chat_flutter/features/chat/repository/chat_repository.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Main screen of chat app, containing messages.
class ChatScreen extends StatefulWidget {
  /// Repository for chat functionality.
  final IChatRepository chatRepository;
  final int chatId;

  /// Constructor for [ChatScreen].
  const ChatScreen({
    required this.chatRepository,
    required this.chatId,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _nameEditingController = TextEditingController();

  Iterable<ChatMessageDto> _currentMessages = [];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _ChatAppBar(
          controller: _nameEditingController,
          onUpdatePressed: _onUpdatePressed,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ChatBody(
              messages: _currentMessages,
            ),
          ),
          _ChatTextField(
            onSendPressed: _onSendPressed,
            onSendGeoMsg: _onSendGeoMsg,
          ),
        ],
      ),
    );
  }

  Future<void> _onUpdatePressed() async {
    final messages = await widget.chatRepository.getMessagesByChatId(widget.chatId);
    setState(() {
      _currentMessages = messages;
    });
  }

  Future<void> _onSendPressed(String msg) async {
    final messages = await widget.chatRepository.sendMessage(msg, widget.chatId);
    setState(() {
      _currentMessages = messages;
    });
  }

  Future<void> _onSendGeoMsg(ChatGeolocationDto location, String msg) async {
    final messages = await widget.chatRepository
        .sendGeolocationMessage(location: location, message: msg);
    setState(() {
      _currentMessages = messages;
    });
  }
}

class _ChatBody extends StatelessWidget {
  final Iterable<ChatMessageDto> messages;

  const _ChatBody({
    required this.messages,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (_, index) => _ChatMessage(
        chatData: messages.elementAt(index),
      ),
    );
  }
}

class _ChatTextField extends StatelessWidget {
  final ValueChanged<String> onSendPressed;
  final onSendGeoMsg;

  final _textEditingController = TextEditingController();

  _ChatTextField({
    required this.onSendPressed,
    required this.onSendGeoMsg,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    Future<Position> _determinePosition() async {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }
      return await Geolocator.getCurrentPosition();
    }

    void setLocationIntoChatTextField() async {
      Position position = await _determinePosition();
      _textEditingController.text =
          'Сообщение с геолокацией: (${position.longitude}, ${position.latitude})';
      ChatGeolocationDto location = ChatGeolocationDto(
          latitude: position.latitude, longitude: position.longitude);
      onSendGeoMsg(location, _textEditingController.text);
    }

    void showAttachmentsDialog() async {
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: Text('Вложения'),
                content: Wrap(
                  verticalDirection: VerticalDirection.down,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context, 'Picture');
                      },
                      icon: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 72,
                      ),
                      label: const Text('Отправить картинки'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setLocationIntoChatTextField();
                        Navigator.pop(context, 'Geo');
                      },
                      icon: const Icon(
                        Icons.pin_drop,
                        color: Colors.blue,
                        size: 72,
                      ),
                      label: const Text('Отправить геолокацию'),
                    )
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, 'Close'),
                      child: const Text('Закрыть'))
                ],
              ));
    }

    return Material(
      color: colorScheme.surface,
      elevation: 12,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: mediaQuery.padding.bottom + 8,
          left: 5,
        ),
        child: Row(
          children: [
            IconButton(
                onPressed: () => showAttachmentsDialog(),
                splashRadius: 25,
                icon: const Icon(Icons.attach_file)),
            Expanded(
              child: TextField(
                controller: _textEditingController,
                decoration: const InputDecoration(
                  hintText: 'Сообщение',
                ),
              ),
            ),
            IconButton(
              onPressed: () => onSendPressed(_textEditingController.text),
              icon: const Icon(Icons.send),
              color: colorScheme.onSurface,
              splashRadius: 25,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget {
  final VoidCallback onUpdatePressed;
  final TextEditingController controller;

  const _ChatAppBar({
    required this.onUpdatePressed,
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: onUpdatePressed,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final ChatMessageDto chatData;

  const _ChatMessage({
    required this.chatData,
    Key? key,
  }) : super(key: key);

  void launchMapsApp(double? longitude, double? latitude) async {
    if (await canLaunchUrlString(
        'https://yandex.ru/maps/?ll=$longitude%2C$latitude&z=2')) {
      await launchUrlString(
          'https://yandex.ru/maps/?ll=$longitude%2C$latitude&z=2');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        child: Row(
          textDirection: chatData.chatUserDto is ChatUserLocalDto
              ? TextDirection.rtl
              : TextDirection.ltr,
          children: [
            _ChatAvatar(userData: chatData.chatUserDto),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    textDirection: chatData.chatUserDto is ChatUserLocalDto
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    children: [
                      Text(
                        chatData.chatUserDto.name ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (chatData is ChatMessageGeolocationDto)
                        IconButton(
                          onPressed: () => launchMapsApp(
                              chatData.location?.longitude,
                              chatData.location?.latitude),
                          icon: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                          ),
                          splashRadius: 15,
                        ),
                    ],
                  ),
                  if (chatData is ChatMessageGeolocationDto)
                    Row(
                      textDirection: chatData.chatUserDto is ChatUserLocalDto
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      children: [
                        SizedBox(
                          child: Text(
                            "φ: ${chatData.location?.latitude} "
                            "\nθ: ${chatData.location?.longitude}",
                          ),
                        )
                      ],
                    ),
                  const SizedBox(height: 4),
                  Bubble(
                    color: chatData.chatUserDto is ChatUserLocalDto
                        ? Colors.lightBlueAccent.withOpacity(.2)
                        : Colors.lightGreen.withOpacity(.3),
                    nip: chatData.chatUserDto is ChatUserLocalDto ? BubbleNip.rightTop : BubbleNip.leftTop,
                    child: Text(chatData.message ?? ''),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  static const double _size = 42;

  final ChatUserDto userData;

  const _ChatAvatar({
    required this.userData,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String getInitials() {
      if (userData.name != null) {
        var splitted = userData.name!.split(' ');
        return splitted.last.isNotEmpty
            ? '${splitted.first[0]}${splitted.last[0]}'
            : splitted.first[0];
      }
      return '';
    }

    return SizedBox(
      width: _size,
      height: _size,
      child: Material(
        color: colorScheme.primary,
        shape: const CircleBorder(),
        child: Center(
          child: Text(
            getInitials(),
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }
}
