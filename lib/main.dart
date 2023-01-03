import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_size/window_size.dart';

// サイズを設定するメソッド
void setupWindow() {
  // サイズを固定
  const double windowWidth = 400;
  const double windowHeight = 300;

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
  Timer? toDayCountdownTimer;
  bool timerState = false;
  bool startState = false;
  DateFormat outputFormat = DateFormat.yMMMMEEEEd('ja'); //フォーマットするだけの関数
  DateTime? startDay;
  DateTime? endDay;

  //自分のタイマーの時間の実体
  Duration myDuration = const Duration(hours: 80);
  //今日のタイマー
  Duration? toDayDuration;
  @override
  void initState() {
    super.initState();
  }

//タイマー系の関数
  void startTimer() {
    //timer.periodicはfor文みたいに繰り返し処理
    //Timer.periodic(繰り返す間隔の時間, その間隔毎に動作させたい処理)
    countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => setCountDown());
  }

  void pauseTimer() {
    setState(() {
      countdownTimer!.cancel();
      if (toDayDuration != null) {
        toDayCountdownTimer!.cancel();
      }
    });
  }

  void resetTimer() {
    pauseTimer();
    setState(() => myDuration = const Duration(hours: 80));
    setState(() {
      myDuration = const Duration(hours: 80);
      toDayDuration = null;
    });
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
        //ローカルに保存
        saveDate();
      }
    });
  }

  void startToDayTimer() {
    toDayCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => setToDayCountDown());
  }

  void setToDayCountDown() {
    const reduceSecondsBy = 1;
    setState(() {
      //一秒引く
      final seconds = toDayDuration!.inSeconds - reduceSecondsBy;
      //タイマーがゼロになったら止まる
      if (seconds < 0) {
        toDayCountdownTimer!.cancel();
      } else {
        toDayDuration = Duration(seconds: seconds);
      }
    });
  }

  void saveDate() async {
    final prefs = await SharedPreferences.getInstance();
    //時間を保存
    prefs.setInt('hours', myDuration.inHours);
    prefs.setInt('minutes', myDuration.inMinutes.remainder(60));
    prefs.setInt('seconds', myDuration.inSeconds.remainder(60));

    //日付を保存
    prefs.setString('startDay', startDay.toString());
    prefs.setString('endDay', endDay.toString());
  }

  void readDate() async {
    final prefs = await SharedPreferences.getInstance();
//保存してたデータを時間の実体に代入
    myDuration = Duration(
        hours: prefs.getInt('hours')!,
        minutes: prefs.getInt('minutes')!,
        seconds: prefs.getInt('seconds')!);
    startDay = DateTime.parse(prefs.getString('startDay')!);
    endDay = DateTime.parse(prefs.getString('endDay')!);
  }

  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    final hours = strDigits(myDuration.inHours);
    final minutes = strDigits(myDuration.inMinutes.remainder(60));
    final seconds = strDigits(myDuration.inSeconds.remainder(60));

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton(
            itemBuilder: ((context) => [
                  PopupMenuItem(
                    child: const Text('today'),
                    onTap: () {
                      if (startDay != null && endDay != null) {
                        toDayDuration =
                            myDuration ~/ endDay!.difference(startDay!).inDays;
                        startToDayTimer();
                      }
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('read'),
                    onTap: () {
                      readDate();
                      startState = true;
                      setState(() {});
                    },
                  ),
                ]),
          ),
        ],
      ),
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
                          if (toDayDuration != null) {
                            startToDayTimer();
                          }
                        },
                        icon: const Icon(Icons.play_arrow)),
                (toDayDuration == null)
                    ? Text(
                        '$hours:$minutes:$seconds',
                        style: const TextStyle(fontSize: 60),
                      )
                    : Text(
                        '${strDigits(toDayDuration!.inHours)}:${strDigits(toDayDuration!.inMinutes.remainder(60))}:${strDigits(toDayDuration!.inSeconds.remainder(60))}',
                        style: const TextStyle(fontSize: 60),
                      ),
                IconButton(
                    onPressed: () {
                      resetTimer();
                      startState = false;
                      timerState = false;
                      startDay = null;
                      endDay = null;
                      toDayDuration = null;
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
