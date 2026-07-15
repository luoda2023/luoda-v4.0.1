// flutter/lib/ui/pages/terminal_page.dart
// 远程终端页面（微信风格）

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class TerminalPage extends StatefulWidget {
 final String deviceId;
 const TerminalPage({Key? key, required this.deviceId}) : super(key: key);

 @override
 State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
 final TextEditingController _controller = TextEditingController();
 final List<String> _history = [];
 final ScrollController _scroll = ScrollController();
 bool _isLoading = false;

 @override
 void dispose() {
 _controller.dispose();
 _scroll.dispose();
 super.dispose();
 }

 Future<void> _send() async {
 final cmd = _controller.text.trim();
 if (cmd.isEmpty) return;
 setState(() {
 _history.add('> $cmd');
 _history.add('[输出] 命令执行 -> ${widget.deviceId}');
 _controller.clear();
 });
 WidgetsBinding.instance.addPostFrameCallback((_)=> _scrollToBottom());
 }

 void _scrollToBottom(){
 if(_scroll.hasClients)_scroll.jumpTo(_scroll.position.maxScrollExtent);
}

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(
 title: Text('终端 - ${widget.deviceId}'),
 backgroundColor: AppColors.primaryGreen,
 actions: [
 IconButton(icon: const Icon(Icons.clear_all), onPressed: ()=>setState(()=>_history.clear())),
 IconButton(icon: const Icon(Icons.refresh), onPressed: ()=>setState(()=>_isLoading=!_isLoading)),
 ],
 ),
 body: Column(children:[
Expanded(child:Container(
color: AppColors.background,
child:ListView.builder(
controller:_scroll,
itemCount:_history.length,
padding:const EdgeInsets.all(12),
itemBuilder:(_,i){
final line=_history[i];
final cmd=line.startsWith('> ');
return SelectableText(line,style:TextStyle(
fontFamily:'monospace',fontSize:12,color:cmd?AppColors.primaryGreenLight:AppColors.textPrimary
));
}
),
)),
Container(
padding:const EdgeInsets.all(8),
color:AppColors.cardBg,
child:Row(children:[Expanded(child:TextField(
controller:_controller,
decoration:const InputDecoration(
hintText:'输入命令...',
border:OutlineInputBorder(),
contentPadding:EdgeInsets.symmetric(horizontal:12,vertical:8),
style:TextStyle(fontFamily:'monospace',fontSize:13)
),onSubmitted:_send,),),
IconButton(icon:const Icon(Icons.send),onPressed:_send)]))
])
);
}
}
