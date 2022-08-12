import 'package:flutter/material.dart';
import 'package:surf_practice_chat_flutter/features/topics/repository/chart_topics_repository.dart';

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

  @override
  void initState() {
    super.initState();
    DateTime start = DateTime(2022);
    final topics =
        widget.chatTopicsRepository.getTopics(topicsStartDate: start);
    setState(() {
      _chatTopics = topics;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
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
                        _ChatTopic(topicData: snapshot.data.elementAt(index)));
              }
          }
        });
  }
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
                  Text(
                    topicData.name as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (topicData.description != null)
                    Text(topicData.description as String)
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
      if (topicData.name != null) {
        var splitted = topicData.name!.split(' ');
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
