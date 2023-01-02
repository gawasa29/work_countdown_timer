import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:window_size/window_size.dart';

// サイズを設定するメソッド
void setupWindow() {
  // サイズを固定
  const double windowWidth = 400;
  const double windowHeight = 200;

  // webとプラットフォームをチェック
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    WidgetsFlutterBinding.ensureInitialized();
    setWindowTitle('sample');
    setWindowMinSize(const Size(windowWidth, windowHeight));
    setWindowMaxSize(const Size(windowWidth, windowHeight));
    getCurrentScreen().then((screen) {
      setWindowFrame(Rect.fromCenter(
        center: screen!.frame.center,
        width: windowWidth,
        height: windowHeight,
      ));
    });
  }
}

void main() {
  setupWindow(); // サイズを設定
  initializeDateFormatting('ja_JP'); //DateTimeを日本語に対応する
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? countdownTimer;
  bool timerState = false;
  bool startState = false;
  DateFormat outputFormat = DateFormat.yMMMMEEEEd('ja'); //フォーマットするだけの関数
  DateTime? startDay;
  DateTime? endDay;

  //自分のタイマーの時間の実体
  Duration myDuration = const Duration(hours: 80);
  @override
  void initState() {
    super.initState();
  }

  void startTimer() {
    countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => setCountDown());
  }

  void pauseTimer() {
    setState(() => countdownTimer!.cancel());
  }

  void resetTimer() {
    pauseTimer();
    setState(() => myDuration = const Duration(hours: 80));
  }

  void setCountDown() {
    const reduceSecondsBy = 1;
    setState(() {
      //一秒引く
      final seconds = myDuration.inSeconds - reduceSecondsBy;
      //タイマーがゼロになったら止まる
      if (seconds < 0) {
        countdownTimer!.cancel();
      } else {
        myDuration = Duration(seconds: seconds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    final hours = strDigits(myDuration.inHours);
    final minutes = strDigits(myDuration.inMinutes.remainder(60));
    final seconds = strDigits(myDuration.inSeconds.remainder(60));
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                (timerState)
                    ? IconButton(
                        onPressed: () {
                          if (countdownTimer == null ||
                              countdownTimer!.isActive) {
                            pauseTimer();
                            timerState = false;
                          }
                        },
                        icon: const Icon(Icons.pause))
                    : IconButton(
                        onPressed: () {
                          startTimer();
                          timerState = true;
                        },
                        icon: const Icon(Icons.play_arrow)),
                Text(
                  '$hours:$minutes:$seconds',
                  style: const TextStyle(fontSize: 60),
                ),
                IconButton(
                    onPressed: () {
                      resetTimer();
                      startState = false;
                      timerState = false;
                      startDay = null;
                      endDay = null;
                      setState(() {});
                    },
                    icon: const Icon(Icons.restart_alt)),
              ],
            ),
            (startState)
                ? const Text('')
                : ElevatedButton(
                    child: const Text('Start'),
                    onPressed: () {
                      startState = true;
                      timerState = true;
                      startDay = DateTime.now();
                      endDay = startDay!.add(const Duration(days: 7));
                      startTimer();
                      setState(() {});
                    },
                  ),
            const SizedBox(
              height: 30,
            ),
            Row(
              children: [
                Text(
                  '$hours:$minutes:$seconds',
                ),
                const SizedBox(
                  width: 10,
                ),
                const Text('S',
                    style: TextStyle(fontSize: 20, color: Colors.red)),
                Text((startDay == null) ? '' : outputFormat.format(startDay!)),
                const SizedBox(
                  width: 10,
                ),
                const Text('E',
                    style: TextStyle(fontSize: 20, color: Colors.red)),
                Text((endDay == null) ? '' : outputFormat.format(endDay!)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
