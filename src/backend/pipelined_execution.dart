
import "dart:io";
import "dart:async";
import "dart:convert";
  int pc = 0,count=0,btarget=0;
  bool 
      knob1=true,
      running=true,
      isBranchtaken=false;
  List n=[];
  final RF = List<int>.filled(32, 0);
  final b = List<int>.filled(32, 0);
  final im = List<int>.filled(32, 0);
  final t = List<int>.filled(32, 0);
  final if_de=List<int>.filled(2, 0);
  final t1=List<int>.filled(2, 0);
  final de_ex =List<int>.filled(13, 0);//pc,instruction,op2,op1,immediate,branchtarget,op2select,aluop,branchselect,resultselect,memop,rfwrite,isbranch
  final t2 =List<int>.filled(13, 0);
  final ex_ma = List<int>.filled(9, 0);//pc,instruction,aluresult,op2,memop,resultselect,rfwrite,isbranch,immediate
  final t3 = List<int>.filled(9, 0);
  final ma_wb = List<int>.filled(5, 0);//pc,instruction,result,rfwrite,isbranch
  final t4 = List<int>.filled(5, 0);
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

  int lw(int Eaddress) {
    return MEM[Eaddress] ?? 0;
  }

  int lb(int Eaddress, int index) {
    int element = MEM[Eaddress] ?? 0;
    int data = ((element >> (8 * index)) & 0xFF);
    for (int i = 0; i <= 7; i++) {
      t[i] = (data >> i) & 1;
    }
    for (int i = 8; i <= 31; i++) {
      t[i] = t[7];
    }
    return comp2();
  }

  int lh(int Eaddress, int index) {
    int element = MEM[Eaddress] ?? 0;
    int data = ((element >> (8 * index)) & 0xFFFF);
    for (int i = 0; i <= 15; i++) {
      t[i] = (data >> i) & 1;
    }
    for (int i = 16; i <= 31; i++) {
      t[i] = t[15];
    }
    return comp2();
  }

  void sb(int Eaddress, int index) {
    int datain=ex_ma[3];
    //if(ex_ma[1]>>20&0x1F==ma_wb[1]>>7&0x1F &&(ma_wb[3]==1))datain=ma_wb[2];
    int element = MEM[Eaddress] ?? 0;
    for (int i = 0; i <= 31; i++) {
      t[i] = (element >> i) & 1;
    }
    index = 8 * index;
    for (int i = 0; i <= 7; i++) {
      t[index] = (datain >> i) & 1;
      index = index + 1;
    }
    MEM[Eaddress] = comp2();
  }

  void sh(int Eaddress, int index) {
    int datain=ex_ma[3];
    //if(ex_ma[1]>>20&0x1F==ma_wb[1]>>7&0x1F &&(ma_wb[3]==1))datain=ma_wb[2];
    int element = MEM[Eaddress] ?? 0;
    for (int i = 0; i <= 31; i++) {
      t[i] = (element >> i) & 1;
    }
    index = 8 * index;
    for (int i = 0; i <= 15; i++) {
      t[index] = (datain >> i) & 1;
      index = index + 1;
    }
    MEM[Eaddress] = comp2();
  }

  void sw(int Eaddress) {
    int datain=ex_ma[3];
    //if(ex_ma[1]>>20&0x1F==ma_wb[1]>>7&0x1F &&(ma_wb[3]==1))datain=ma_wb[2];
    MEM[Eaddress] = datain;
  }

  void fetch() {
     t1[0]=pc;t1[1]=MEM[pc]??0;
  }
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  void decode_p(){
    //0,1,2,3,4,6,7,9,10,11
    t2[0]=if_de[0];t2[1]=if_de[1];
    t2[2]=RF[(t2[1]>>20)&0x1F];
    t2[3]=RF[(t2[1]>>15)&0x1F];
    //immediate
    //immediate bits list
    for (int i = 0; i <= 31; i++) {
      im[i] = 0;b[i]=0;t[i]=0;
    }
    dec2bin(if_de[1]);
    for(int i=0;i<32;i++){b[i]=t[i];}

    ///i type
    if (if_de[1]&0x3F == 19 || if_de[1]&0x3F == 3 || if_de[1]&0x3F == 103) {
      for (int i = 20; i <= 31; i++) {
        im[i - 20] = b[i];
      }
      for (int i = 12; i <= 31; i++) {
        im[i] = im[11];
      }
    }

    ///j type
    else if (if_de[1]&0x3F == 111) {
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
    else if (if_de[1]&0x3F == 55 || if_de[1]&0x3F == 23) {
      for (int i = 12; i <= 31; i++) {
        im[i] = b[i];
      }
    }

    ///b type
    else if (if_de[1]&0x3F == 99) {
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
    else if(if_de[1]&0x3F==35)
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

    //immediate sign extension
    for (int i = 0; i < 32; i++) {
      t[i] = im[i];
    }
    t2[4] = comp2();

    //Rfwrite
    if(t2[1]&0x3F==51 || t2[1]&0x3F==19 || t2[1]&0x3F==3 || t2[1]&0x3F==111 || t2[1]&0x3F==103 || t2[1]&0x3F==55 || t2[1]&0x3F==23){t2[11]=1;}

    //resultselect
    if (t2[1]&0x3F == 3) t2[9] = 1; //load mode
    else if (t2[1]&0x3F == 111 || t2[1]&0x3F == 103) t2[9] = 2; //jal|jalr pc+4
    else if(t2[1]&0x3F==23)t2[9]=3;//auipc
    else if(t2[1]&0x3F==55)t2[9]=4;//lui

   //op2select
    if(t2[1]&0x3F==19 || t2[1]&0x3F==3 || t2[1]&0x3F==35 || t2[1]&0x3F==103)t2[6]=1;

   //MEmop
    if(t2[1]&0x3F==35)t2[10]=1;//for store 

   //ALUOP
    if (t2[1]&0x3F == 99 || (t2[1]&0x3F == 51 && t2[1]>>12&0x3 == 0 && t2[1]>>25&0x3F == 32)) {
      t2[7] = 1;
    } //sub
    else if (t2[1]>>12&0x3 == 7 && (t2[1]&0x3F == 51 || t2[1]&0x3F == 19))
      t2[7] = 2; //and
    else if (t2[1]>>12&0x3 == 6 && (t2[1]&0x3F == 51 || t2[1]&0x3F == 19))
      t2[7] = 3; //or
    else if (t2[1]&0x3F == 51 && t2[1]>>12&0x3 == 4)
      t2[7] = 4; //xor
    if (t2[1]&0x3F == 51) {
      if (t2[1]>>12&0x3 == 1) t2[7] = 5; //sll
      else if (t2[1]>>12&0x3 == 5 && t2[1]>>25&0x3F == 32)
        t2[7] = 7; //sra
      else if(t2[1]>>12&0x3==5 && t2[1]>>25&0x3F==0)
        t2[7] = 6; //srl
      else if(t2[1]>>12&0x3==2)t2[7]=8;
    }   
  }
  void execute() {
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
      
      int temp = de_ex[2];
      int op1=de_ex[3];
    
    if (de_ex[6]==1) temp = de_ex[4];
    switch (de_ex[7]) {
      case 0:
        {
          t3[2] = temp + op1;
          if(t3[2]>2147483647){t3[2]=-2147483648+(t3[2]-2147483648);}
          else if(t3[2]< -2147483648){t3[2]=2147483647+(2147483649+t3[2]);}
        }
        break;

      case 1:
        {
          t3[2] = op1 - temp;
          if(t3[2]>2147483647){t3[2]=-2147483648+(t3[2]-2147483648);}
          else if(t3[2]< -2147483648){t3[2]=2147483647+(2147483649+t3[2]);}
        }
        break;

      case 2:
        {
          t3[2] = op1 & temp;
        }
        break;

      case 3:
        {
          t3[2] = op1 | temp;
        }
        break;

      case 4:
        {
          t3[2] = op1 ^ temp;
        }
        break;

      case 5:
        {
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
          t3[2] = op1 >> temp;
        }
        break;

      case 8:
        {
          if(op1<temp)t3[2]=1;
          else t3[2]=0;
        }break;
    }
    //branch
    btarget=pc+4;
    if(de_ex[1]&0x3F==99 || de_ex[1]&0x3F==111)btarget = de_ex[0] + de_ex[4];
    else if(de_ex[1]&0x3F==103)btarget=temp+op1;
    if (de_ex[1]&0x3F == 111 || de_ex[1]&0x3F==103) {t3[7] = 1;}
    if(de_ex[1]&0x3F==99){
      if ((de_ex[1]>>12)&0x3 == 0 && (t3[2]==0)) t3[7] = 1;
      else if ((de_ex[1]>>12)&0x3 == 1 && (t3[2]!=0)) t3[7] = 1;
      else if ((de_ex[1]>>12)&0x3 == 4 && (t3[2]<0)) t3[7] = 1;
      else if ((de_ex[1]>>12)&0x3 == 5 && (t3[2] >= 0)) t3[7] = 1;
    }
    ////////branch target remaining////////////
    if(t3[7]==1 && (de_ex[1]&0x3F==99 || de_ex[1]&0x3F == 111 || de_ex[1]&0x3F==103)){isBranchtaken=true;}
    
  }
  void memory() {
    //pipelined 
    if(knob1==true){
      t4[0]=ex_ma[0];t4[1]=ex_ma[1];t4[3]=ex_ma[6];t4[4]=ex_ma[7];
      int Eaddress = ex_ma[2] - (ex_ma[2] % 4);
      int index = ex_ma[2] % 4;
      for (int i = 0; i < 32; i++) {
      t[i] = 0;
    }
    if (ex_ma[4] == 0) {

      if ((ex_ma[1]>>12)&0x3 == 0) {
        t4[2]=lb(Eaddress, index);
      } else if ((ex_ma[1]>>12)&0x3 == 1) {
        t4[2]=lh(Eaddress, index);
      } else if((ex_ma[1]>>12)&0x3 == 2) {
        t4[2]=lw(Eaddress);
      }
    } else if(ex_ma[4]==1) {
      if ((ex_ma[1]>>12)&0x3 == 0) {
        sb(Eaddress, index);
      } else if ((ex_ma[1]>>12)&0x3 == 1) {
        sh(Eaddress, index);
      } else if((ex_ma[1]>>12)&0x3 == 2) {
        sw(Eaddress);
      }
    }
      
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
  }
  void write_back(File f) {
        if( ma_wb[3]==1  &&   ((ma_wb[1]>>7)&0x1F)!=0 ){
          RF[(ma_wb[1]>>7)&0x1F]=ma_wb[2];
        }
        if(ma_wb[1]==1){swi_exit(f);}
  }
  void transfer()
  {

     if(hazardDetect(de_ex[1])==false && hazardDetect(ex_ma[1])==false && hazardDetect(ma_wb[1])==false){
      if(isBranchtaken==true)pc=btarget;
      else pc=pc+4;
      //if to de//
      if_de[0]=t1[0];if_de[1]=t1[1];
      //de to ex//
      for(int i=0;i<13;i++){de_ex[i]=t2[i];}
     }
     else{
      de_ex[0]=0;de_ex[1]=19;for(int i=2;i<13;i++){de_ex[i]=0;}
     }
     if(isBranchtaken==true){isBranchtaken=false;if_de[0]=0;if_de[1]=19;de_ex[0]=0;de_ex[1]=19;for(int i=2;i<13;i++){de_ex[i]=0;}}
     //ma to wb//
     for(int i=0;i<9;i++){ex_ma[i]=t3[i];}
     for(int i=0;i<5;i++){ma_wb[i]=t4[i];}

  }
  void swi_exit(File f) {
    print(RF);
    exit(0);
  }
  bool hazardDetect(int instruction){
    int opcode=instruction&0x3F;
    bool hasrs1=true,hasrs2=false;
    if(opcode==35 || opcode==99 || opcode==0 || instruction==19){return false;}
    if(if_de[1]&0x3F==111 || if_de[1]&0x3F==55 || if_de[1]&0x3F==23){return false;}
    if(if_de[1]&0x3F==51 || if_de[1]&0x3F==35 || if_de[1]&0x3F==99){hasrs2=true;}
    if(hasrs1==true && ((if_de[1]>>15)&0x1F == (instruction>>15)&0x1F)){return true;}
    if(hasrs2==true && ((if_de[1]>>20)&0x1F == (instruction>>20)&0x1F)){return true;}
    return false;
  }
  void run_riscvsim(File f){
    while(running){
      fetch();
      decode_p();
      execute();
      memory();
      write_back(f);
      transfer();
      //print("**************************");
      //print("${t1} ${t2} ${t3} ${t4}" );
      print(pc);
      count++;
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
  RF[2]=2147483644;
  load_progmem();
  run_riscvsim(file);
}
