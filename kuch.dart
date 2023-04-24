import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:arrow_path/arrow_path.dart';
import 'dart:math';



void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'home screen',
      home: MyHomeScreen(),
    ),
  );
}

class MyHomeScreen extends StatelessWidget {
  const MyHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Drawer(
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(10),
                    )),
                child: Text(
                  'Execution\nType',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              ListTile(
                title: const Text('Pipelined with Caches'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PipelinedWithCaches(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: const Text('RISCV-32I Simulator'),
        ),
        body: PipelinedWithCaches());
  }
}

class BTB{
  var address;
  var branchtarget;
  var branchtaken;
  BTB(int address,int branchtarget,bool branchtaken){
    this.address=address;
    this.branchtaken=branchtaken;
    this.branchtarget=branchtarget;
  }
}

class PipelinedWithCaches extends StatefulWidget {
  const PipelinedWithCaches({Key? key}) : super(key: key);

  @override
  State<PipelinedWithCaches> createState() => _PipelinedWithCachesState();
}
class _PipelinedWithCachesState extends State<PipelinedWithCaches> {
  int whatDisplay=0;
  int displayStep=0;
  PlatformFile? myFile;

  void myFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mc'],
    );
    if (result == null) return;
    myFile = result.files.single;
    String strPath =
        '${Directory(myFile!.path!).parent.path}\\${basenameWithoutExtension(myFile!.path!)}_PipelinedWithCaches.txt';
    File outputFile = File(strPath);
    File inputFile = File(myFile!.name);

    solvePipelinedWithCaches.datacache=new Cache(solvePipelinedWithCaches.row,solvePipelinedWithCaches.col);
    solvePipelinedWithCaches.inscache=new Cache(solvePipelinedWithCaches.row,solvePipelinedWithCaches.col);
    if (solvePipelinedWithCaches.row % solvePipelinedWithCaches.inscache.way != 0 || solvePipelinedWithCaches.inscache.way <= 0 || solvePipelinedWithCaches.row % solvePipelinedWithCaches.datacache.way != 0 || solvePipelinedWithCaches.datacache.way <= 0) {
      print("invalid inputs to cache.");
      exit(0);
    }
    solvePipelinedWithCaches.inscache.INSorMEM=true;

    List<String> str=inputFile.readAsLinesSync();
    for(int i=0;i<str.length;i++)
    {solvePipelinedWithCaches.n.add(str[i]);}
    solvePipelinedWithCaches.RF[2]=2147483644;
    solvePipelinedWithCaches.buffer.add(new BTB(-1,-1,false));
    solvePipelinedWithCaches.load_progmem();
    solvePipelinedWithCaches.run_riscvsim(outputFile);
    displayStep=0;
    setState((){});
  }

  displayRF() {
    List<String> rf=solvePipelinedWithCaches.outputReg[displayStep].split('\t');
    var RFlist = <Widget>[];
    for (int i = 0; i < 33; i+=11) {
      RFlist.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          SizedBox(width: 150,),
          Container(
            height: 25,
            child: Text("x${i}: ${rf[i]}",style:TextStyle(fontSize: 16)),
          ),
          Container(
            height: 25,
            child: Text("x${i + 1}: ${rf[i + 1]}",style:TextStyle(fontSize: 16)),
          ),
          Container(
            height: 25,
            child: Text("x${i + 2}: ${rf[i + 2]}",style:TextStyle(fontSize: 16)),
          ),
          Container(
            height: 25,
            child: Text("x${i + 3}: ${rf[i + 3]}",style:TextStyle(fontSize: 16)),
          ),
          Container(
            height: 25,
            child: Text("x${i + 4}: ${rf[i + 4]}",style:TextStyle(fontSize: 16)),
          ),
          Container(
            height: 25,
            child: Text("x${i + 5}: ${rf[i + 5]}",style:TextStyle(fontSize: 16)),
          ),
          Container(
            height: 25,
            child: Text("x${i + 6}: ${rf[i + 6]}",style:TextStyle(fontSize: 16)),
          ),
          Container(
            height: 25,
            child: Text("x${i + 7}: ${rf[i + 7]}",style:TextStyle(fontSize: 16)),
          ),
          Container(
            height: 25,
            child: Text("x${i + 8}: ${rf[i + 8]}",style:TextStyle(fontSize: 16)),
          ),
          Container(
            height: 25,
            child: Text("x${i + 9}: ${rf[i + 9]}",style:TextStyle(fontSize: 16)),
          ),
          if(i!=22)
            Container(
              height: 25,
              child: Text("x${i + 10}: ${rf[i + 10]}",style:TextStyle(fontSize: 16)),
            ),
        ],
      ));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,crossAxisAlignment: CrossAxisAlignment.start,children: RFlist);
  }

  displayPR(){
    List<String> a1=[];
    List<String> a2=[];
    List<String> a3=[];
    List<String> a4=[];

    if(solvePipelinedWithCaches.IFDE[displayStep] !=null) a1 = solvePipelinedWithCaches.IFDE[displayStep]!.split('\t');
    if(solvePipelinedWithCaches.DEEX[displayStep] !=null) a2 = solvePipelinedWithCaches.DEEX[displayStep]!.split('\t');
    if(solvePipelinedWithCaches.EXMA[displayStep] !=null) a3 = solvePipelinedWithCaches.EXMA[displayStep]!.split('\t');
    if(solvePipelinedWithCaches.EXMA[displayStep] !=null) a4 = solvePipelinedWithCaches.EXMA[displayStep]!.split('\t');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 400,),
        if(whatDisplay==1)Column(
            children:[
              (solvePipelinedWithCaches.IFDE[displayStep]==null)?const SelectableText('Empty'):
              Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('PC:\t'),
                      SelectableText(a1[0]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('INSTRUCTION:\t'),
                      SelectableText(a1[1]),
                    ],
                  ),
                ],
              )
            ]
        ),
        if(whatDisplay==2)Column(
            children:[
              (solvePipelinedWithCaches.IFDE[displayStep]==null)?const SelectableText('Empty'):
              Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('PC:\t'),
                      SelectableText(a2[0]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('INSTRUCTION:\t'),
                      SelectableText(a2[1]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('OP2:\t'),
                      SelectableText(a2[2]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('OP1:\t'),
                      SelectableText(a2[3]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('IMMEDIATE:\t'),
                      SelectableText(a2[4]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('BRANCH TARGET:\t'),
                      SelectableText(a2[5]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('OP2 SELECT:\t'),
                      SelectableText(a2[6]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('ALU OP:\t'),
                      SelectableText(a2[7]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('BRANCH SELECT:\t'),
                      SelectableText(a2[8]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('RESULT SELECT:\t'),
                      SelectableText(a2[9]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('MEMORY OP:\t'),
                      SelectableText(a2[10]),
                    ],
                  ),
                  Row(

                    children: [
                      SizedBox(width:170),
                      SelectableText('RF WRITE:\t'),
                      SelectableText(a2[11]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('IS BRANCH:\t'),
                      SelectableText(a2[12]),
                    ],
                  ),

                ],
              )
            ]
        ),
        if(whatDisplay==3)Column(
            children:[
              (solvePipelinedWithCaches.IFDE[displayStep]==null)?const SelectableText('Empty'):
              Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('PC:\t'),
                      SelectableText(a3[0]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('INSTRUCTION:\t'),
                      SelectableText(a3[1]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('ALU RESULT:\t'),
                      SelectableText(a3[2]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('OP2:\t'),
                      SelectableText(a3[3]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('MEMORY OP:\t'),
                      SelectableText(a3[4]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('RESULT SELECT:\t'),
                      SelectableText(a3[5]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('RF WRITE:\t'),
                      SelectableText(a3[6]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('IS BRANCH:\t'),
                      SelectableText(a3[7]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('IMMEDIATE:\t'),
                      SelectableText(a3[8]),
                    ],
                  ),
                ],
              )
            ]
        ),
        if(whatDisplay==4)Column(
            children:[
              (solvePipelinedWithCaches.IFDE[displayStep]==null)?const SelectableText('Empty'):
              Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('PC:\t'),
                      SelectableText(a4[0]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('INSTRUCTION:\t'),
                      SelectableText(a4[1]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('RESULT:\t'),
                      SelectableText(a4[2]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('RF WRITE:\t'),
                      SelectableText(a4[3]),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width:170),
                      SelectableText('IS BRANCH:\t'),
                      SelectableText(a4[4]),
                    ],
                  ),
                ],
              )
            ]
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Pipelined Execution'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: 'Select .mc file',
            onPressed: () {
              myFilePicker();
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Information'),
                  content: const Text(
                      'If a file is selected, the output file will be created in the same directory.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'OK'),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                    width: 500,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (displayStep < solvePipelinedWithCaches.count) {
                              displayStep++;
                              setState((){});
                            }
                          },
                          child: const Text('Step'),
                        ),
                        ElevatedButton(
                            onPressed: (){
                              displayStep=solvePipelinedWithCaches.count;
                              setState(() {});
                            },

                            child: const Text('Run')),
                        ElevatedButton(
                            onPressed: (){
                              displayStep = 0;
                              setState((){});
                            },
                            child: const Text('Reset')),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(primary:(solvePipelinedWithCaches.knob2)?Colors.green:Colors.redAccent),
                            onPressed: (){
                              solvePipelinedWithCaches.knob2=!solvePipelinedWithCaches.knob2;
                              displayStep=0;
                              setState((){});
                            },
                            child: const Text('Forwarding'))
                        ,
                      ],
                    )),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                    child: Container(
                      width: 500,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 1,
                        ),
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SelectableText(
                          (displayStep==solvePipelinedWithCaches.count)?solvePipelinedWithCaches.displayTxt:solvePipelinedWithCaches.showTxt(displayStep),
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 5),
                Expanded(
                    child: Container(
                      width: 500,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 1,
                        ),
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children: [
                            Text(
                              (whatDisplay==0)?'Register File':
                              (whatDisplay==1)?'IF-DE Pipeline Registers':
                              (whatDisplay==2)?'DE-EX Pipeline Registers':
                              (whatDisplay==3)?'EX-MA Pipeline Registers':
                              'MA-WB Pipeline Registers',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            if (myFile != null)
                              (whatDisplay==0)?displayRF():displayPR(),
                          ],
                        ),
                      ),
                    ))
              ],
            ),
            const SizedBox(width: 15),
            ExecutionDiagram(isPipelined: true,updateDisplay: (int v){whatDisplay=v;setState(() {});},)
          ],
        ),
      ),
    );
  }
}
class Cache{
  int policy = 0, //random,lru,fifo
      mapping = 0,
      way = 2;
  var cache ;
  var dirty ;
  var status ;
  var filled ;
  var tag ;
  int accesses=0,
      hits=0,
      misses=0,
      coldmisses=0,
      conflictmisses=0,
      capacitymisses=0,
      penalty=20,
      hittime=1,
      totalstalls=0;
  bool INSorMEM=false;
  Cache(int row,int col){
    this.cache=List.generate(row, (i) => List.filled(col, 0, growable: false),growable: false);
    this.dirty = List.generate(row, (i) => 0, growable: false);
    this.status = List.generate(row, (i) => 0, growable: false);
    this.filled = List.generate(row, (i) => 0, growable: false);
    this.tag = List.generate(row, (i) => -1, growable: false);
  }

  void replace(int i, int block, int tagelement) {
    solvePipelinedWithCaches.stop=20;
    this.misses++;
    totalstalls+=penalty;
    if(INSorMEM==true && solvePipelinedWithCaches.INScold.contains(tagelement)==false)this.coldmisses++;
    else if(INSorMEM==false && solvePipelinedWithCaches.MEMcold.contains(tagelement)==false)this.coldmisses++;
    else{
      if(INSorMEM==true && solvePipelinedWithCaches.INSconflict.contains(tagelement)==true && this.mapping!=1)this.conflictmisses++;
      else if(INSorMEM==false && solvePipelinedWithCaches.MEMconflict.contains(tagelement)==true && this.mapping!=1)this.conflictmisses++;
      else this.capacitymisses++;
    }
    if(INSorMEM==true)solvePipelinedWithCaches.INScold.add(tagelement);
    else solvePipelinedWithCaches.MEMcold.add(tagelement);
    //|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    int base = block * (4 * solvePipelinedWithCaches.col);
    //if (dirty[i] == 1) writeBlock(i);
    tag[i] = tagelement;
    filled[i] = 1;
    dirty[i] = 0;
    if (policy == 1 || policy == 2) status[i] = solvePipelinedWithCaches.col - 1;
    for (int j = 0; j < solvePipelinedWithCaches.col; j++) {
      if(INSorMEM==false)
        cache[i][j] = solvePipelinedWithCaches.MEM[base + (4 * j)] ?? 0;
      else
        cache[i][j] = solvePipelinedWithCaches.INS[base + (4 * j)] ?? 0;
    }
  }

  int getnumber(int address,bool cacheop,int data) {
    this.accesses++;//|||||||||||||||||||||||||

    int block = address ~/ (4 * solvePipelinedWithCaches.col);
    int offset = address & ((4 * solvePipelinedWithCaches.col) - 1);
    offset = offset >> 2;
    int index = block & (solvePipelinedWithCaches.row - 1);
    int tagelement = block ~/ (solvePipelinedWithCaches.row);
    ///////////////1:-     DIRECT MAPPING     //////////////
    if (mapping == 0) {
      if (tag[index] != tagelement) {

        if(INSorMEM==true)solvePipelinedWithCaches.INSconflict.add((tag[index]*solvePipelinedWithCaches.row)+index);
        else solvePipelinedWithCaches.MEMconflict.add((tag[index]*solvePipelinedWithCaches.row)+index);

        replace(index, block, tagelement);}
      else this.hits++;//|||||||||||||||||||||||

      if(cacheop==true){
        solvePipelinedWithCaches.MEM[address]=data;
        cache[index][offset]=data;
        dirty[index]=1;
      }

      return cache[index][offset];
    }

    //fullyassociative
    else if (mapping == 1) {
      //////////////////////////////////////finding current block in cache////////////////////////////////
      int statusBit = 0;
      for (int i = 0; i < solvePipelinedWithCaches.row; i++) {
        if (filled[i] == 1) statusBit++;
        if (tag[i] == block) {
          this.hits++;//|||||||||||||||||||||||||
          if (policy == 1) {
            statusBit = 0;
            for (int j = 0; j < solvePipelinedWithCaches.row; j++) {
              if (status[j] > status[i]) status[j]--;
              if (filled[j] == 1) statusBit++;
            }
            status[i] = statusBit - 1;
          }
          if(cacheop==true){
            solvePipelinedWithCaches.MEM[address]=data;
            cache[i][offset]=data;
            dirty[i]=1;
          }

          return cache[i][offset];
        }
      }
      ///////////////////////////////////chaecking for empty space in cache for new block////////////////////////
      for (int i = 0; i < solvePipelinedWithCaches.row; i++) {
        if (filled[i] == 0) {
          //add condition for new status number
          replace(i, block, block);
          status[i] = statusBit;
          if(cacheop==true){
            solvePipelinedWithCaches.MEM[address]=data;
            cache[i][offset]=data;
            dirty[i]=1;
          }

          return cache[i][offset];
        }
      }
      ///////////////////////////////////replacing a victim////////////////////////////////////////////////////////
      ///// 1:-        Random Policy
      if (policy == 0) {
        Random random = new Random();
        int i = random.nextInt(solvePipelinedWithCaches.row);

        if(INSorMEM==true)solvePipelinedWithCaches.INSconflict.add(tag[i]);
        else solvePipelinedWithCaches.MEMconflict.add(tag[i]);

        replace(i, block, block);
        if(cacheop==true){
          solvePipelinedWithCaches.MEM[address]=data;
          cache[i][offset]=data;
          dirty[i]=1;
        }

        return cache[i][offset];
      }
      ///// 2:-        LRU policy or FIFO policy
      else {
        int index = 0;
        for (int i = 0; i < solvePipelinedWithCaches.row; i++) {
          if (status[i] > 0)
            status[i]--;
          else
            index = i;
        }

        if(INSorMEM==true)solvePipelinedWithCaches.INSconflict.add(tag[index]);
        else solvePipelinedWithCaches.MEMconflict.add(tag[index]);

        replace(index, block, block);
        status[index] = solvePipelinedWithCaches.row - 1;
        if(cacheop==true){
          solvePipelinedWithCaches.MEM[address]=data;
          cache[index][offset]=data;
          dirty[index]=1;
        }

        return cache[index][offset];
      }
    }
    ///////////////////////////////////////////SET associative////////////////////////////////////////
    else {
      int set = way * (block % (solvePipelinedWithCaches.row ~/ way));
      tagelement = block ~/ (solvePipelinedWithCaches.row ~/ way);

      int statusBit = 0;

      for (int i = set; i < set + way; i++) {
        if (filled[i] == 1) statusBit++;
        if (tag[i] == tagelement) {

          this.hits++;//|||||||||||||||||||||||||||||||||||||||||||
          if (policy == 1) {
            statusBit = 0;
            for (int j = set; j < set + way; j++) {
              if (status[j] > status[i]) status[j]--;
              if (filled[j] == 1) statusBit++;
            }
            status[i] = statusBit - 1;
          }
          if(cacheop==true){
            solvePipelinedWithCaches.MEM[address]=data;
            cache[i][offset]=data;
            dirty[i]=1;
          }

          return cache[i][offset];
        }
      }

      ///////////////////////////////////chaecking for empty space in cache for new block////////////////////////
      for (int i = set; i < set + way; i++) {
        if (filled[i] == 0) {
          //add condition for new status number
          //print("new added");
          replace(i, block, tagelement);
          status[i] = statusBit;
          if(cacheop==true){
            solvePipelinedWithCaches.MEM[address]=data;
            cache[i][offset]=data;
            dirty[i]=1;
          }

          return cache[i][offset];
        }
      }
      ///////////////////////////////////replacing a victim////////////////////////////////////////////////////////
      ///// 1:-        Random Policy
      if (policy == 0) {
        Random random = new Random();
        int i = set + random.nextInt(way);

        if(INSorMEM==true)solvePipelinedWithCaches.INSconflict.add((tag[i]*(solvePipelinedWithCaches.row ~/ way))+set);
        else solvePipelinedWithCaches.MEMconflict.add((tag[i]*(solvePipelinedWithCaches.row ~/ way))+set);

        replace(i, block, tagelement);
        if(cacheop==true){
          solvePipelinedWithCaches.MEM[address]=data;
          cache[i][offset]=data;
          dirty[i]=1;
        }

        return cache[i][offset];
      }
      //////2:-        LRU policy or FIFO policy
      else {
        int index = 0;
        for (int i = set; i < set + way; i++) {
          if (status[i] > 0)
            status[i]--;
          else
            index = i;
        }

        if(INSorMEM==true)solvePipelinedWithCaches.INSconflict.add((tag[index]*(solvePipelinedWithCaches.row ~/ way))+set);
        else solvePipelinedWithCaches.MEMconflict.add((tag[index]*(solvePipelinedWithCaches.row ~/ way))+set);

        replace(index, block, tagelement);
        status[index] = way - 1;
        if(cacheop==true){
          solvePipelinedWithCaches.MEM[address]=data;
          cache[index][offset]=data;
          dirty[index]=1;
        }

        return cache[index][offset];
      }
    }

  }
}
class solvePipelinedWithCaches {
  static var datacache;
  static var inscache;
  static int row = 8,
      col = 8,
      size = 64,
      stop=0,
      instructCount=0,
      dataCount=0,
      controlCount=0,
      stallCount=0,
      dataHazard=0,
      controlHazard=0,
      misPredict=0,
      dataStalls=0,
      controlStalls=0;
  static Set<int> INScold={};
  static Set<int> MEMcold={};
  static Set<int> INSconflict={};
  static Set<int> MEMconflict={};
  static int pc = 0,count=0,btarget=0;
  static bool
  knob1=true,
      knob2=true,
      running=true,
      isBranchtaken=false,
      loadHazard=false;
  static List n=[];
  static final RF = List<int>.filled(32, 0);
  static final b = List<int>.filled(32, 0);
  static final im = List<int>.filled(32, 0);
  static final t = List<int>.filled(32, 0);
  static final if_de=List<int>.filled(2, 0);
  static final t1=List<int>.filled(2, 0);
  static final de_ex =List<int>.filled(13, 0);//pc,instruction,op2,op1,immediate,branchtarget,op2select,aluop,branchselect,resultselect,memop,rfwrite,isbranch
  static final t2 =List<int>.filled(13, 0);
  static final ex_ma = List<int>.filled(9, 0);//pc,instruction,aluresult,op2,memop,resultselect,rfwrite,isbranch,immediate
  static final t3 = List<int>.filled(9, 0);
  static final ma_wb = List<int>.filled(5, 0);//pc,instruction,result,rfwrite,isbranch
  static final t4 = List<int>.filled(5, 0);
  static Map<int, int> MEM = Map<int, int>();
  static Map<int,int> INS=Map<int,int>();
  static List <BTB> buffer=[];
  //|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
  static void dec2bin(int value) {
    if (value < 0) value = (1 << 32) + value;

    for (int i = 0; i < 32; i++) {
      t[i] = 0;
    }

    int i = 0;
    while (value > 0 && i <= 31) {
      t[i] = value % 2;
      double next = value / 2;
      value = next.toInt();
      i++;
    }
  }
  static int comp2() {

    int c = t[31];
    if (c == 1) {
      for (int i = 0; i <= 31; i++) {
        if (t[i] == 1)
          t[i] = 0;
        else
          t[i] = 1;
      }
      int i = 0;
      while (i <= 31 && t[i] == 1) {
        t[i] = 0;
        i++;
      }
      if (i <= 31) {
        t[i] = 1;
      }
    }
    int sum = 0;
    for (int i = 31; i >= 0; i--) {
      sum = (2 * sum) + t[i];
    }
    if (c == 1) {
      sum = (-1) * sum;
    }
    return sum;
  }

  static int lw(int Eaddress) {

    return datacache.getnumber(Eaddress,false,0);
  }
  static int lb(int Eaddress, int index) {
    int element = datacache.getnumber(Eaddress,false,0);
    int data = ((element >> (8 * index)) & 0xFF);
    for (int i = 0; i <= 7; i++) {
      t[i] = (data >> i) & 1;
    }
    for (int i = 8; i <= 31; i++) {
      t[i] = t[7];
    }
    return comp2();
  }
  static int lh(int Eaddress, int index) {
    int element = datacache.getnumber(Eaddress,false,0);
    int data = ((element >> (8 * index)) & 0xFFFF);
    for (int i = 0; i <= 15; i++) {
      t[i] = (data >> i) & 1;
    }
    for (int i = 16; i <= 31; i++) {
      t[i] = t[15];
    }
    return comp2();
  }
  static void sb(int Eaddress, int index) {
    int datain=ex_ma[3];
    if(src2Hazard(ma_wb[1], ex_ma[1]) && knob2==true){
      datain=ma_wb[2];}

    int element = MEM[Eaddress]??0;
    for (int i = 0; i <= 31; i++) {
      t[i] = (element >> i) & 1;
    }
    index = 8 * index;
    for (int i = 0; i <= 7; i++) {
      t[index] = (datain >> i) & 1;
      index = index + 1;
    }
    int temp=datacache.getnumber(Eaddress,true,comp2());
  }
  static void sh(int Eaddress, int index) {
    int datain=ex_ma[3];
    if(src2Hazard(ma_wb[1], ex_ma[1]) && knob2==true){
      datain=ma_wb[2];}

    int element = MEM[Eaddress]??0;
    for (int i = 0; i <= 31; i++) {
      t[i] = (element >> i) & 1;
    }
    index = 8 * index;
    for (int i = 0; i <= 15; i++) {
      t[index] = (datain >> i) & 1;
      index = index + 1;
    }
    int temp=datacache.getnumber(Eaddress,true,comp2());
  }
  static void sw(int Eaddress) {
    int datain=ex_ma[3];
    if(src2Hazard(ma_wb[1], ex_ma[1]) && knob2==true){
      datain=ma_wb[2]; }
    int temp=datacache.getnumber(Eaddress,true,datain);
  }



  static Map<int,String> IFDE={};
  static Map<int,String> DEEX={};
  static Map<int,String> EXMA={};
  static Map<int,String> MAWB={};
  static String displayTxt='CYCLES ELAPSED: 0\n\n';
  static List<String> outputReg = ['0${'\t0'*31}'];

  static void fetch() {
    t1[0]=pc;t1[1]=inscache.getnumber(pc,false,0);
    displayTxt +='FETCH: Read instruction from address 0x${pc.toRadixString(16)}.\n';
  }
  static void decode_p(){
    if(if_de[1]==0) {
      displayTxt += "DECODE: EMPTY\n";
      return;
    }
    //0,1,2,3,4,6,7,9,10,11
    t2[0]=if_de[0];t2[1]=if_de[1];
    t2[2]=RF[(t2[1]>>20)&0x1F];
    t2[3]=RF[(t2[1]>>15)&0x1F];
    //display
    displayTxt += "DECODE: ";
    if(if_de[1]&0x7F==99 ||if_de[1]&0x7F == 111 || if_de[1]&0x7F==103)displayTxt += "\nControl Hazard detected at instruction ${(if_de[0]/4).toInt()}\n";
    if(knob2==true){
      //forwarding:
      if(src1Hazard(ma_wb[1],if_de[1])){t2[3]=ma_wb[2];displayTxt+="\nHazard detected between instructions number ${(if_de[0]/4).toInt()}(Decode) and ${(ma_wb[0]/4).toInt()}(Writeback) and WB-DE forwarding used.\n";}
      if(src2Hazard(ma_wb[1],if_de[1])){t2[2]=ma_wb[2];displayTxt+="\nHazard detected between instructions number ${(if_de[0]/4).toInt()}(Decode) and ${(ma_wb[0]/4).toInt()}(Writeback) and WB-DE forwarding used.\n";}
      //load-use hazard
      if(src2Hazard(de_ex[1],if_de[1]) && de_ex[1]&0x7F==3){loadHazard=true;displayTxt+="\nLoad Hazard detected between instructions number ${(if_de[0]/4).toInt()}(Decode) and ${(de_ex[0]/4).toInt()}(Execute) and no forwarding used.\n";}
      if(src1Hazard(de_ex[1],if_de[1]) && de_ex[1]&0x7F==3){loadHazard=true;displayTxt+="\nLoad Hazard detected between instructions number ${(if_de[0]/4).toInt()}(Decode) and ${(de_ex[0]/4).toInt()}(Execute) and no forwarding used.\n";}
    }

    //immediate
    for (int i = 0; i <= 31; i++) {
      im[i] = 0;b[i]=0;t[i]=0;
    }
    dec2bin(if_de[1]);
    for(int i=0;i<32;i++){b[i]=t[i];}
    ///i type
    if (if_de[1]&0x7F == 19 || if_de[1]&0x7F == 3 || if_de[1]&0x7F == 103) {
      for (int i = 20; i <= 31; i++) {
        im[i - 20] = b[i];
      }
      for (int i = 12; i <= 31; i++) {
        im[i] = im[11];
      }
    }

    ///j type
    else if (if_de[1]&0x7F == 111) {
      for (int i = 12; i <= 19; i++) {
        im[i] = b[i];
      }
      im[11] = b[20];
      im[20] = b[31];
      for (int i = 21; i <= 30; i++) {
        im[i - 20] = b[i];
      }
      for (int i = 21; i <= 31; i++) {
        im[i] = im[20];
      }
    }

    //u type
    else if (if_de[1]&0x7F == 55 || if_de[1]&0x7F == 23) {
      for (int i = 12; i <= 31; i++) {
        im[i] = b[i];
      }
    }

    ///b type
    else if (if_de[1]&0x7F == 99) {
      im[11] = b[7];
      im[12] = b[31];
      for (int i = 8; i <= 11; i++) {
        im[i - 7] = b[i];
      }
      for (int i = 25; i <= 30; i++) {
        im[i - 20] = b[i];
      }
      for (int i = 13; i <= 31; i++) {
        im[i] = im[12];
      }
    }

    //s type
    else if(if_de[1]&0x7F==35)
    {
      for (int i = 7; i <= 11; i++) {
        im[i - 7] = b[i];
      }
      for (int i = 25; i <= 31; i++) {
        im[i - 20] = b[i];
      }
      for (int i = 12; i <= 31; i++) {
        im[i] = im[11];
      }
    }

    //immediate sign extension
    for (int i = 0; i < 32; i++) {
      t[i] = im[i];
    }
    t2[4] = comp2();

    //Rfwrite
    if(t2[1]&0x7F==51 || t2[1]&0x7F==19 || t2[1]&0x7F==3 || t2[1]&0x7F==111 || t2[1]&0x7F==103 || t2[1]&0x7F==55 || t2[1]&0x7F==23){t2[11]=1;}

    //resultselect
    if (t2[1]&0x7F == 3) t2[9] = 1; //load mode
    else if (t2[1]&0x7F == 111 || t2[1]&0x7F == 103) t2[9] = 2; //jal|jalr pc+4
    else if(t2[1]&0x7F==23)t2[9]=3;//auipc
    else if(t2[1]&0x7F==55)t2[9]=4;//lui

    //op2select
    if(t2[1]&0x7F==19 || t2[1]&0x7F==3 || t2[1]&0x7F==35 || t2[1]&0x7F==103)t2[6]=1;

    //MEmop
    if(t2[1]&0x7F==35)t2[10]=1;//for store


    //ALUOP
    if (t2[1]&0x7F == 99 || (t2[1]&0x7F == 51 && t2[1]>>12&0x7 == 0 && t2[1]>>25&0x7F == 32)) {
      t2[7] = 1;
    } //sub
    else if (t2[1]>>12&0x7 == 7 && (t2[1]&0x7F == 51 || t2[1]&0x7F == 19))
      t2[7] = 2; //and
    else if (t2[1]>>12&0x7 == 6 && (t2[1]&0x7F == 51 || t2[1]&0x7F == 19))
      t2[7] = 3; //or
    else if (t2[1]&0x7F == 51 && t2[1]>>12&0x7 == 4)
      t2[7] = 4; //xor
    if (t2[1]&0x7F == 51) {
      if (t2[1]>>12&0x7 == 1) t2[7] = 5; //sll
      else if (t2[1]>>12&0x7 == 5 && t2[1]>>25&0x7F == 32)
        t2[7] = 7; //sra
      else if(t2[1]>>12&0x7==5 && t2[1]>>25&0x7F==0)
        t2[7] = 6; //srl
      else if(t2[1]>>12&0x7==2)t2[7]=8;
    }

    if(!(if_de[0]==0 && if_de[1]==19 )){displayTxt += "Instruction number ${(if_de[0]/4).toInt()}, ";}
    displayTxt += "Operation is ";
    if(if_de[0]==0 && if_de[1]==19){
      displayTxt+="NOP/bubble instruction\n";
    }
    else if (if_de[1]&0x7F == 51) {
      if ((if_de[1]>>12)&0x7 == 0) {
        if ((if_de[1]>>25)&0x7F == 0) {
          displayTxt += "ADD, ";
        } else
          displayTxt += "SUB, ";
      } else if ((if_de[1]>>12)&0x7 == 7)
        displayTxt += "AND, ";
      else if ((if_de[1]>>12)&0x7 == 6)
        displayTxt += "OR, ";
      else if ((if_de[1]>>12)&0x7 == 4)
        displayTxt += "XOR, ";
      else if ((if_de[1]>>12)&0x7 == 1)
        displayTxt += "SLL, ";
      else if ((if_de[1]>>12)&0x7 == 2)
        displayTxt += "SLT, ";
      else if ((if_de[1]>>12)&0x7 == 5) {
        if ((if_de[1]>>25)&0x7F == 0) {
          displayTxt += "SRL, ";
        } else
          displayTxt += "SRA, ";
      }
      displayTxt +=
      "rs1 is x${(if_de[1]>>15)&0x1F}, rs2 is x${(if_de[1]>>20)&0x1F} and destination register is x${(if_de[1]>>7)&0x1F}.\n";
    } else if (if_de[1]&0x7F == 19) {
      if ((if_de[1]>>12)&0x7 == 0) {
        displayTxt += "ADDI, ";
      } else if ((if_de[1]>>12)&0x7 == 6) {
        displayTxt += "ORI, ";
      } else if ((if_de[1]>>12)&0x7 == 7) {
        displayTxt += "ANDI, ";
      }
      displayTxt +=
      "rs1 is x${(if_de[1]>>15)&0x1F}, immediate is ${t2[4]} and destination register is x${(if_de[1]>>7)&0x1F}.\n";
    } else if (if_de[1]&0x7F == 3) {
      if ((if_de[1]>>12)&0x7 == 0) {
        displayTxt += "LB, ";
      } else if ((if_de[1]>>12)&0x7 == 1) {
        displayTxt += "LH, ";
      } else if ((if_de[1]>>12)&0x7 == 2) {
        displayTxt += "LW, ";
      }
      displayTxt +=
      "rs1 is x${(if_de[1]>>15)&0x1F}, immediate is ${t2[4]} and destination register is x${(if_de[1]>>7)&0x1F}.\n";
    } else if (if_de[1]&0x7F == 103) {
      displayTxt +=
      "JALR, rs1 is x${(if_de[1]>>15)&0x1F}, immediate is ${t2[4]} and destination register is x${(if_de[1]>>7)&0x1F}.\n";
    } else if (if_de[1]&0x7F == 35) {
      if ((if_de[1]>>12)&0x7 == 0) {
        displayTxt += "SB, ";
      } else if ((if_de[1]>>12)&0x7 == 1) {
        displayTxt += "SH, ";
      } else if ((if_de[1]>>12)&0x7 == 2) {
        displayTxt += "SW, ";
      }
      displayTxt +=
      "rs1 is x${(if_de[1]>>15)&0x1F}, immediate is ${t2[4]} and rs2 is x${(if_de[1]>>20)&0x1F}.\n";
    } else if (if_de[1]&0x7F == 99) {
      if ((if_de[1]>>12)&0x7 == 0) {
        displayTxt += "BEQ, ";
      } else if ((if_de[1]>>12)&0x7 == 1) {
        displayTxt += "BNE, ";
      } else if ((if_de[1]>>12)&0x7 == 4) {
        displayTxt += "BLT, ";
      } else if ((if_de[1]>>12)&0x7 == 5) {
        displayTxt += "BGE, ";
      }
      displayTxt +=
      "rs1 is x${(if_de[1]>>15)&0x1F}, immediate is ${t2[4]} and rs2 is x${(if_de[1]>>20)&0x1F}.\n";
    } else if (if_de[1]&0x7F == 111) {
      displayTxt += "JAL, immediate is ${t2[4]} and rd is x${(if_de[1]>>7)&0x1F}.\n";
    } else if (if_de[1]&0x7F == 55) {
      displayTxt += "LUI, immediate is ${t2[4]} and rd is x${(if_de[1]>>7)&0x1F}.\n";
    } else if (if_de[1]&0x7F == 23) {
      displayTxt += "AUIPC, immediate is ${t2[4]} and rd is x${(if_de[1]>>7)&0x1F}.\n";
    }
  }
  static void execute() {
    if(de_ex[1]==0) {
      displayTxt += "EXECUTE: EMPTY\n";
      return;
    }
    //0,1,3,4,5,6,7,8
    //////////////////////pipelined////////////////////////////////////////
    t3[0]=de_ex[0];
    t3[1]=de_ex[1];
    t3[3]=de_ex[2];
    t3[4]=de_ex[10];
    t3[5]=de_ex[9];
    t3[6]=de_ex[11];
    t3[7]=de_ex[12];
    t3[8]=de_ex[4];

    displayTxt += "EXECUTE: ";
    if(!(if_de[0]==0 && if_de[1]==19)){displayTxt += "Instruction number ${(de_ex[0]/4).toInt()}, ";}
    if(de_ex[0]==0 && de_ex[1]==19)displayTxt+="NOP/BUBBLE instruction  ";
    int temp = de_ex[2];
    int op1=de_ex[3];
    if(knob2==true){
      //forwarding:
      if(src1Hazard(ex_ma[1],de_ex[1]) && ex_ma[1]&0x7F!=3){
        displayTxt+="\nHazard detected between instructions number ${(de_ex[0]/4).toInt()}(Execute) and ${(ex_ma[0]/4).toInt()}(Memory) and MA-EX forwarding used.\n";
        if(ex_ma[5]==0){
          op1=ex_ma[2];
        }
        else if(ex_ma[5]==2){
          op1=ex_ma[0]+4;
        }
        else if(ex_ma[5]==3){
          op1=ex_ma[0]+ex_ma[8];
        }
        else if(ex_ma[5]==4){
          op1=ex_ma[8];
        }}
      else if(src1Hazard(ma_wb[1],de_ex[1])){op1=ma_wb[2];displayTxt+="\nHazard detected between instructions number ${(de_ex[0]/4).toInt()}(Execute) and ${(ma_wb[0]/4).toInt()}(Writeback) and WB-EX forwarding used.\n";}


      if(src2Hazard(ex_ma[1],de_ex[1]) && ex_ma[1]&0x7F!=3){
        displayTxt+="\nHazard detected between instructions number ${(de_ex[0]/4).toInt()}(Execute) and ${(ex_ma[0]/4).toInt()}(Memory) and MA-EX forwarding used.\n";
        if(ex_ma[5]==0){
          temp=ex_ma[2];t3[3]=ex_ma[2];
        }
        else if(ex_ma[5]==2){
          temp=ex_ma[0]+4;t3[3]=ex_ma[0]+4;
        }
        else if(ex_ma[5]==3){
          temp=ex_ma[0]+ex_ma[8];t3[3]=ex_ma[0]+ex_ma[8];
        }
        else if(ex_ma[5]==4){
          temp=ex_ma[8];t3[3]=ex_ma[8];
        }}
      else if(src2Hazard(ma_wb[1],de_ex[1])){temp=ma_wb[2];t3[3]=ma_wb[2];displayTxt+="\nHazard detected between instructions number ${(de_ex[0]/4).toInt()}(Execute) and ${(ma_wb[0]/4).toInt()}(Writeback) and WB-EX forwarding used.\n";}
      //forwarding stopped
    }

    if (de_ex[6]==1) temp = de_ex[4];
    switch (de_ex[7]) {
      case 0:
        {
          displayTxt += "ADD ${op1} and ${temp}.\n";
          t3[2] = temp + op1;
          if(t3[2]>2147483647){t3[2]=-2147483648+(t3[2]-2147483648);}
          else if(t3[2]< -2147483648){t3[2]=2147483647+(2147483649+t3[2]);}
        }
        break;

      case 1:
        {
          displayTxt += "SUBTRACT ${temp} from ${op1}.\n";
          t3[2] = op1 - temp;
          if(t3[2]>2147483647){t3[2]=-2147483648+(t3[2]-2147483648);}
          else if(t3[2]< -2147483648){t3[2]=2147483647+(2147483649+t3[2]);}
        }
        break;

      case 2:
        {
          displayTxt += "LOGICAL 'AND' of ${op1} and ${temp}.\n";
          t3[2] = op1 & temp;
        }
        break;

      case 3:
        {
          displayTxt += "LOGICAL 'OR' of ${op1} and ${temp}.\n";
          t3[2] = op1 | temp;
        }
        break;

      case 4:
        {
          displayTxt += "LOGICAL 'XOR' of ${op1} and ${temp}.\n";
          t3[2] = op1 ^ temp;
        }
        break;

      case 5:
        {
          displayTxt += "SHIFT left ${op1} ${temp} times.\n";
          t3[2]=op1;
          for(int i=0;i<temp;i++){
            t3[2]=t3[2]<<1;
            if(t3[2]>2147483647){t3[2]=-2147483648+(t3[2]-2147483648);}
            else if(t3[2]<-2147483648){t3[2]=2147483647+(2147483649+t3[2]);}
          }
        }break;
    //list use for srl
      case 6:
        {
          displayTxt += "LOGICAL SHIFT right ${op1} ${temp} times.\n";
          dec2bin(op1);
          int i = 0;
          for (; i <= 31 - temp && i<=31; i++) {
            t[i] = t[i + temp];
          }
          while (i <= 31) {
            t[i] = 0;
            i++;
          }
          t3[2] = comp2();
        }
        break;

      case 7:
        {
          displayTxt += "ARITHMETIC SHIFT right ${op1} ${temp} times.\n";
          t3[2] = op1 >> temp;
        }
        break;

      case 8:
        {
          displayTxt += "SET less than ${op1} ${temp} times.\n";
          if(op1<temp)t3[2]=1;
          else t3[2]=0;
        }break;
    }
    //branch
    btarget=pc+4;
    if(de_ex[1]&0x7F==99 || de_ex[1]&0x7F==111)btarget = de_ex[0] + de_ex[4];
    else if(de_ex[1]&0x7F==103)btarget=temp+op1;
    if (de_ex[1]&0x7F == 111 || de_ex[1]&0x7F==103) {t3[7] = 1;}
    if(de_ex[1]&0x7F==99){
      if ((de_ex[1]>>12)&0x7 == 0 && (op1==temp)) t3[7] = 1;
      else if ((de_ex[1]>>12)&0x7 == 1 && (op1!=temp)) t3[7] = 1;
      else if ((de_ex[1]>>12)&0x7 == 4 && (op1<temp)) t3[7] = 1;
      else if ((de_ex[1]>>12)&0x7 == 5 && (op1>=temp)) t3[7] = 1;
    }
    ////branch target buffer working///
    int index=0;
    if(de_ex[1]&0x7F==99 || de_ex[1]&0x7F==111 || de_ex[1]&0x7F==103){
      bool flag=false;
      for(int i=0;i<buffer.length;i++){
        if(buffer[i].address==de_ex[0]){flag=true;index=i;break;}
      }
      //adding to buffer
      displayTxt+="\nBranch predictor used for instruction ${(de_ex[0]).toInt()} ";
      if(flag==false){
        var block=new BTB(de_ex[0],btarget,false);
        if(de_ex[1]&0x7F==111 || de_ex[1]&0x7F==103)block.branchtaken=true;
        buffer.add(block);
        index=buffer.length-1;
        if(block.branchtaken==true)displayTxt+="and branch taken.\n";
        else displayTxt+="and no branch taken.\n";
      }
    }
    ////////branch target remaining////////////
    if(t3[7]==1 && (de_ex[1]&0x7F==99 || de_ex[1]&0x7F == 111 || de_ex[1]&0x7F==103)){isBranchtaken=true;}
    if(isBranchtaken==false){btarget=de_ex[0]+4;}
    if(btarget!=if_de[0] && de_ex[1]!=0){
      if(buffer[index].branchtaken==false){buffer[index].branchtaken=true;}
      else buffer[index].branchtaken=false;
    }
    isBranchtaken=false;

  }
  static void memory() {
    if(ex_ma[1]==0) {
      displayTxt += "MEMORY: EMPTY\n";
      return;
    }
    //pipelined//
    if(knob1==true){
      t4[0]=ex_ma[0];t4[1]=ex_ma[1];t4[3]=ex_ma[6];t4[4]=ex_ma[7];
      int Eaddress = ex_ma[2] - (ex_ma[2] % 4);
      int index = ex_ma[2] % 4;
      for (int i = 0; i < 32; i++) {
        t[i] = 0;
      }
      displayTxt += "MEMORY: ";
      if(!(if_de[0]==0 && if_de[1]==19)){displayTxt += "Instruction number ${(ex_ma[0]/4).toInt()}, ";}
      if (ex_ma[4] == 0 && ex_ma[1]&0x7F==3) {
        if (ex_ma[1]&0x7F == 3)displayTxt += "Load from address 0x${ex_ma[2].toRadixString(16)}.\n";
        else{
          displayTxt += "No memory operation.\n";
        }
        if ((ex_ma[1]>>12)&0x3 == 0) {
          t4[2]=lb(Eaddress, index);
        } else if ((ex_ma[1]>>12)&0x3 == 1) {
          t4[2]=lh(Eaddress, index);
        } else if((ex_ma[1]>>12)&0x3 == 2) {
          t4[2]=lw(Eaddress);
        }
      } else if(ex_ma[4]==1) {
        displayTxt += "Store at address 0x${ex_ma[2].toRadixString(16)}.\n";
        if ((ex_ma[1]>>12)&0x3 == 0) {
          sb(Eaddress, index);
        } else if ((ex_ma[1]>>12)&0x3 == 1) {
          sh(Eaddress, index);
        } else if((ex_ma[1]>>12)&0x3 == 2) {
          sw(Eaddress);
        }
      }
      if(ex_ma[1]==19 && ex_ma[0]==0){displayTxt+="NOP/BUBBLE instruction.\n";}
      if(ex_ma[5]==0){
        t4[2]=ex_ma[2];
      }
      else if(ex_ma[5]==2){
        t4[2]=ex_ma[0]+4;
      }
      else if(ex_ma[5]==3){
        t4[2]=ex_ma[0]+ex_ma[8];
      }
      else if(ex_ma[5]==4){
        t4[2]=ex_ma[8];
      }
    }
    if(src2Hazard(ma_wb[1], ex_ma[1]) && knob2==true)displayTxt+="\nHazard detected between instructions number ${(ex_ma[0]/4).toInt()}(Memory) and ${(ma_wb[0]/4).toInt()}(Writeback) and WB-MA forwarding used.\n";
  }
  static void write_back(File f) {
    if(ma_wb[1]==0) {
      displayTxt += "WRITEBACK: EMPTY\n";
      return;
    }
    displayTxt += "WRITEBACK: ";
    if(!(if_de[0]==0 && if_de[1]==19)){displayTxt += "Instruction number ${(ma_wb[0]/4).toInt()}, ";}
    if( ma_wb[3]==1  &&   ((ma_wb[1]>>7)&0x1F)!=0 ){
      displayTxt += "Write to x${(ma_wb[1]>>7)&0x1F}.\n ";
      RF[(ma_wb[1]>>7)&0x1F]=ma_wb[2];
    }else{
      displayTxt += "No writeback.\n";
    }
    if(ma_wb[0]==0 && ma_wb[1]==19){displayTxt+="NOP/BUBBLE instruction.\n";}
    if(ma_wb[1]==1 ){swi_exit(f);}
    //stats
    if(!((ma_wb[1]==19 && ma_wb[3]==0) || ma_wb[1]==0)){instructCount++;}
    if(ma_wb[1]&0x7F==35 || ma_wb[1]&0x7F==3){dataCount++;}
    if(ma_wb[1]&0x7F==99 || ma_wb[1]&0x7F == 111 || ma_wb[1]&0x7F==103){controlCount++;}
    if(ma_wb[1]&0x7F==99){controlHazard++;}
  }
  static void transfer() {
    ////data forwarding////
    if(knob2==true){
      if(loadHazard==false){

        if(btarget!=if_de[0] && de_ex[1]!=0 && de_ex[1]!=19 ){
          pc=btarget;if_de[0]=0;if_de[1]=19;de_ex[0]=0;de_ex[1]=19;for(int i=2;i<13;i++){de_ex[i]=0;}
          stallCount+=2;
          controlStalls+=2;
          misPredict++;
        }
        else {
          //display
          bool check=false;
          int progControl=pc;
          pc=pc+4;
          for(int i=0;i<buffer.length;i++){
            if(buffer[i].address ==  (pc-4) && buffer[i].branchtaken==true){pc=buffer[i].branchtarget;check=true;}
          }
          //if to de//
          if_de[0]=t1[0];if_de[1]=t1[1];
          //de to ex//
          for(int i=0;i<13;i++){de_ex[i]=t2[i];}
          if(check==true)displayTxt+="\nBranch predictor used for instruction ${(progControl/4).toInt()} and branch taken.\n";
          else displayTxt+="\nBranch predictor used for instruction ${(progControl/4).toInt()} and branch not taken.\n";
        }
      }
      else{

        de_ex[0]=0;de_ex[1]=19;for(int i=2;i<13;i++){de_ex[i]=0;}loadHazard=false;
        stallCount++;dataStalls++;dataHazard++;}
    }
    ///no data forwarding///
    else{
      if(btarget!=if_de[0] && de_ex[1]!=0 && de_ex[1]!=19 ){
        pc=btarget;if_de[0]=0;if_de[1]=19;de_ex[0]=0;de_ex[1]=19;for(int i=2;i<13;i++){de_ex[i]=0;}
        stallCount=stallCount+2;
        controlStalls=controlStalls+2;
        misPredict++;
      }
      else {


        if(hazardDetect(de_ex[1])==false && hazardDetect(ex_ma[1])==false && hazardDetect(ma_wb[1])==false){
          pc=pc+4;
          for(int i=0;i<buffer.length;i++){
            if(buffer[i].address ==  (pc-4) && buffer[i].branchtaken==true){pc=buffer[i].branchtarget;}
          }
          //if to de//
          if_de[0]=t1[0];if_de[1]=t1[1];
          //de to ex//
          for(int i=0;i<13;i++){de_ex[i]=t2[i];}
        }
        else{
          //hazard print
          if(hazardDetect(de_ex[1])==true)displayTxt+="\nHazard detected between instructions number ${(if_de[0]/4).toInt()}(Decode) and ${(de_ex[0]/4).toInt()}(Execute).\n";
          else if(hazardDetect(ex_ma[1])==true)displayTxt+="\nHazard detected between instructions number ${(if_de[0]/4).toInt()}(Decode) and ${(ex_ma[0]/4).toInt()}(Memory).\n";
          else if(hazardDetect(ma_wb[1])==true)displayTxt+="\nHazard detected between instructions number ${(if_de[0]/4).toInt()}(Decode) and ${(ma_wb[0]/4).toInt()}(Writeback).\n";
          de_ex[0]=0;de_ex[1]=19;for(int i=2;i<13;i++){de_ex[i]=0;}
          stallCount++;
          dataHazard++;
          dataStalls++;
        }
      }
    }

    //ma to wb//
    for(int i=0;i<9;i++){ex_ma[i]=t3[i];t3[i]=0;}
    for(int i=0;i<5;i++){ma_wb[i]=t4[i];t4[i]=0;}
    //temp//
    for(int i=0;i<13;i++){t2[i]=0;}
    t1[0]=0;t1[1]=0;
  }

  static void swi_exit(File f) {
    print(datacache.misses);
    write_datamemory(f);
    running = false;
  }
  static void write_datamemory(File myOutFile) {
    var sortedINS = Map.fromEntries(
        INS.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)));
    var sortedMEM = Map.fromEntries(
        MEM.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)));
    myOutFile.writeAsStringSync("TEXT segment: \n",
        mode: FileMode.append);
    myOutFile.writeAsStringSync("ADDRESS\t\t\t\tINSTRUCTION\t\t\tDECIMAL\n\n",
        mode: FileMode.append);
    for (var i in sortedINS.keys) {
      String adress = i.toRadixString(16);
      int val = sortedINS[i] ?? 0;
      int dec=val;
      if (val < 0) {
        val = (1 << 32) + val;
      }
      adress = "0x" +
          '0' * (8 - adress.length) +
          adress +
          "\t\t\t0x" +
          '0' * (8 - val.toRadixString(16).length) +
          val.toRadixString(16) +
          "\t\t\t${dec}\n";
      myOutFile.writeAsStringSync(adress, mode: FileMode.append);
    }
    myOutFile.writeAsStringSync("\n\nDATA segment: \n",
        mode: FileMode.append);
    myOutFile.writeAsStringSync("ADDRESS\t\t\t\tDATA\t\t\tDECIMAL\n\n",
        mode: FileMode.append);
    for (var i in sortedMEM.keys) {
      String adress = i.toRadixString(16);
      int val = sortedMEM[i] ?? 0;
      int dec=val;
      if (val < 0) {
        val = (1 << 32) + val;
      }
      adress = "0x" +
          '0' * (8 - adress.length) +
          adress +
          "\t\t\t0x" +
          '0' * (8 - val.toRadixString(16).length) +
          val.toRadixString(16) +
          "\t\t\t${dec}\n";
      myOutFile.writeAsStringSync(adress, mode: FileMode.append);
    }
    ///////printing stats to output file/////
    myOutFile.writeAsStringSync("\nTotal cycles:  ${count}\nTotal instruction executed:  ${instructCount}\nCPI:  ${count/instructCount}", mode: FileMode.append);
    myOutFile.writeAsStringSync("\nData instructions:  ${dataCount}\nControl instructions:  ${controlCount}\nStalls count:  ${stallCount}", mode: FileMode.append);
    myOutFile.writeAsStringSync("\nData hazards count:  ${dataHazard}\nControl hazards count:  ${controlHazard}\nBranch mispredictions count:  ${misPredict}", mode: FileMode.append);
    myOutFile.writeAsStringSync("\nNumber of stalls due to data hazards:  ${dataStalls}\nNumber of stalls due to control hazards:  ${controlStalls}.", mode: FileMode.append);
  }
  static bool src1Hazard(int write,int read) {
    int opcode1=write&0x7F,opcode2=read&0x7F;
    if(opcode1==35 || opcode1==99 || opcode1==0 || write==19){return false;}
    if(opcode2==111 || opcode2==55 || opcode2==23 || read==19){return false;}
    int src1=(read>>15)&0x1F,dest=(write>>7)&0x1F;
    if((src1!=0) && (src1 == dest)){return true;}
    return false;
  }
  static bool src2Hazard(int write,int read) {
    bool hasrs2=false;
    int opcode1=write&0x7F,opcode2=read&0x7F;
    if(opcode1==35 || opcode1==99 || opcode1==0 || write==19){return false;}
    if(opcode2==111 || opcode2==55 || opcode2==23 || read==19){return false;}
    int src2=(read>>20)&0x1F,dest=(write>>7)&0x1F;
    if(opcode2==51 || opcode2==35 || opcode2==99){hasrs2=true;}
    if(hasrs2==true &&(src2!=0) && (src2 == dest)){return true;}
    return false;
  }
  static bool hazardDetect(int instruction) {
    int opcode=instruction&0x7F;
    bool hasrs1=true,hasrs2=false;
    if(opcode==35 || opcode==99 || opcode==0 || instruction==19){return false;}
    if(if_de[1]&0x7F==111 || if_de[1]&0x7F==55 || if_de[1]&0x7F==23 || if_de[1]==19){return false;}
    int src1=(if_de[1]>>15)&0x1F,src2=(if_de[1]>>20)&0x1F,dest=(instruction>>7)&0x1F;
    if(if_de[1]&0x7F==51 || if_de[1]&0x7F==35 || if_de[1]&0x7F==99){hasrs2=true;}
    if(hasrs1==true && (src1!=0) && (src1 == dest)){return true;}
    else if(hasrs2==true &&(src2!=0) && (src2 == dest)){return true;}
    return false;
  }

  static void load_progmem() {
    for(int i=0;i<n.length;i++)
    {
      String s=n[i];
      int address=0,instruct=0;
      int j=0;
      while(j<s.length && s.codeUnitAt(j)!=120){j++;}
      j++;
      while(j<s.length){
        int asc=s.codeUnitAt(j);
        if(asc==32)break;
        else{
          if(asc>=65)asc=asc-55;
          else asc=asc-48;
        }
        address=16*(address)+asc;
        j++;
      }
      while(j<s.length && s.codeUnitAt(j)!=120){j++;}
      j++;
      while(j<s.length){
        int asc=s.codeUnitAt(j);
        if(asc==32)break;
        else{
          if(asc>=65)asc=asc-55;
          else asc=asc-48;
        }
        instruct=16*(instruct)+asc;
        j++;
      }
      dec2bin(instruct);
      instruct=comp2();
      dec2bin(address);
      address=comp2();
      if(address>=0x10000000)
        MEM[address]=instruct;
      else
        INS[address]=instruct;
    }
  }
  static void run_riscvsim(File f)async{
    f.writeAsStringSync("",
        mode: FileMode.write);
    while(running){


      fetch();
      decode_p();
      execute();
      memory();
      write_back(f);

      // print("**************************");
      // print(pc);
      // print(if_de);
      // print(de_ex);
      // print(ex_ma);
      // print(ma_wb);
      // print(RF);
      count++;
      transfer();
      displayTxt+='CYCLES ELAPSED: ${count}\n\n';
      outputReg.add(RF.join('\t'));
      IFDE[count]=if_de.join('\t');
      DEEX[count]=de_ex.join('\t');
      EXMA[count]=ex_ma.join('\t');
      MAWB[count]=ma_wb.join('\t');

      // print(count.toString()+if_de.toString());
    }
  }

  static String showTxt(int step){
    List<String> myList=displayTxt.split('\n\n');
    String str='';
    for(int i=0;i<step;i++){
      str+=myList[i]+'\n\n';
    }
    return str;
  }
  void solve(File inputFile,File outputFile)async {

    IFDE={};
    DEEX={};
    EXMA={};
    MAWB={};
    displayTxt='CYCLES ELAPSED: 0\n\n';
    outputReg = ['0${'\t0'*31}'];
    pc = 0;
    count=0;
    btarget=0;
    instructCount=0;
    dataCount=0;
    controlCount=0;
    stallCount=0;
    dataHazard=0;
    controlHazard=0;
    misPredict=0;
    dataStalls=0;
    controlStalls=0;

    knob1=true;
    running=true;
    isBranchtaken=false;
    loadHazard=false;
    n=[];
    for (int i=0;i<RF.length;i++){
      RF[i]=0;
    }
    for (int i=0;i<b.length;i++){
      b[i]=0;
    }
    for (int i=0;i<im.length;i++){
      im[i]=0;
    }
    for (int i=0;i<t.length;i++){
      t[i]=0;
    }
    for (int i=0;i<if_de.length;i++){
      if_de[i]=0;
    }
    for (int i=0;i<t1.length;i++){
      t1[i]=0;
    }
    for (int i=0;i<ex_ma.length;i++){
      ex_ma[i]=0;
    }
    for (int i=0;i<t2.length;i++){
      t2[i]=0;
    }
    for (int i=0;i<de_ex.length;i++){
      de_ex[i]=0;
    }
    for (int i=0;i<t3.length;i++){
      t3[i]=0;
    }
    for (int i=0;i<ma_wb.length;i++){
      ma_wb[i]=0;
    }
    for (int i=0;i<t4.length;i++){
      t4[i]=0;
    }
    MEM = {};
    INS={};
    buffer=[];

  }
}

class ExecutionDiagram extends StatefulWidget {
  bool? isPipelined;
  Function(int v)? updateDisplay;
  ExecutionDiagram({Key? key,required this.isPipelined, required this.updateDisplay});

  @override
  State<ExecutionDiagram> createState() => _ExecutionDiagramState();
}
class _ExecutionDiagramState extends State<ExecutionDiagram> {
  final ScrollController _mycontroller = new ScrollController();
  chooseColor(int type){
    if(type==5) return Colors.black38;
    if(type==3) return Colors.blueGrey;
    if(type==0) return Colors.pinkAccent;
    if(type==2) return Colors.blueAccent;
    return Colors.deepPurpleAccent;

  }
  createBox(String text,int type, VoidCallback func, double height, double width){
    return ElevatedButton(
        onPressed: func,
        style: ElevatedButton.styleFrom(primary:chooseColor(type),minimumSize: Size(width, height)),
        child: Container(
          alignment: Alignment.center,
          child: (type==5)?RotatedBox(
            quarterTurns: -1,
            child: Text(text,style: const TextStyle(fontSize: 10,color: Colors.white),),
          ):Text(text,textAlign: TextAlign.center,),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      controller: _mycontroller,
      child: Container(
        width: 1000,
        height: 700,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: Colors.cyan[200],
            borderRadius: const BorderRadius.all(Radius.circular(10.0))),
        child: Stack(children: <Widget>[
          if(widget.isPipelined!)
            Row(
              children: [
                Container(height: 700,width: 200,child: const Text('Fetch',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30),textAlign: TextAlign.center,),),
                Container(height: 700,width: 200,child: const Text('Decode',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30),textAlign: TextAlign.center,),),
                Container(height: 700,width: 200,child: const Text('Execute',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30),textAlign: TextAlign.center,),),
                Container(height: 700,width: 200,child: const Text('Memory',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30),textAlign: TextAlign.center,),),
                Container(height: 700,width: 180,child: const Text('Write-\nBack',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30),textAlign: TextAlign.center,),)
              ],
            ),
          ClipRect(
            child: CustomPaint(
              size: const Size(1000, 800),
              painter: ArrowPainter(),
            ),
          ),
          Row(
            //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 200,),
                  const SizedBox(height: 50,),
                  createBox('IsBranch\nMux', 2, () {return null;}, 100, 70),
                  const SizedBox(height: 70,),
                  createBox('PC', 1, () {return null;}, 50, 80), // PC
                  const SizedBox(height: 100,),
                  createBox('Instruction\nMemory', 0, () {return null;}, 180, 130),
                ],
              ),//Fetch
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 200,),
                  const SizedBox(height: 100,),
                  createBox('Adder', 3, () {}, 50, 50),
                  const SizedBox(height: 120,),
                  createBox('Sign\nExt.', 1, () { }, 160, 70),
                  const SizedBox(height: 30,),
                  createBox('Register\nFile', 0, () {widget.updateDisplay!(0);}, 150, 130),
                ],
              ),//Decode
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 200,),
                  const SizedBox(height: 60,),
                  createBox('Adder', 3, () {}, 70, 70),
                  const SizedBox(height: 40,),
                  createBox('Branch Target\nSelect Mux', 2, () {}, 100, 100),
                  const SizedBox(height: 100,),
                  createBox('OP2\nSelect\nMux', 2, () { }, 100, 70),
                  const SizedBox(height: 70,),
                  createBox('ALU', 1, () { }, 120, 120),

                ],
              ),//Execute
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 200,),
                  const SizedBox(height: 400,),
                  createBox('DATA\nMEMORY', 0, () { }, 160, 170),
                ],
              ),//Memory
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 180,),
                  const SizedBox(height: 300,),
                  createBox('Result\nSelect\nMux', 2, () { }, 200, 70),
                ],
              ),//Writeback
            ],
          ),
          if(widget.isPipelined!)
            Row(
              children: [
                const SizedBox(width: 180,),
                createBox('                     Fetch-Decode', 5, () {widget.updateDisplay!(1);}, 700, 10),
                const SizedBox(width: 160,),
                createBox('                                                                                                Decode-Execute', 5, () {widget.updateDisplay!(2);}, 700, 10),
                const SizedBox(width: 140,),
                createBox('Execute-Memory                                                                                                ', 5, () {widget.updateDisplay!(3);}, 700, 10),
                const SizedBox(width: 180,),
                createBox('                                                                                 Memory-WriteBack', 5, () {widget.updateDisplay!(4);}, 700, 10),
              ],
            ),
        ]
        ),
      ),
    );
  }
}
class ArrowPainter extends CustomPainter {
  createArrow(double x1,double y1,double x2,double y2,double x3,double y3,double x4,double y4,Canvas canvas,Paint paint){
    Path path = Path();
    path.moveTo(x1, y1);
    path.relativeLineTo(x2,y2);
    path.relativeLineTo(x3,y3);
    path.relativeLineTo(x4,y4);
    path = ArrowPath.make(path: path);
    canvas.drawPath(path, paint);
  }
  createText(Canvas canvas,Paint paint,String txt,double size,double x,double y){
    final TextSpan textSpan = TextSpan(
      text: txt,
      style: TextStyle(color: Colors.black, fontSize: size),
    );
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x,y));
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    ///Arrows
    createArrow(100, 140, 0, 70, 0, 0, 0, 0, canvas, paint);//Isbranch to pc
    createArrow(100, 250, 0, 100, 0, 0, 0, 0, canvas, paint);//pc to IM
    createArrow(100, 245, 190, 0, 0, -95, 0, 0, canvas, paint);//pc to adder
    createArrow(320, 245, 0, -95, 0, 0, 0, 0, canvas, paint);//4 to adder
    createArrow(305, 125, -160, 0, 0, 0, 0, 0, canvas, paint);//adder to isbranch
    createArrow(500, 95, -355, 0, 0, 0, 0, 0, canvas, paint); //Branch Target Address Arrow
    createArrow(300, 65, -155, 0, 0, 0, 0, 0, canvas, paint);//ALU result to IsBranch Arrow
    createArrow(500, 600, 200, 0, 0, -40, 0, 0, canvas, paint);//ALU to memory
    createArrow(700, 600, 110, 0, 0, -140, 40, 0, canvas, paint);//ALU to ResultSelect
    createArrow(500, 410, 115, 0, 0, 0, 0, 0, canvas, paint);//op2select to mem
    createArrow(700, 430, 150, 0, 0, 0, 0, 0, canvas, paint);//mem to result select
    createArrow(600, 75, -60, 0, 0, 0, 0, 0, canvas, paint);//pc to branch adder
    createArrow(500, 200, 100, 0, 0, -100, -60, 0, canvas, paint);// branch target to adder
    createArrow(780, 370, 70, 0, 0, 0, 0, 0, canvas, paint);// pc r select
    createArrow(300, 330, 550, 0, 0, 0, 0, 0, canvas, paint);// immu "
    createArrow(890, 490, 0, 160, -580, 0, 0, -60, canvas, paint);    // result select to rf
    createArrow(500, 445, 0, 70, 0, 0, 0, 0, canvas, paint);    //OP2 Select to ALU
    createArrow(300, 550, 140, 0, 0, 0, 0, 0, canvas, paint); //RF to ALU
    createArrow(100, 460, 135, 0, 0, 0, 0, 0, canvas, paint); // rs1 to rf
    createArrow(100, 490, 135, 0, 0, 0, 0, 0, canvas, paint); // rs1 to rf
    createArrow(100, 380, 165, 0, 0, 0, 0, 0, canvas, paint); // IM to sign ext
    createArrow(300, 500, 100, 0, 0, -70, 60, 0, canvas, paint); //RF to op2select
    createArrow(300, 370, 160, 0, 0, 0, 0, 0, canvas, paint); //sign ext to op2sel
    createArrow(300, 400, 160, 0, 0, 0, 0, 0, canvas, paint); //sign ext to op2sel
    createArrow(300, 300, 180, 0, 0, -40, 0, 0, canvas, paint);//sign ext to branch select
    createArrow(300, 315, 220, 0, 0, -55, 0, 0, canvas, paint);//sign ext to branch select

    ///Text
    createText(canvas, paint, '4', 20, 330, 190);
    createText(canvas, paint, 'RS1', 16, 180, 440);
    createText(canvas, paint, 'RS2', 16, 180, 470);
    createText(canvas, paint, 'Imm', 16, 360, 345);
    createText(canvas, paint, 'ImmS', 16, 360, 375);
    createText(canvas, paint, 'OP1', 16, 380, 525);
    createText(canvas, paint, 'OP2', 16, 365, 480);
    createText(canvas, paint, 'ImmJ', 16, 430, 270);
    createText(canvas, paint, 'ImmB', 16, 530, 270);
    createText(canvas, paint, 'ImmU', 16, 790, 310);
    createText(canvas, paint, 'PC+4', 16, 790, 350);
    createText(canvas, paint, 'Load\nData', 15, 800, 390);
    createText(canvas, paint, 'ALU Result', 16, 720, 570);
    createText(canvas, paint, 'PC', 16, 570, 50);
    createText(canvas, paint, 'ALU Result', 16, 200, 40);
    createText(canvas, paint, 'Branch Target Address', 16, 200, 70);

  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) => false;
}
