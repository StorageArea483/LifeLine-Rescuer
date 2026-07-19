import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/pages/rescuer_contact_page.dart';
import 'package:life_line_rescuer/providers/ngo_chat_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/utils/responsive_helper.dart';
import 'package:life_line_rescuer/widgets/global/in_out_calls.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';
import 'package:life_line_rescuer/widgets/global/page_navigation.dart';

class NgoChatScreen extends ConsumerStatefulWidget {
  final String ngoId;
  final String ngoName;

  const NgoChatScreen({super.key, required this.ngoId, required this.ngoName});

  @override
  ConsumerState<NgoChatScreen> createState() => _NgoChatScreenState();
}

class _NgoChatScreenState extends ConsumerState<NgoChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  FirebaseFirestore? ngoFirestore;

  StreamSubscription? _messageSubscription;

  String? currentUserId;
  String? chatId;

  // life-line-ngo database credentials
  static const FirebaseOptions _ngoFirebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyBeieryGaw4bh4dtbrI54qsIc51XkP6SoM',
    appId: '1:169949190544:web:2640453ce5dd2aa55d3b15',
    messagingSenderId: '169949190544',
    projectId: 'life-line-ngo',
    authDomain: 'life-line-ngo.firebaseapp.com',
    storageBucket: 'life-line-ngo.firebasestorage.app',
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
    super.dispose();
  }

  // Builds a deterministic chat id from the two participant ids
  String _generateChatId(String userId, String ngoId) {
    final ids = [userId, ngoId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _initializeChat() async {
    if (mounted) {
      ref.read(ngoChatLoadingProvider.notifier).state = true;
    }
    try {
      FirebaseApp ngoApp;
      try {
        ngoApp = Firebase.app('life-line-ngo');
      } catch (_) {
        ngoApp = await Firebase.initializeApp(
          name: 'life-line-ngo',
          options: _ngoFirebaseOptions,
        );
      }
      ngoFirestore = FirebaseFirestore.instanceFor(app: ngoApp);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          ref.read(ngoChatLoadingProvider.notifier).state = false;
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
      final chatId = _generateChatId(userId, widget.ngoId);
      if (mounted) {
        ref.read(ngoChatIdProvider.notifier).state = chatId;
      }

      _subscribeToMessages(chatId);

      if (mounted) {
        ref.read(ngoChatLoadingProvider.notifier).state = false;
      }
    } catch (e) {
      if (mounted) {
        ref.read(ngoChatLoadingProvider.notifier).state = false;
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
    if (ngoFirestore == null) return;

    try {
      _messageSubscription?.cancel();

      _messageSubscription = ngoFirestore!
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;

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

            ref.read(ngoChatMessagesProvider(chatId).notifier).state = messages;
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

  Future<void> _sendMessage() async {
    try {
      if (ngoFirestore == null) return;

      final text = _messageController.text.trim();
      if (text.isEmpty) return;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      final currentChatId = ref.read(ngoChatIdProvider);

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

      await ngoFirestore!
          .collection('chats')
          .doc(currentChatId)
          .collection('messages')
          .add({
            'chatId': currentChatId,
            'senderId': userId,
            'receiverId': widget.ngoId,
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
      final chatId = ref.read(ngoChatIdProvider);
      if (ngoFirestore == null || chatId == null) return;

      await ngoFirestore!
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
          _buildNgoLogo(widget.ngoName),
          SizedBox(width: ResponsiveHelper.isTablet(context) ? 16 : 12),
          Expanded(
            child: Text(
              widget.ngoName,
              style: AppText.fieldLabel.copyWith(
                fontSize: ResponsiveHelper.isTablet(context) ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkCharcoal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNgoLogo(String ngoName) {
    return Container(
      width: ResponsiveHelper.isTablet(context) ? 72 : 48,
      height: ResponsiveHelper.isTablet(context) ? 72 : 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/offline_logos/$ngoName.webp',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.primaryMaroon.withOpacity(0.1),
              child: Icon(
                Icons.business,
                color: AppColors.primaryMaroon,
                size: ResponsiveHelper.isTablet(context) ? 36 : 24,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(ngoChatLoadingProvider);
    final chatId = ref.watch(ngoChatIdProvider);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMaroon),
      );
    }

    if (chatId == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMaroon),
      );
    }

    final messages = ref.watch(ngoChatMessagesProvider(chatId));

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
