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
      body: const HomeBody()
    );
  }
}

class HomeBody extends StatelessWidget{
  const HomeBody({super.key});

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



class SingleCycle extends StatefulWidget {
  const SingleCycle({Key? key}) : super(key: key);

  @override
  State<SingleCycle> createState() => _SingleCycleState();
}

class _SingleCycleState extends State<SingleCycle> {
  String outputTxt='',displayTxt='';
  List<String>outputLines = [];
  int clock=0,
      displayStep=0,
      aluresult = 0,
      immediate = 0,
      operand1 = 0,
      operand2 = 0,
      loadData = 0,
      aluop = 0,
      branchtarget = 0,
      resultselect = 0,
      rs1 = 0,
      rs2 = 0,
      rd = 0,
      mcode = 0;
  int type = 0, funct3 = 0, funct7 = 0, pc = 0;
  bool outputRan = false,
      Rfwrite = false,
      Memop = false,
      op2select = false,
      isBranch = false,
      running = true;
  List n=[];
  final RF = List<int>.filled(32, 0);
  final b = List<int>.filled(32, 0);
  final im = List<int>.filled(32, 0);
  final t = List<int>.filled(32, 0);
  Map<int, int> MEM = Map<int, int>();

  void dec2bin(int value) {
    if (value < 0) value = (1 << 32) + value;

    for (int i = 0; i < 32; i++) {
      t[i] = 0;
    }

    int i = 0;
    while (value > 0 && i <= 31) {
      t[i] = value % 2;
      double next=value/2;
      value=next.toInt();
      i++;
    }
  }

  int comp2() {
    int c = t[31];
    if (c == 1) {
      for (int i = 0; i <= 31; i++) {
        if(t[i]==1)t[i]=0;
        else t[i]=1;
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

  void lw(int Eaddress) {
    loadData = MEM[Eaddress] ?? 0;
  }

  void lb(int Eaddress, int index) {
    int element = MEM[Eaddress] ?? 0;
    loadData = ((element >> (8 * index)) & 0xFF);
    for (int i = 0; i <= 7; i++) {
      t[i] = (loadData >> i) & 1;
    }
    for (int i = 8; i <= 31; i++) {
      t[i] = t[7];
    }
    loadData = comp2();
  }

  void lh(int Eaddress, int index) {
    int element = MEM[Eaddress] ?? 0;
    loadData = ((element >> (8 * index)) & 0xFFFF);
    for (int i = 0; i <= 15; i++) {
      t[i] = (loadData >> i) & 1;
    }
    for (int i = 16; i <= 31; i++) {
      t[i] = t[15];
    }
    loadData = comp2();
  }

  void sb(int Eaddress, int index) {
    int element = MEM[Eaddress] ?? 0;
    for (int i = 0; i <= 31; i++) {
      t[i] = (element >> i) & 1;
    }
    index = 8 * index;
    for (int i = 0; i <= 7; i++) {
      t[index] = (operand2 >> i) & 1;
      index = index + 1;
    }
    MEM[Eaddress] = comp2();
  }

  void sh(int Eaddress, int index) {
    int element = MEM[Eaddress] ?? 0;
    for (int i = 0; i <= 31; i++) {
      t[i] = (element >> i) & 1;
    }
    index = 8 * index;
    for (int i = 0; i <= 15; i++) {
      t[index] = (operand2 >> i) & 1;
      index = index + 1;
    }
    MEM[Eaddress] = comp2();
  }

  void sw(int Eaddress) {
    MEM[Eaddress] = operand2;
  }

  void fetch(File f) {
    int mcode = MEM[pc] ?? 0;
    if (mcode == 0 || mcode == -285212655) {
      swi_exit(f);
    }
    else
    {dec2bin(mcode);for(int i=0;i<32;i++){b[i]=t[i];}}
    outputTxt+='FETCH: Read instruction 0x${'0'*(8-(MEM[pc]??0).toRadixString(16).length)}${(MEM[pc]??0).toRadixString(16)} from address 0x${pc.toRadixString(16)}.\n';
  }

  void decode() {
    //finding opcode,funct7,funct3,rs1,rs2,rs
    for (int i = 6; i >= 0; i--) {
      type = (2 * type) + b[i];
    }
    for (int i = 14; i >= 12; i--) {
      funct3 = (2 * funct3) + b[i];
    }
    for (int i = 31; i >= 25; i--) {
      funct7 = (2 * funct7 + b[i]);
    }
    for (int i = 19; i >= 15; i--) {
      rs1 = (2 * rs1 + b[i]);
    }
    for (int i = 24; i >= 20; i--) {
      rs2 = (2 * rs2 + b[i]);
    }
    for (int i = 11; i >= 7; i--) {
      rd = (2 * rd + b[i]);
    }
    //immediate bits list
    for (int i = 0; i <= 31; i++) {
      im[i] = 0;
    }
    ///i type
    if (type == 19 || type == 3 || type == 103) {
      for (int i = 20; i <= 31; i++) {
        im[i - 20] = b[i];
      }
      for (int i = 12; i <= 31; i++) {
        im[i] = im[11];
      }
    }

    ///j type
    else if (type == 111) {
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
    else if (type == 55 || type == 23) {
      for (int i = 12; i <= 31; i++) {
        im[i] = b[i];
      }
    }

    ///b type
    else if (type == 99) {
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
    else if(type==35) {
      for (int i = 7; i <= 11; i++) {
        im[i - 7] = b[i];
      }
      for (int i = 25; i <= 30; i++) {
        im[i - 20] = b[i];
      }
      for (int i = 12; i <= 31; i++) {
        im[i] = im[11];
      }
    }
//Rfwrite
    if(type!=99 && type!=35){Rfwrite=true;}
//resultselect
    if (type == 3) resultselect = 1; //load mode
    else if (type == 111 || type == 103) resultselect = 2; //jal|jalr pc+4
    else if(type==23)resultselect=3;
    else if(type==55)resultselect=4;

//op2select
    if(type==19 || type==3 || type==35)op2select=true;
//MEmop
    if(type==35)Memop=true;
//ALUOP
    if (type == 99 || (type == 51 && funct3 == 0 && funct7 == 32)) {
      aluop = 1;
    } //sub
    else if (funct3 == 7 && (type == 51 || type == 19))
      aluop = 2; //and
    else if (funct3 == 6 && (type == 51 || type == 19))
      aluop = 3; //or
    else if (type == 51 && funct3 == 4)
      aluop = 4; //xor
    if (type == 51) {
      if (funct3 == 1) aluop = 5; //sll
      else if (funct3 == 5 && funct7 == 32)
        aluop = 7; //sra
      else if(funct3==5 && funct7==0)
        aluop = 6; //srl
      else if(funct3==2)aluop=8;
    }
//immediate sign extension
    for (int i = 0; i < 32; i++) {
      t[i] = im[i];
    }
    immediate = comp2();
//registers
    operand1 = RF[rs1];
    operand2 = RF[rs2];
    //message
    outputTxt+="DECODE: Operation is ";
    if(type==51)
    {
      if (funct3==0){
        if(funct7==0){outputTxt+="ADD, ";}
        else outputTxt+="SUB, ";
      }
      else if(funct3==7)outputTxt+="AND, ";
      else if(funct3==6)outputTxt+="OR, ";
      else if(funct3==4)outputTxt+="XOR, ";
      else if(funct3==1)outputTxt+="SLL, ";
      else if(funct3==2)outputTxt+="SLT, ";
      else if(funct3==5){
        if(funct7==0){outputTxt+="SRL, ";}
        else outputTxt+="SRA, ";
      }
      outputTxt+="rs1 is x${rs1}, rs2 is x${rs2} and destination register is x${rd}.\n";
    }
    else if(type==19)
    {
      if(funct3==0){outputTxt+="ADDI, ";}
      else if(funct3==6){outputTxt+="ORI, ";}
      else if(funct3==7){outputTxt+="ANDI, ";}
      outputTxt+="rs1 is x${rs1}, immediate is ${immediate} and destination register is x${rd}.\n";
    }
    else if(type==3)
    {
      if(funct3==0){outputTxt+="LB, ";}
      else if(funct3==1){outputTxt+="LH, ";}
      else if(funct3==2){outputTxt+="LW, ";}
      outputTxt+="rs1 is x${rs1}, immediate is ${immediate} and destination register is x${rd}.\n";
    }
    else if(type==103){
      outputTxt+="JALR, rs1 is x${rs1}, immediate is ${immediate} and destination register is x${rd}.\n";
    }
    else if(type==35){
      if(funct3==0){outputTxt+="SB, ";}
      else if(funct3==1){outputTxt+="SH, ";}
      else if(funct3==2){outputTxt+="SW, ";}
      outputTxt+="rs1 is x${rs1}, immediate is ${immediate} and rs2 is x${rs2}.\n";
    }
    else if(type==99){
      if(funct3==0){outputTxt+="BEQ, ";}
      else if(funct3==1){outputTxt+="BNE, ";}
      else if(funct3==4){outputTxt+="BLT, ";}
      else if(funct3==5){outputTxt+="BGE, ";}
      outputTxt+="rs1 is x${rs1}, immediate is ${immediate} and rs2 is x${rs2}.\n";
    }
    else if(type==111){
      outputTxt+="JAL, immediate is ${immediate} and rd is x${rd}.\n";
    }
    else if(type==55)
    {
      outputTxt+="LUI, immediate is ${immediate} and rd is x${rd}.\n";
    }
    else if(type==23){
      outputTxt+="AUIPC, immediate is ${immediate} and rd is x${rd}.\n";
    }

  }

  void execute() {
    int temp = operand2;
    outputTxt+="EXECUTE: ";
    if (op2select == true) temp = immediate;
    switch (aluop) {
      case 0:
        {
          outputTxt+="ADD ${operand1} and ${temp}.\n";
          aluresult = temp + operand1;
          if(aluresult>2147483647){aluresult=-2147483648+(aluresult-2147483648);}
          else if(aluresult<-2147483648){aluresult=2147483647+(2147483649+aluresult);}
        }
        break;

      case 1:
        {
          outputTxt+="SUBTRACT ${temp} from ${operand1}.\n";
          aluresult = operand1 - temp;
          if(aluresult>2147483647){aluresult=-2147483648+(aluresult-2147483648);}
          else if(aluresult<-2147483648){aluresult=2147483647+(2147483649+aluresult);}
        }
        break;

      case 2:
        {
          outputTxt+="LOGICAL 'AND' of ${operand1} and ${temp}.\n";
          aluresult = operand1 & temp;
        }
        break;

      case 3:
        {
          outputTxt+="LOGICAL 'OR' of ${operand1} and ${temp}.\n";
          aluresult = operand1 | temp;
        }
        break;

      case 4:
        {
          outputTxt+="LOGICAL 'XOR' of ${operand1} and ${temp}.\n";
          aluresult = operand1 ^ temp;
        }
        break;

      case 5:
        {
          outputTxt+="SHIFT left ${operand1} ${temp} times.\n";
          aluresult=operand1;
          for(int i=0;i<temp;i++){
            aluresult=aluresult<<1;
            if(aluresult>2147483647){aluresult=-2147483648+(aluresult-2147483648);}
            else if(aluresult<-2147483648){aluresult=2147483647+(2147483649+aluresult);}
          }
        }break;
    //list use for srl
      case 6:
        {
          outputTxt+="LOGICAL SHIFT right ${operand1} ${temp} times.\n";
          dec2bin(operand1);
          int i = 0;
          for (; i <= 31 - temp && i<=31; i++) {
            t[i] = t[i + temp];
          }
          while (i <= 31) {
            t[i] = 0;
            i++;
          }
          aluresult = comp2();
        }
        break;

      case 7:
        {
          outputTxt+="ARITHMETIC SHIFT right ${operand1} ${temp} times.\n";
          aluresult = operand1 >> temp;
        }
        break;

      case 8:
        {
          outputTxt+="SET less than ${operand1} ${temp} times.\n";
          if(operand1<temp)aluresult=1;
          else aluresult=0;
        }break;
    }
    //branch
    if(type==99 || type==111)branchtarget = pc + immediate;
    else if(type==103)branchtarget=aluresult;
    if (type == 111 || type==103)
      isBranch = true;
    else if (type == 99) {
      if (funct3 == 0 && operand1==operand2) isBranch = true;
      else if (funct3 == 1 && operand1!=temp) isBranch = true;
      else if (funct3 == 4 && operand1<temp) isBranch = true;
      else if (funct3 == 5 && operand1 >= temp) isBranch = true;
    }

  }

  void memory() {
    int Eaddress = aluresult - (aluresult % 4);
    int index = aluresult % 4;
    outputTxt+="MEMORY: ";
    for (int i = 0; i < 32; i++) {
      t[i] = 0;
    }
    if (Memop == false) {

      if(type==3)
      {outputTxt+="Load from address 0x${aluresult.toRadixString(16)}.\n";}
      else outputTxt+="No memory operation.\n";

      if (funct3 == 0) {
        lb(Eaddress, index);
      } else if (funct3 == 1) {
        lh(Eaddress, index);
      } else if(funct3==2) {
        lw(Eaddress);
      }
    } else {
      outputTxt+="Store at address 0x${aluresult.toRadixString(16)}.\n";

      if (funct3 == 0) {
        sb(Eaddress, index);
      } else if (funct3 == 1) {
        sh(Eaddress, index);
      } else if(funct3==2){
        sw(Eaddress);
      }

    }
  }

  void write_back() {

    outputTxt+="WRITEBACK: ";

    int word = aluresult;
    if (Rfwrite == true) {

      outputTxt+="Write to x${rd}. ";

      if (resultselect == 1)
        word = loadData;
      else if (resultselect == 2)
        word = pc + 4;
      else if (resultselect == 3)
        word = pc + immediate;
      else if (resultselect == 4) word = immediate;

      if(rd!=0)
        RF[rd] = word;
      else RF[0]=0;
    }
    if (isBranch == true) {
      pc = branchtarget;
    } else
      pc = pc + 4;

    outputTxt+="PC is updated to 0x${pc.toRadixString(16)}.\n";
  }

  void reset_proc() {
    aluresult = 0; immediate = 0; operand1 = 0;  operand2 = 0; loadData = 0;  aluop = 0;  branchtarget = 0;  resultselect = 0;  rs1 = 0;
    rs2 = 0;  rd = 0;  type = 0;  funct3 = 0;  funct7 = 0;
    Rfwrite = false;   Memop = false;  op2select = false;  isBranch = false;
    for (int i = 0; i <= 31; i++) {
      b[i] = 0;  im[i] = 0;  t[i] = 0;
    }
  }

  void swi_exit(File f) {
    write_datamemory(f);
    running = false;
  }

  void write_datamemory(File myOutFile){
    myOutFile.writeAsStringSync("ADDRESS\t\t\t\tDATA\n\n",mode:FileMode.append);
    for(var i in MEM.keys){
      String adress=i.toRadixString(16);
      int val=MEM[i]??0;
      if(val<0){val=(1<<32)+val;}
      adress="0x"+'0'*(8-adress.length)+adress+"\t\t\t0x"+'0'*(8-val.toRadixString(16).length)+val.toRadixString(16)+"\n";
      myOutFile.writeAsStringSync(adress,mode:FileMode.append);
    }
  }

  void run_riscvsim(File f){
    pc=0;
    clock=0;
    displayStep=0;
    while(running){
      fetch(f);
      decode();
      execute();
      memory();
      write_back();
      reset_proc();
      clock++;
      outputTxt+='CLOCK CYCLES ELAPSED = $clock\n\n';
    }
    outputLines = outputTxt.split('\n\n');
  }

  void load_progmem(){
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
      MEM[address]=instruct;
    }
  }

  void singleCycleCode(PlatformFile inputFile)async{
    // print(Directory(inputFile.path!).parent.path);
    // print(basenameWithoutExtension(inputFile.path!));
    String strPath ='${Directory(inputFile.path!).parent.path}\\${basenameWithoutExtension(inputFile.path!)}_output.txt';
    // print(strPath);
    File outputFile = File(strPath);

    File file = File(inputFile.name);
    List<String> s=file.readAsLinesSync();
    for(int i=0;i<s.length;i++)
    {n.add(s[i]);}
    reset_proc();
    running=true;
    outputRan = false;
    RF[2]=2147483644;
    load_progmem();
    run_riscvsim(outputFile);
  }

  void myFilePicker()async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mc'],
    );
    if (result==null) return;
    PlatformFile myFile = result.files.single;
    outputTxt='CLOCK CYCLES ELAPSED = 0\n\n';
    displayTxt='CLOCK CYCLES ELAPSED = 0\n\n';
    singleCycleCode(myFile);
    displayOutput();
  }

  void displayOutput() {
    setState(() {;});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: (){
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Single Cycle'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: 'Select .mc file',
            onPressed: (){
              myFilePicker();
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Information'),
                  content: const Text('If a file is selected, the output file will be created in the same directory.'),
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
      body: Container(
        width: 500,
        padding: const EdgeInsets.all(10),
        child: Column(

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: (){
                    if(!outputRan && displayStep<outputLines.length) {
                      displayStep++;
                      displayTxt += '${outputLines[displayStep]}\n\n';
                      displayOutput();
                    }
                  },
                  child: const Text('Step'),
                ),
                ElevatedButton(
                  onPressed: (){
                    if(!outputRan) {
                      outputRan=true;
                      displayTxt = outputTxt;
                      displayOutput();
                    }
                  },
                  child:const Text('Run')
                ),
                ElevatedButton(
                    onPressed: (){
                      outputRan = false;
                      displayTxt = '${outputLines[0]}\n\n';
                      displayStep=0;
                      displayOutput();
                    },
                    child:const Text('Reset')
                ),
              ],
            ),
            const SizedBox(height: 10,),
            Expanded(
              child:Container(
                width: 500,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Text(
                    displayTxt,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
