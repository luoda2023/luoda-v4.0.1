// AUTO-INJECTED RUNTIME LOGGER
//
// 运行期日志产出：所有 INFO/WARN/ERROR/DEBUG 写入本地文件，供后续排查错误。
// 日志路径：
//   Windows : %APPDATA%\LUODA\logs\luoda_runtime.log
//   macOS   : ~/Library/Logs/LUODA/luoda_runtime.log
//   Linux   : ~/.config/luoda/logs/luoda_runtime.log
// 超过 5MB 自动轮转（旧文件存为 .old）。
import 'dart:io';
import 'dart:convert';

class RuntimeLogger {
  static RuntimeLogger? _instance;
  File? _logFile;
  IOSink? _sink;
  bool _enabled = true;
  bool _initialized = false;
  static const int _maxBytes = 5 * 1024 * 1024; // 5MB 轮转阈值

  RuntimeLogger._();
  static RuntimeLogger get instance {
    _instance ??= RuntimeLogger._();
    return _instance!;
  }

  /// 应用启动早期调用一次即可（幂等）。失败不影响主流程。
  Future<void> init() async {
    if (_initialized) return;
    try {
      String basePath;
      if (Platform.isWindows) {
        basePath =
            (Platform.environment['APPDATA'] ?? 'C:\\LUODA') + '\\LUODA\\logs';
      } else if (Platform.isMacOS) {
        basePath =
            (Platform.environment['HOME'] ?? '/tmp') + '/Library/Logs/LUODA';
      } else {
        basePath =
            (Platform.environment['HOME'] ?? '/tmp') + '/.config/luoda/logs';
      }
      final dir = Directory(basePath);
      await dir.create(recursive: true);
      _logFile = File(dir.path + '/luoda_runtime.log');
      _sink = _logFile!.openWrite(mode: FileMode.append);
      _initialized = true;
      info('SYSTEM',
          'Runtime logger initialized on ' + Platform.operatingSystem);
    } catch (e) {
      _enabled = false;
    }
  }

  /// 日志文件完整路径（UI 展示用），未初始化时为 null。
  String? get logFilePath => _logFile?.path;

  /// 读取完整日志内容（UI 展示 / 复制用）。
  Future<String> readLog() async {
    try {
      final f = _logFile;
      if (f == null || !await f.exists()) return '(尚无日志文件)';
      return await f.readAsString();
    } catch (e) {
      return '(读取日志失败: $e)';
    }
  }

  /// 便捷方法：记录一次未捕获异常（含堆栈）。
  void logException(dynamic e, [StackTrace? stack]) {
    error('EXCEPTION',
        (e?.toString() ?? 'null') + '\n' + (stack?.toString() ?? ''));
  }

  void _rotateIfNeeded() {
    try {
      final f = _logFile;
      if (f == null || !f.existsSync()) return;
      if (f.lengthSync() > _maxBytes) {
        final old = File(f.path + '.old');
        if (old.existsSync()) old.deleteSync();
        f.renameSync(f.path + '.old');
        _sink?.close();
        _sink = f.openWrite(mode: FileMode.write); // 重新从头写
        info('SYSTEM', 'Log rotated (>$_maxBytes bytes)');
      }
    } catch (_) {
      // 轮转失败忽略，不影响写入
    }
  }

  void _write(String level, String tag, String message) {
    if (!_enabled) return;
    _rotateIfNeeded();
    final ts = DateTime.now().toUtc().toIso8601String();
    _sink?.write('[' + ts + '] [' + level + '] [' + tag + '] ' + message + '\n');
  }

  void info(String tag, String message) => _write('INFO', tag, message);
  void warn(String tag, String message) => _write('WARN', tag, message);
  void error(String tag, String message) => _write('ERROR', tag, message);
  void debug(String tag, String message) => _write('DEBUG', tag, message);
}
