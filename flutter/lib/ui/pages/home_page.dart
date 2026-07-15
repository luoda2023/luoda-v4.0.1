// flutter/lib/ui/pages/home_page.dart
// 微信风格设备列表页（首页）

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/device_card.dart';
import '../components/conversation_item.dart';
import '../components/search_bar.dart';
import '../states/app_state.dart';
import '../states/conversation_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Get.find<AppState>();
    final convState = Get.find<ConversationState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text('设备列表', style: AppTextStyles.headline2),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textOnDark),
            onPressed: () => appState.searchKeyword = '', // reset / open search
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textOnDark),
            onPressed: () => Get.toNamed('/settings'),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, sb) => [_buildSliverHeader(ctx)],
        body: Column(
          children: [
            StreamBuilder<List<Conversation>>(
              stream: convState.listenConversations(),
              builder: (context, snap) {
                final list = convState.filteredConvs(keyword: appState.searchKeyword);
                return Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text("暂无设备"))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: list.length,
                          itemBuilder: (c, i) => ConversationItem(
                            name: list[i].name,
                            lastMessage: list[i].lastMessage,
                            unreadCount: list[i].unreadCount,
                            avatarText: list[i].avatarText ?? 'D',
                            onTap: () => appState.selectConversation(list[i].id),
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext c) {
    return SliverToBoxAdapter(
      child: SearchBar(
        hintText: '搜索设备或联系人',
        onChanged: (v) => Get.find<AppState>().searchKeyword = v,
      ),
    );
  }
}

// === mock helpers ===
extension ConversationStateX on ConversationState {
  Stream<List<Conversation>> listenConversations() async* {
    // periodically refresh
    while (true) {
      yield conversations.toList();
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  List<Conversation> filteredConvs({String? keyword}) {
    final q = keyword?.toLowerCase() ?? '';
    return conversations.where((c) {
      return q.isEmpty || c.name.toLowerCase().contains(q);
    }).toList();
  }
}
