import 'package:luoda_flutter/common.dart';
import 'package:get/get.dart';

import '../consts.dart';

// Generic helper to reduce repetitive init/delete/find boilerplate.
// Usage: SharedStateHelper<RxString>('privacy_mode', '').init(id)
class _SharedStateHelper<T> {
  final String _tagBase;
  final T Function() _defaultValue;
  _SharedStateHelper(this._tagBase, this._defaultValue);

  String tag(String id) => '${_tagBase}_$id';

  void init(String id) {
    if (!Get.isRegistered<T>(tag: tag(id))) {
      Get.put<T>(_defaultValue(), tag: tag(id));
    }
  }

  void delete(String id) {
    if (Get.isRegistered<T>(tag: tag(id))) {
      Get.delete<T>(tag: tag(id));
    }
  }

  T find(String id) => Get.find<T>(tag: tag(id));
}

class PrivacyModeState {
  static final _h = _SharedStateHelper<RxString>('privacy_mode', () => ''.obs);
  static String tag(String id) => _h.tag(id);
  static void init(String id) => _h.init(id);
  static void delete(String id) => _h.delete(id);
  static RxString find(String id) => _h.find(id);
}

class BlockInputState {
  static final _h = _SharedStateHelper<RxBool>('block_input', () => false.obs);
  static String tag(String id) => _h.tag(id);
  static void init(String id) => _h.init(id);
  static void delete(String id) => _h.delete(id);
  static RxBool find(String id) => _h.find(id);
}

class CurrentDisplayState {
  static final _h = _SharedStateHelper<RxInt>('current_display', () => RxInt(0));
  static String tag(String id) => _h.tag(id);
  static void init(String id) => _h.init(id);
  static void delete(String id) => _h.delete(id);
  static RxInt find(String id) => _h.find(id);
}

class ConnectionType {
  final Rx<String> _secure = kInvalidValueStr.obs;
  final Rx<String> _direct = kInvalidValueStr.obs;
  final Rx<String> _stream_type = kInvalidValueStr.obs;

  Rx<String> get secure => _secure;
  Rx<String> get direct => _direct;
  Rx<String> get stream_type => _stream_type;

  static String get strSecure => 'secure';
  static String get strInsecure => 'insecure';
  static String get strDirect => '';
  static String get strIndirect => '_relay';

  void setSecure(bool v) {
    _secure.value = v ? strSecure : strInsecure;
  }

  void setDirect(bool v) {
    _direct.value = v ? strDirect : strIndirect;
  }

  void setStreamType(String v) {
    _stream_type.value = v;
  }

  bool isValid() {
    return _secure.value != kInvalidValueStr &&
        _direct.value != kInvalidValueStr &&
        _stream_type.value != kInvalidValueStr;
  }
}

class ConnectionTypeState {
  static final _h = _SharedStateHelper<ConnectionType>('connection_type', () => ConnectionType());
  static String tag(String id) => _h.tag(id);
  static void init(String id) => _h.init(id);
  static void delete(String id) => _h.delete(id);
  static ConnectionType find(String id) => _h.find(id);
}

class FingerprintState {
  static final _h = _SharedStateHelper<RxString>('fingerprint', () => ''.obs);
  static String tag(String id) => _h.tag(id);
  static void init(String id) => _h.init(id);
  static void delete(String id) => _h.delete(id);
  static RxString find(String id) => _h.find(id);
}

class ShowRemoteCursorState {
  static final _h = _SharedStateHelper<RxBool>('show_remote_cursor', () => false.obs);
  static String tag(String id) => _h.tag(id);
  static void init(String id) => _h.init(id);
  static void delete(String id) => _h.delete(id);
  static RxBool find(String id) => _h.find(id);
}

class ShowRemoteCursorLockState {
  static final _h = _SharedStateHelper<RxBool>('show_remote_cursor_lock', () => false.obs);
  static String tag(String id) => _h.tag(id);
  static void init(String id) => _h.init(id);
  static void delete(String id) => _h.delete(id);
  static RxBool find(String id) => _h.find(id);
}

class KeyboardEnabledState {
  static final _h = _SharedStateHelper<RxBool>('keyboard_enabled', () => true.obs);
  static String tag(String id) => _h.tag(id);
  static void init(String id) => _h.init(id);
  static void delete(String id) => _h.delete(id);
  static RxBool find(String id) => _h.find(id);
}

class RemoteCursorMovedState {
  static final _h = _SharedStateHelper<RxBool>('remote_cursor_moved', () => false.obs);
  static String tag(String id) => _h.tag(id);
  static void init(String id) => _h.init(id);
  static void delete(String id) => _h.delete(id);
  static RxBool find(String id) => _h.find(id);
}

class RemoteCountState {
  static final _h = _SharedStateHelper<RxInt>('remote_count_', () => 1.obs);
  static String tag() => _h.tag('');
  static void init() => _h.init('');
  static void delete() => _h.delete('');
  static RxInt find() => _h.find('');
}

class PeerBoolOption {
  static String tag(String id, String opt) => 'peer_{$opt}_$id';

  static void init(String id, String opt, bool Function() init_getter) {
    final key = tag(id, opt);
    if (!Get.isRegistered<RxBool>(tag: key)) {
      final RxBool value = RxBool(init_getter());
      Get.put<RxBool>(value, tag: key);
    } else {
      Get.find<RxBool>(tag: key).value = init_getter();
    }
  }

  static void delete(String id, String opt) {
    final key = tag(id, opt);
    if (Get.isRegistered<RxBool>(tag: key)) {
      Get.delete<RxBool>(tag: key);
    }
  }

  static RxBool find(String id, String opt) =>
      Get.find<RxBool>(tag: tag(id, opt));
}

class PeerStringOption {
  static String tag(String id, String opt) => 'peer_{$opt}_$id';

  static void init(String id, String opt, String Function() init_getter) {
    final key = tag(id, opt);
    if (!Get.isRegistered<RxString>(tag: key)) {
      final RxString value = RxString(init_getter());
      Get.put<RxString>(value, tag: key);
    } else {
      Get.find<RxString>(tag: key).value = init_getter();
    }
  }

  static void delete(String id, String opt) {
    final key = tag(id, opt);
    if (Get.isRegistered<RxString>(tag: key)) {
      Get.delete<RxString>(tag: key);
    }
  }

  static RxString find(String id, String opt) =>
      Get.find<RxString>(tag: tag(id, opt));
}

class UnreadChatCountState {
  static final _h = _SharedStateHelper<RxInt>('unread_chat_count', () => RxInt(0));
  static String tag(String id) => _h.tag(id);
  static void init(String id) => _h.init(id);
  static void delete(String id) => _h.delete(id);
  static RxInt find(String id) => _h.find(id);
}

initSharedStates(String id) {
  PrivacyModeState.init(id);
  BlockInputState.init(id);
  CurrentDisplayState.init(id);
  KeyboardEnabledState.init(id);
  ShowRemoteCursorState.init(id);
  ShowRemoteCursorLockState.init(id);
  RemoteCursorMovedState.init(id);
  FingerprintState.init(id);
  PeerBoolOption.init(id, kOptionZoomCursor, () => false);
  UnreadChatCountState.init(id);
  if (isMobile) ConnectionTypeState.init(id); // desktop in other places
}

removeSharedStates(String id) {
  PrivacyModeState.delete(id);
  BlockInputState.delete(id);
  CurrentDisplayState.delete(id);
  ShowRemoteCursorState.delete(id);
  ShowRemoteCursorLockState.delete(id);
  KeyboardEnabledState.delete(id);
  RemoteCursorMovedState.delete(id);
  FingerprintState.delete(id);
  PeerBoolOption.delete(id, kOptionZoomCursor);
  UnreadChatCountState.delete(id);
  if (isMobile) ConnectionTypeState.delete(id);
}
