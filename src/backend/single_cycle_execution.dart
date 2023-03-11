import "dart:io";
import "dart:async";
import "dart:convert";

  int aluresult = 0,
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
  bool Rfwrite = false,
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
    int j = 0;
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
    int j = 0;
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

  void fetch() {
    int mcode = MEM[pc] ?? 0;
    if (mcode == 0 || mcode == -285212655) {
      swi_exit();
    }
    else
    {dec2bin(mcode);for(int i=0;i<32;i++){b[i]=t[i];}}
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
    else if(type==35)
    {
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
  }

  void execute() {
    int temp = operand2;
    if (op2select == true) temp = immediate;
    switch (aluop) {
      case 0:
        {
          aluresult = temp + operand1;
          if(aluresult>2147483647){aluresult=-2147483648+(aluresult-2147483648);}
          else if(aluresult<-2147483648){aluresult=2147483647+(2147483649+aluresult);}
        }
        break;

      case 1:
        {
          aluresult = operand1 - temp;
          if(aluresult>2147483647){aluresult=-2147483648+(aluresult-2147483648);}
          else if(aluresult<-2147483648){aluresult=2147483647+(2147483649+aluresult);}
        }
        break;

      case 2:
        {
          aluresult = operand1 & temp;
        }
        break;

      case 3:
        {
          aluresult = operand1 | temp;
        }
        break;

      case 4:
        {
          aluresult = operand1 ^ temp;
        }
        break;

      case 5:
        {
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
          aluresult = operand1 >> temp;
        }
        break;

      case 8:
        {
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
    for (int i = 0; i < 32; i++) {
      t[i] = 0;
    }
    if (Memop == false) {

      if (funct3 == 0) {
        lb(Eaddress, index);
      } else if (funct3 == 1) {
        lh(Eaddress, index);
      } else if(funct3==2) {
        lw(Eaddress);
      }
    } else {
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

    int word = aluresult;
    if (Rfwrite == true) {
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
  }

  void reset_proc() {
    aluresult = 0; immediate = 0; operand1 = 0;  operand2 = 0; loadData = 0;  aluop = 0;  branchtarget = 0;  resultselect = 0;  rs1 = 0;
    rs2 = 0;  rd = 0;  type = 0;  funct3 = 0;  funct7 = 0;
    Rfwrite = false;   Memop = false;  op2select = false;  isBranch = false;
    for (int i = 0; i <= 31; i++) {
      b[i] = 0;  im[i] = 0;  t[i] = 0;
    }
  }

  void swi_exit() {
    //write_datamemory();
    print(RF);
    running = false;
  }

  void write_datamemory(){
    
     myOutfile.writeAsStringSync("address       Data\n",mode:FileMode.append);
    for(var i in MEM.keys){
    String adress=i.toRadixString(16);
    int val=MEM[i]??0;
    if(val<0){val=(1<<32)+val;}
    adress="0x"+adress+"       0x"+val.toRadixString(16)+"\n";
     myOutfile.writeAsStringSync(adress,mode:FileMode.append);
  }
 
  }

  void run_riscvsim(){
    RF[23]=7;
    RF[24]=4;
    while(running){
      fetch();
      decode();
      execute();
      memory();
      write_back();
      reset_proc();
    }
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


void main() {
  var path='test.txt';
  
  var file= new File(path);
  List<String> s=file.readAsLinesSync();
  for(int i=0;i<s.length;i++)
  {n.add(s[i]);}
  reset_proc();
  RF[2]=2147483644;
  RF[5]=6;
  load_progmem();
  run_riscvsim();
}
