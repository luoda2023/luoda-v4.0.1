// flutter/lib/ui/components/dialog/base_dialog.dart
// 微信风格对话框基础组件

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// 微信风格通用对话框
///
/// 圆角浅色背景 + 顶部标题 + 中间内容 + 底部按钮
class WeChatDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final List<DialogAction> actions;
  final bool dismissOnAction;
  final VoidCallback? onCancel;

  const WeChatDialog({
    super.key,
    this.title,
    this.content,
    required this.actions,
    this.dismissOnAction = true,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  title!,
                  style: AppTextStyles.headline2,
                  textAlign: TextAlign.center,
                ),
              ),
            if (content != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: DefaultTextStyle.merge(
                  style: AppTextStyles.bodyText1,
                  child: content!,
                ),
              ),
            const Divider(height: 1, color: AppColors.divider),
            Row(
              children: _buildActions(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final w = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      final a = actions[i];
      if (i > 0) {
        w.add(const SizedBox(
          width: 1,
          child: SizedBox.expand(
            child: ColoredBox(color: AppColors.divider),
          ),
        ));
      }
      w.add(
        Expanded(
          child: TextButton(
            onPressed: () {
              if (dismissOnAction) Navigator.of(context).pop(a.value);
              a.onPressed?.call();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: a.isDestructive
                  ? AppColors.error
                  : AppColors.primaryGreen,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text(
              a.label,
              style: AppTextStyles.buttonSecondary.copyWith(
                color: a.isDestructive ? AppColors.error : AppColors.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }
    return w;
  }
}

class DialogAction<T> {
  final String label;
  final T value;
  final bool isDestructive;
  final VoidCallback? onPressed;

  const DialogAction({
    required this.label,
    required this.value,
    this.isDestructive = false,
    this.onPressed,
  });
}

/// 简单确认对话框
Future<bool?> showWeChatConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = '确定',
  String cancelLabel = '取消',
  bool isDestructive = false,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => WeChatDialog(
      title: title,
      content: Text(content, textAlign: TextAlign.center),
      actions: [
        DialogAction(label: cancelLabel, value: false),
        DialogAction(
          label: confirmLabel,
          value: true,
          isDestructive: isDestructive,
        ),
      ],
    ),
  );
}

/// 简单提示对话框（仅一个按钮）
Future<void> showWeChatAlertDialog(
  BuildContext context, {
  required String title,
  required String content,
  String okLabel = '确定',
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => WeChatDialog(
      title: title,
      content: Text(content, textAlign: TextAlign.center),
      actions: [
        DialogAction(label: okLabel, value: true),
      ],
    ),
  );
}

/// 加载中对话框
Future<T?> showWeChatLoadingDialog<T>(
  BuildContext context, {
  String message = '加载中...',
  Future<T>? task,
}) async {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black.withOpacity(0.85),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.textOnDark,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppColors.textOnDark, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 输入对话框
Future<String?> showWeChatInputDialog(
  BuildContext context, {
  required String title,
  String? hintText,
  String? initialValue,
  String confirmLabel = '确定',
  String cancelLabel = '取消',
  int maxLines = 1,
  bool obscureText = false,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => WeChatDialog(
      title: title,
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: obscureText,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        DialogAction(label: cancelLabel, value: ''),
        DialogAction(label: confirmLabel, value: controller.text),
      ],
    ),
  );
  if (result == null) return null;
  return controller.text;
}
