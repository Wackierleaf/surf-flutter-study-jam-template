
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surf_practice_chat_flutter/features/topics/models/chat_topic_send_dto.dart';
import 'package:surf_practice_chat_flutter/features/topics/repository/chart_topics_repository.dart';
import 'package:surf_study_jam/surf_study_jam.dart';

import '../../auth/models/token_dto.dart';
import '../../chat/repository/chat_repository.dart';
import '../../chat/screens/chat_screen.dart';
import '../models/chat_topic_dto.dart';

/// Screen with different chat topics to go to.
class TopicsScreen extends StatefulWidget {
  final IChatTopicsRepository chatTopicsRepository;

  /// Constructor for [TopicsScreen].
  const TopicsScreen({required this.chatTopicsRepository, Key? key})
      : super(key: key);

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  Future<Iterable<ChatTopicDto>> _chatTopics = Future(() => <ChatTopicDto>[]);
  late final TextEditingController _name;
  late final TextEditingController _description;
  DateTime start = DateTime(2022);

  @override
  void initState() {
    _name = TextEditingController();
    _description = TextEditingController();
    final topics =
        widget.chatTopicsRepository.getTopics(topicsStartDate: start);
    setState(() {
      _chatTopics = topics;
    });

    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void createNewTopic() async {
    ChatTopicSendDto newTopic =
        ChatTopicSendDto(name: _name.text, description: _description.text);
    await widget.chatTopicsRepository.createTopic(newTopic);
    final topics =
        widget.chatTopicsRepository.getTopics(topicsStartDate: start);
    setState(() {
      _chatTopics = topics;
    });
  }

  void openTopicCreationDia() async {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text('Создание чата'),
              content: (Wrap(
                spacing: 2.1,
                children: [
                  TextField(
                    controller: _name,
                    maxLength: 100,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Название',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 3,
                              color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 3,
                            color: Theme.of(context).colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _description,
                    maxLength: 200,
                    maxLines: 4,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Описание',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 3,
                              color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 3,
                            color: Theme.of(context).colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                ],
              )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, 'Close'),
                    child: const Text('Отмена')),
                ElevatedButton(
                    onPressed: () {
                      createNewTopic();
                      Navigator.pop(context, 'Created');
                    },
                    child: const Text('Создать'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: _ChatTopicsAppBar(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
              child: _ChatTopicsBody(
            chatTopics: _chatTopics,
          ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => openTopicCreationDia(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ChatTopicsBody extends StatelessWidget {
  final Future<Iterable<ChatTopicDto>> chatTopics;

  const _ChatTopicsBody({required this.chatTopics, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: chatTopics,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Text('Loading....');
            default:
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return ListView.separated(
                    separatorBuilder: (context, index) => const Divider(
                          color: Colors.grey,
                          indent: 10,
                          endIndent: 10,
                          thickness: 0.8,
                        ),
                    itemCount: snapshot.data.length,
                    itemBuilder: (_, index) =>
                    GestureDetector(
                      onTap: () => _pushToChat(context, snapshot.data.elementAt(index).id),
                      child: _ChatTopic(topicData: snapshot.data.elementAt(index)),
                    )
                );
              }
          }
        });
  }

  void _pushToChat(BuildContext context, int chatId) async  {
    final prefs = await SharedPreferences.getInstance();
    Object? token = prefs.get('USR_TOKEN');
    Navigator.push<ChatScreen>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ChatScreen(
            chatRepository: ChatRepository(
              StudyJamClient().getAuthorizedClient(token.toString()),
            ),
            chatId: chatId,
          );
        },
      ),
    );
  }
}

Future<String> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  Object? token = prefs.get('USR_TOKEN');
  print(token);
  return token.toString();
}

class _ChatTopicsAppBar extends StatelessWidget {
  const _ChatTopicsAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [const Text('Чаты')],
      ),
    );
  }
}

class _ChatTopic extends StatelessWidget {
  final ChatTopicDto topicData;

  const _ChatTopic({required this.topicData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        child: Row(
          children: [
            _TopicAvatar(topicData: topicData),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (topicData.description != null)
                    Text(
                      topicData.name.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (topicData.description != null)
                    Text(topicData.description.toString())
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TopicAvatar extends StatelessWidget {
  static const double _size = 42;

  final ChatTopicDto topicData;

  const _TopicAvatar({
    required this.topicData,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String getInitials() {
      final name = topicData.name;
      if (name != null && name.isNotEmpty) {
        List<String> splitted = topicData.name!.split(' ');
        return splitted.isNotEmpty
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
