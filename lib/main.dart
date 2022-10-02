import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:windows_in_app_updater/constant.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isDownloading = false;
  double downloadProgress = 0;
  String downloadedFilePath = '';

  Future<Map<String, dynamic>> loadJsonFile() async {
    final response = await http.read(
      Uri.parse(
          'https://raw.githubusercontent.com/ekokurniadi/windows_in_app_updater_version/master/version.json'),
    );
    return jsonDecode(response);
  }

  Future<void> _checkUpdateVersion() async {
    final result = await loadJsonFile();
    print(result);
    await showUpdateDialog(result);
  }

  Future<void> showUpdateDialog(Map<String, dynamic> json) async {
    final latestVersion = json['version'];
    final changeLog = json['change_log'] as List;

    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            contentPadding: const EdgeInsets.all(10),
            title: Text('Latest Version $latestVersion'),
            children: [
              Text('What\'s new in version $latestVersion'),
              const SizedBox(
                height: 5,
              ),
              ...changeLog
                  .map(
                    (e) => Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.blue[400],
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text('$e')
                      ],
                    ),
                  )
                  .toList(),
              const SizedBox(
                height: 10,
              ),
              latestVersion > Constant.currentVersion
                  ? ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await updateVersion(json['installer_path']);
                      },
                      child: Text('Update Now'),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Close'),
                    )
            ],
          );
        });
  }

  Future<void> updateVersion(String remotePath) async {
    print(remotePath);
    final appFileName = remotePath.split('/').last;
    setState(() {
      isDownloading = true;
    });

    final dio = Dio();
    final appDirectory = (await getApplicationDocumentsDirectory()).path;

    downloadedFilePath = '$appDirectory/$appFileName';

    await dio.download(
      'https://github.com/ekokurniadi/windows_in_app_updater_version/raw/master/$remotePath',
      downloadedFilePath,
      onReceiveProgress: (count, total) {
        final progress = (count / total) * 100;
        print('Download Receive : $count, progress : $progress');
        setState(() {
          downloadProgress = double.parse(progress.toStringAsFixed(1));
        });
      },
    );
    await executeExeFile(downloadedFilePath);

    setState(() {
      isDownloading = false;
    });
  }

  Future<void> executeExeFile(String filePath) async {
    await Process.start(filePath, ['-t', '-l', '1000']).then((value) {
      print(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.orange,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Current Version Of App ${Constant.currentVersion}',
            ),
            const SizedBox(height: 5),
            Visibility(
              visible: isDownloading,
              child: Text('Download progress :$downloadProgress'),
            ),
            const SizedBox(height: 5),
            ElevatedButton(
                onPressed: () async {
                  await _checkUpdateVersion();
                },
                child: const Text('Check update'))
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
