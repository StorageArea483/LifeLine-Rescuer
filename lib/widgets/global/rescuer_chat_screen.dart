import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;

import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/pages/rescuer_contact_page.dart';
import 'package:life_line_rescuer/providers/rescuer_chat_screen_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/utils/responsive_helper.dart';
import 'package:life_line_rescuer/widgets/global/in_out_calls.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';
import 'package:life_line_rescuer/widgets/global/page_navigation.dart';

class RescuerChatScreen extends ConsumerStatefulWidget {
  final String victimId;
  final String victimName;
  final String photoUrl;
  const RescuerChatScreen({
    super.key,
    required this.victimId,
    required this.victimName,
    required this.photoUrl,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RescuerChatScreenState();
}

class _RescuerChatScreenState extends ConsumerState<RescuerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  FirebaseFirestore? victimFirestore;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _presenceSubscription;

  String? currentUserId;

  // life-line-victim database credentials
  static const FirebaseOptions _victimAndroidOptions = FirebaseOptions(
    apiKey: 'AIzaSyByihQ3YBdrJUrAAxFSX3257fUMa0AJ6uo',
    appId: '1:503939690280:android:aff06bb9fb777faf792a1d',
    messagingSenderId: '503939690280',
    projectId: 'project-life-line',
    storageBucket: 'project-life-line.firebasestorage.app',
  );

  static const FirebaseOptions _victimIosOptions = FirebaseOptions(
    apiKey: 'AIzaSyBDX51z8C6yiZnbEHgHK70UxnRZcn5oSd0',
    appId: '1:503939690280:ios:ed2fb1d85f841609792a1d',
    messagingSenderId: '503939690280',
    projectId: 'project-life-line',
    storageBucket: 'project-life-line.firebasestorage.app',
    iosBundleId: 'com.example.lifeLine',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageSubscription?.cancel();
    _presenceSubscription?.cancel();
    super.dispose();
  }

  // Builds a deterministic chat id from the two participant ids
  String _generateChatId(String userId, String victimId) {
    final ids = [userId, victimId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _initializeChat() async {
    if (mounted) {
      ref.read(rescuerChatLoadingProvider.notifier).state = true;
    }
    try {
      FirebaseApp rescuerApp;

      // Victim Firebase
      try {
        rescuerApp = Firebase.app('project-life-line');
      } catch (_) {
        rescuerApp = await Firebase.initializeApp(
          name: 'project-life-line',
          options: Platform.isIOS ? _victimIosOptions : _victimAndroidOptions,
        );
      }
      victimFirestore = FirebaseFirestore.instanceFor(app: rescuerApp);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          ref.read(rescuerChatLoadingProvider.notifier).state = false;
          pageMessage(
            'Unable to load chat. Please re-try.',
            context,
            AppColors.error,
          );
          pageNavigation(const InOutCalls(child: LandingPage()), context);
        }
        return;
      }

      currentUserId = userId;

      final chatId = _generateChatId(userId, widget.victimId);
      if (mounted) {
        ref.read(rescuerChatIdProvider.notifier).state = chatId;
      }

      _subscribeToMessages(chatId);
      _subscribeToPresence();
      await _fetchVictimReport();

      if (mounted) {
        ref.read(rescuerChatLoadingProvider.notifier).state = false;
      }
    } catch (e) {
      if (mounted) {
        ref.read(rescuerChatLoadingProvider.notifier).state = false;
        pageMessage(
          'An unexpected error occurred. Please try again.',
          context,
          AppColors.error,
        );
        pageNavigation(const InOutCalls(child: LandingPage()), context);
      }
    }
  }

  void _subscribeToMessages(String chatId) {
    try {
      _messageSubscription?.cancel();

      _messageSubscription = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
            final messages =
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  return {
                    'id': doc.id,
                    'senderId': data['senderId'] ?? '',
                    'text': data['text'] ?? '',
                    'createdAt': data['createdAt'],
                  };
                }).toList();
            if (!mounted) return;
            ref.read(rescuerChatMessagesProvider(chatId).notifier).state =
                messages;
          });
    } catch (e) {
      if (mounted) {
        pageMessage(
          'Unable to load messages, please retry',
          context,
          AppColors.error,
        );
      }
    }
  }

  void _subscribeToPresence() {
    if (victimFirestore == null) return;

    try {
      _presenceSubscription?.cancel();

      _presenceSubscription = victimFirestore!
          .collection('users')
          .doc(widget.victimId)
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;
            final isOnline = snapshot.data()?['online'] ?? false;
            ref
                .read(victimOnlineStatusProvider(widget.victimId).notifier)
                .state = isOnline;
          });
    } catch (e) {
      if (mounted) {
        pageMessage(
          'Unable to check victim status, please retry',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _fetchVictimReport() async {
    if (victimFirestore == null) return;

    try {
      final reportDoc =
          await victimFirestore!
              .collection('victim-report')
              .doc(widget.victimId)
              .get();

      if (reportDoc.exists) {
        final data = reportDoc.data() ?? {};
        if (!mounted) return;
        ref.read(victimReportProvider(widget.victimId).notifier).state = data;

        // Show the report sheet
        _showVictimReportSheet(data);
      }
    } catch (e) {
      if (mounted) {
        pageMessage('Unable to load victim report.', context, AppColors.error);
      }
    }
  }

  void _showVictimReportSheet(Map<String, dynamic> report) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final entries = report.entries.toList();

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: entries.length,
            separatorBuilder:
                (_, _) =>
                    const Divider(height: 24, color: AppColors.borderColor),
            itemBuilder: (context, index) {
              final key = entries[index].key;
              final value = entries[index].value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: AppText.small.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$value',
                    style: AppText.fieldLabel.copyWith(
                      fontSize: 15,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    try {
      final text = _messageController.text.trim();
      if (text.isEmpty) return;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (!mounted) return;
      final currentChatId = ref.read(rescuerChatIdProvider);

      if (userId == null || currentChatId == null) {
        if (mounted) {
          pageMessage(
            'Unable to send message. Please try again.',
            context,
            AppColors.error,
          );
        }
        return;
      }

      _messageController.clear();

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(currentChatId)
          .collection('messages')
          .add({
            'chatId': currentChatId,
            'senderId': userId,
            'receiverId': widget.victimId,
            'text': text,
            'status': 'sent',
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      if (mounted) {
        pageMessage(
          'Unable to send message. Please try again.',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      if (!mounted) return;
      final chatId = ref.read(rescuerChatIdProvider);
      if (chatId == null) return;

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      if (mounted) {
        pageMessage(
          'Unable to delete message. Please try again.',
          context,
          AppColors.error,
        );
      }
    }
  }

  Widget _buildOptionsMenu(String messageId) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        size: 18,
        color: AppColors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) {
        if (value == 'delete') {
          _deleteMessage(messageId);
        }
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Message'),
                ],
              ),
            ),
          ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: ResponsiveHelper.contentWidth(context),
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    return _buildHeader(context, ref);
                  },
                ),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      return _buildMessagesList(context, ref);
                    },
                  ),
                ),
                _buildInputSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final avatarSize = ResponsiveHelper.isTablet(context) ? 56.0 : 40.0;
    final isOnline = ref.watch(victimOnlineStatusProvider(widget.victimId));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isTablet(context) ? 24 : 16,
        vertical: ResponsiveHelper.isTablet(context) ? 16 : 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: ResponsiveHelper.iconSize(context),
              color: AppColors.textPrimary,
            ),
            onPressed:
                () => pageNavigation(
                  const InOutCalls(child: RescuerContactPage()),
                  context,
                ),
          ),
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundColor: AppColors.primaryMaroon.withOpacity(0.1),
                  backgroundImage:
                      widget.photoUrl.isNotEmpty
                          ? NetworkImage(widget.photoUrl)
                          : null,
                  child:
                      widget.photoUrl.isEmpty
                          ? Icon(
                            Icons.person,
                            color: AppColors.primaryMaroon,
                            size: avatarSize * 0.5,
                          )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: avatarSize * 0.28,
                    height: avatarSize * 0.28,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceLight,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.isTablet(context) ? 16 : 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.victimName,
                  style: AppText.fieldLabel.copyWith(
                    fontSize: ResponsiveHelper.isTablet(context) ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: AppText.small.copyWith(
                    color:
                        isOnline ? AppColors.success : AppColors.textSecondary,
                    fontSize: ResponsiveHelper.bodyFont(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(rescuerChatLoadingProvider);
    final chatId = ref.watch(rescuerChatIdProvider);

    if (isLoading || chatId == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMaroon),
      );
    }

    final messages = ref.watch(rescuerChatMessagesProvider(chatId));

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 48 : 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.textSecondary.withOpacity(0.5),
                size: ResponsiveHelper.isTablet(context) ? 96 : 64,
              ),
              SizedBox(height: ResponsiveHelper.isTablet(context) ? 24 : 16),
              Text(
                'No messages yet',
                style: AppText.subtitle.copyWith(
                  fontSize: ResponsiveHelper.titleFont(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isSentByMe = message['senderId'] == currentUserId;
        return _buildMessageBubble(context, message, isSentByMe);
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> message,
    bool isSentByMe,
  ) {
    final bubbleMaxWidth = MediaQuery.of(context).size.width * 0.7;
    final messageId = message['id'] as String;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isSentByMe) _buildOptionsMenu(messageId),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
            decoration: BoxDecoration(
              color: isSentByMe ? AppColors.primaryMaroon : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
                bottomRight: Radius.circular(isSentByMe ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkCharcoal.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message['text'] ?? '',
              style: TextStyle(
                color: isSentByMe ? Colors.white : AppColors.darkCharcoal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.isTablet(context) ? 24 : 12,
        12,
        ResponsiveHelper.isTablet(context) ? 24 : 12,
        ResponsiveHelper.isTablet(context) ? 24 : 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.softBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primaryMaroon.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: AppText.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primaryMaroon,
            radius: ResponsiveHelper.isTablet(context) ? 26 : 22,
            child: IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: ResponsiveHelper.isTablet(context) ? 22 : 18,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
