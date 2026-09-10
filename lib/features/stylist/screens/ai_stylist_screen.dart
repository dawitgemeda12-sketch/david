import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/stylist_service.dart';
import '../../../data/services/wardrobe_service.dart';
import '../../../data/models/chat_message_model.dart';

/// AI Stylist — understated, helpful conversational styling assistant
/// that reasons over the user's real wardrobe. Clearly distinguishes
/// items the user owns from Shop the Gap suggestions.
class AiStylistScreen extends StatefulWidget {
  const AiStylistScreen({super.key});

  @override
  State<AiStylistScreen> createState() => _AiStylistScreenState();
}

class _AiStylistScreenState extends State<AiStylistScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  static const _suggestions = [
    (icon: Icons.dashboard_customize_outlined, label: 'Create an outfit'),
    (icon: Icons.wb_sunny_outlined, label: 'What should I wear today?'),
    (icon: Icons.search, label: 'What am I missing?'),
    (icon: Icons.event_outlined, label: 'Style for an occasion'),
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _sending) return;
    _inputCtrl.clear();
    setState(() => _sending = true);
    final auth = context.read<AuthService>();
    final stylist = context.read<StylistService>();
    final user = auth.currentUser!;
    await stylist.handleUserQuery(userId: user.id, query: text.trim());
    if (!mounted) return;
    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final stylist = context.watch<StylistService>();
    final wardrobeService = context.watch<WardrobeService>();
    final user = auth.currentUser!;
    final history = stylist.historyFor(user.id);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Stylish AI')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: history.isEmpty
                  ? _WelcomePrompt(userName: user.name, onSuggestionTap: _send)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final msg = history[index];
                        return _ChatBubble(message: msg, wardrobeService: wardrobeService);
                      },
                    ),
            ),
            if (_sending)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Stylish is thinking…', style: TextStyle()),
              ),
            _ComposerBar(controller: _inputCtrl, onSend: _send, sending: _sending),
          ],
        ),
      ),
    );
  }
}

class _WelcomePrompt extends StatelessWidget {
  final String userName;
  final ValueChanged<String> onSuggestionTap;
  const _WelcomePrompt({required this.userName, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi ${userName.split(' ').first.isEmpty ? 'there' : userName.split(' ').first}, what would you like help with today?',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 24),
          ..._AiStylistScreenState._suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => onSuggestionTap(s.label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(s.icon, size: 18, color: AppColors.oliveDark),
                        const SizedBox(width: 12),
                        Text(s.label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoal)),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final WardrobeService wardrobeService;
  const _ChatBubble({required this.message, required this.wardrobeService});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.charcoal : AppColors.ivory,
          borderRadius: BorderRadius.circular(18),
          border: isUser ? null : Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(color: isUser ? AppColors.ivory : AppColors.charcoal),
            ),
            if (!isUser && message.referencedWardrobeItemIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('IN YOUR WARDROBE', style: AppTextStyles.caption.copyWith(color: AppColors.olive, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: message.referencedWardrobeItemIds.map((id) {
                    final item = wardrobeService.getById(id);
                    if (item == null) return const SizedBox.shrink();
                    return Container(
                      width: 56,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.sandLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.imagePath != null && File(item.imagePath!).existsSync()
                          ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                          : const Icon(Icons.checkroom_outlined, size: 18, color: AppColors.mutedGray),
                    );
                  }).toList(),
                ),
              ),
            ],
            if (!isUser && message.referencedShopGapIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('SHOP THE GAP', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool sending;
  const _ComposerBar({required this.controller, required this.onSend, required this.sending});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Ask me anything…'),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.charcoal,
            child: IconButton(
              icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
              onPressed: sending ? null : () => onSend(controller.text),
            ),
          ),
        ],
      ),
    );
  }
}
