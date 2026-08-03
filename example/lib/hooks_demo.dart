import 'package:flutter/material.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';
import 'hooks_demo_scene.dart';

class HooksDemoPage extends StatefulWidget { const HooksDemoPage({super.key}); @override State<HooksDemoPage> createState()=>_HooksDemoPageState(); }
class _HooksDemoPageState extends State<HooksDemoPage> {
  final ScrollController _scroll=ScrollController(); late final MotionPathSpawnController _spawns; late final MotionPathScrollDriver _driver;
  @override void initState(){super.initState(); _spawns=MotionPathSpawnController(parent: MotionPathTrackRuntime('hooks-demo')); for(final t in hooksDemoSceneTracks()) _spawns.spawn(t); _driver=MotionPathScrollDriver(binding: const MotionPathScrollBinding(end: 900),onProgress:(p)=>_spawns.advanceTo(p)); WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)_driver.attach(_scroll);});}
  @override void dispose(){_driver.dispose();_spawns.dispose();_scroll.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFF08070D),appBar:AppBar(title:const Text('MotionPath Hooks Demo')),body:LayoutBuilder(builder:(context,c)=>Stack(fit:StackFit.expand,children:[const _HooksBackdrop(),Center(child:SizedBox(width:900,height:500,child:MotionPathSpawnView(alignment:Alignment.center,controller:_spawns,itemBuilder:(context,i)=>_HooksItem(id:i.id)))),ListView(controller:_scroll,children:[SizedBox(height:c.maxHeight+900),const Padding(padding:EdgeInsets.all(32),child:Text('Direct patch consumption, zero widget rebuilds in the motion layer.'))])])));
}
class _HooksItem extends StatelessWidget { const _HooksItem({required this.id}); final String id; @override Widget build(BuildContext context)=>id=='rocket-track'?const Text('🚀',style:TextStyle(fontSize:54)):const Text('☁️',style:TextStyle(fontSize:58)); }
class _HooksBackdrop extends StatelessWidget { const _HooksBackdrop(); @override Widget build(BuildContext context)=>const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[Color(0xFF171044),Color(0xFF08070D)])),child:SizedBox.expand()); }
