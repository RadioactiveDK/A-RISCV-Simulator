import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'home screen',
      home: MyHomeScreen(),
    ),
  );
}

class MyHomeScreen extends StatelessWidget{
  const MyHomeScreen({super.key});
  @override
  Widget build(BuildContext context){
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children:[
            ListTile(
              title: const Text('Single-Cycle'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SingleCycle(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Computer Architecture'),
      ),
      body: MyHome()
    );
  }
}

class MyHome extends StatelessWidget{
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: const TextSpan(
          text: 'Let\'s study ',
          style: TextStyle(fontSize: 32,color: Colors.black54),
          children: <TextSpan>[
            TextSpan(
                text: 'Computer Architecture!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 64,
                )
            ),
          ],
        ),
      ),
    );
  }
}



class SingleCycle extends StatelessWidget{
  const SingleCycle({super.key});
  void myFilePicker()async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result==null) return;
    PlatformFile myFile = result.files.single;
    SingleCycleCode(myFile);
  }
  void SingleCycleCode(PlatformFile myFile)async{
    print(Directory(myFile.path!).parent.path);
    print(basenameWithoutExtension(myFile.path!));
    File myOutFile = File('${Directory(myFile.path!).parent.path}\\${basenameWithoutExtension(myFile.path!)}_output.txt');
    await myOutFile.writeAsString('hello world');
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
          ),
          title: const Text('Single Cycle'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: (){
                myFilePicker();
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Information'),
                    content: const Text('Once file is selected, the output file will be created in the same directory.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'OK'),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Open File'),
            )
          ],
        ),
        body: MySingleCycleBody()
    );
  }
}

class MySingleCycleBody extends StatelessWidget{
  const MySingleCycleBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: const TextSpan(
          text: 'Let\'s study ',
          style: TextStyle(fontSize: 32,color: Colors.black54),
          children: <TextSpan>[
            TextSpan(
                text: 'Computer Architecture!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 64,
                )
            ),
          ],
        ),
      ),
    );
  }
}
