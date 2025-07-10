import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/theme_provider.dart';



class ThemeChange extends ConsumerWidget {

  static const name ='theme_change';

  const ThemeChange({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {

    final isdarkmode = ref.watch(isDarkModeProvider);
    
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambio de tema'),
        actions: [
          IconButton(
            onPressed: (){
              ref.read(isDarkModeProvider.notifier).update((state)=>!state);
         }, 
          icon: Icon(isdarkmode ? Icons.dark_mode_outlined: Icons.light_mode_outlined )),
        ],
      ),

      body: _ThemeChangerView(),
    );
  }
}

class _ThemeChangerView extends ConsumerWidget {
  const _ThemeChangerView();

  @override
  Widget build(BuildContext context, ref) {

    final List<Color> colors= ref.watch(colorListProvider);
    final int selectedColor= ref.watch(selectColorProvider);
    
    return ListView.builder(
      itemCount: colors.length,
      itemBuilder: (context,index){
         final Color color= colors[index];
         return RadioListTile(
          title: Text('Este color', style: TextStyle(color:color),),
          // ignore: deprecated_member_use
          subtitle: Text('${color.value}'),
          activeColor: color,
          value: index,
          groupValue: selectedColor,
          onChanged: (value) {
            ref.read(selectColorProvider.notifier).state=index;
          },
         );
       },
      );
  }
}