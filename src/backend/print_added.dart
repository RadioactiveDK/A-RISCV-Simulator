import "dart:io";
import "dart:async";
import "dart:convert";
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
  int pc = 0,count=0,btarget=0,instructCount=0,dataCount=0,controlCount=0,stallCount=0,dataHazard=0,controlHazard=0,misPredict=0,dataStalls=0,controlStalls=0;
  bool 
      knob1=true,
      knob2=true,
      running=true,
      isBranchtaken=false,
      loadHazard=false;
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
  Map<int,int> INS=Map<int,int>();
  List <BTB> buffer=[];

  void dec2bin(int value) {
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

  int comp2() {

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
    if(src2Hazard(ma_wb[1], ex_ma[1]) && knob2==true){
      datain=ma_wb[2];}

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
    if(src2Hazard(ma_wb[1], ex_ma[1]) && knob2==true){
      datain=ma_wb[2];}

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
    if(src2Hazard(ma_wb[1], ex_ma[1]) && knob2==true){
      datain=ma_wb[2]; }

    MEM[Eaddress] = datain;
  }

  void fetch() {
     t1[0]=pc;t1[1]=INS[pc]??0;
     displayTxt +='FETCH: Read instruction from address 0x${pc.toRadixString(16)}.\n';
  }
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  void decode_p(){
    //0,1,2,3,4,6,7,9,10,11
    t2[0]=if_de[0];t2[1]=if_de[1];
    t2[2]=RF[(t2[1]>>20)&0x1F];
    t2[3]=RF[(t2[1]>>15)&0x1F];
    //display
    displayTxt += "DECODE: ";
    if(if_de[1]&0x7F==99 ||if_de[1]&0x7F == 111 || if_de[1]&0x7F==103)displayTxt += "\nControl Hazard detected at instruction ${if_de[0]/4}\n";
    if(knob2==true){
    //forwarding:
      if(src1Hazard(ma_wb[1],if_de[1])){t2[3]=ma_wb[2];displayTxt+="\nHazard detected between instructions number ${if_de[0]/4}(Decode) and ${ma_wb[0]/4}(Writeback) and WB-DE forwarding used.\n";}
      if(src2Hazard(ma_wb[1],if_de[1])){t2[2]=ma_wb[2];displayTxt+="\nHazard detected between instructions number ${if_de[0]/4}(Decode) and ${ma_wb[0]/4}(Writeback) and WB-DE forwarding used.\n";}
    //load-use hazard
     if(src2Hazard(de_ex[1],if_de[1]) && de_ex[1]&0x7F==3){loadHazard=true;displayTxt+="\nLoad Hazard detected between instructions number ${if_de[0]/4}(Decode) and ${de_ex[0]/4}(Execute) and no forwarding used.\n";}
     if(src1Hazard(de_ex[1],if_de[1]) && de_ex[1]&0x7F==3){loadHazard=true;displayTxt+="\nLoad Hazard detected between instructions number ${if_de[0]/4}(Decode) and ${de_ex[0]/4}(Execute) and no forwarding used.\n";}
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
    
    if(!(if_de[0]==0 && if_de[1]==19)){displayTxt += "Instruction number ${if_de[0]/4}, ";}
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

      displayTxt += "EXECUTE: ";
      if(!(if_de[0]==0 && if_de[1]==19)){displayTxt += "Instruction number ${de_ex[0]/4}, ";}
      if(de_ex[0]==0 && de_ex[1]==19)displayTxt+="NOP/BUBBLE instruction  ";
      int temp = de_ex[2];
      int op1=de_ex[3];
      if(knob2==true){
      //forwarding:
      if(src1Hazard(ex_ma[1],de_ex[1]) && ex_ma[1]&0x7F!=3){
        displayTxt+="\nHazard detected between instructions number ${de_ex[0]/4}(Execute) and ${ex_ma[0]/4}(Memory) and MA-EX forwarding used.\n";
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
      else if(src1Hazard(ma_wb[1],de_ex[1])){op1=ma_wb[2];displayTxt+="\nHazard detected between instructions number ${de_ex[0]/4}(Execute) and ${ma_wb[0]/4}(Writeback) and WB-EX forwarding used.\n";}
    

      if(src2Hazard(ex_ma[1],de_ex[1]) && ex_ma[1]&0x7F!=3){
        displayTxt+="\nHazard detected between instructions number ${de_ex[0]/4}(Execute) and ${ex_ma[0]/4}(Memory) and MA-EX forwarding used.\n";
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
      else if(src2Hazard(ma_wb[1],de_ex[1])){temp=ma_wb[2];t3[3]=ma_wb[2];displayTxt+="\nHazard detected between instructions number ${de_ex[0]/4}(Execute) and ${ma_wb[0]/4}(Writeback) and WB-EX forwarding used.\n";}
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
      displayTxt+="\nBranch predictor used for instruction ${de_ex[0]/4} ";
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
  void memory() {
    //pipelined// 
    if(knob1==true){
      t4[0]=ex_ma[0];t4[1]=ex_ma[1];t4[3]=ex_ma[6];t4[4]=ex_ma[7];
      int Eaddress = ex_ma[2] - (ex_ma[2] % 4);
      int index = ex_ma[2] % 4;
      for (int i = 0; i < 32; i++) {
      t[i] = 0;
    }
    displayTxt += "MEMORY: ";
    if(!(if_de[0]==0 && if_de[1]==19)){displayTxt += "Instruction number ${ex_ma[0]/4}, ";}
    if (ex_ma[4] == 0) {
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
    if(src2Hazard(ma_wb[1], ex_ma[1]) && knob2==true)displayTxt+="\nHazard detected between instructions number ${ex_ma[0]/4}(Memory) and ${ma_wb[0]/4}(Writeback) and WB-MA forwarding used.\n";
  }
  void write_back(File f) {
        displayTxt += "WRITEBACK: ";
        if(!(if_de[0]==0 && if_de[1]==19)){displayTxt += "Instruction number ${ma_wb[0]/4}, ";}
        if( ma_wb[3]==1  &&   ((ma_wb[1]>>7)&0x1F)!=0 ){
          displayTxt += "Write to x${(ma_wb[1]>>7)&0x1F}.\n ";
          RF[(ma_wb[1]>>7)&0x1F]=ma_wb[2];
        }else{
          displayTxt += "No writeback.";
        }
        if(ma_wb[0]==0 && ma_wb[1]==19){displayTxt+="NOP/BUBBLE instruction.\n";}
        displayTxt+="\n";
        if(ma_wb[1]==1 ){swi_exit(f);}
        //stats
        if(!((ma_wb[1]==19 && ma_wb[3]==0) || ma_wb[1]==0)){instructCount++;}
        if(ma_wb[1]&0x7F==35 || ma_wb[1]&0x7F==3){dataCount++;}
        if(ma_wb[1]&0x7F==99 || ma_wb[1]&0x7F == 111 || ma_wb[1]&0x7F==103){controlCount++;}
        if(ma_wb[1]&0x7F==99){controlHazard++;}
  }
  void transfer()
  {
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
                 if(check==true)displayTxt+="\nBranch predictor used for instruction ${progControl/4} and branch taken.\n";
                 else displayTxt+="\nBranch predictor used for instruction ${progControl/4} and branch not taken.\n";
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
          if(hazardDetect(de_ex[1])==true)displayTxt+="\nHazard detected between instructions number ${if_de[0]/4}(Decode) and ${de_ex[0]/4}(Execute).\n";
          else if(hazardDetect(ex_ma[1])==true)displayTxt+="\nHazard detected between instructions number ${if_de[0]/4}(Decode) and ${ex_ma[0]/4}(Memory).\n";
          else if(hazardDetect(ma_wb[1])==true)displayTxt+="\nHazard detected between instructions number ${if_de[0]/4}(Decode) and ${ma_wb[0]/4}(Writeback).\n";
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
  void swi_exit(File f) {
    write_datamemory(f);
    running = false;
  }
  void write_datamemory(File myOutFile) {
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
  bool src1Hazard(int write,int read){
    int opcode1=write&0x7F,opcode2=read&0x7F;
    if(opcode1==35 || opcode1==99 || opcode1==0 || write==19){return false;}
    if(opcode2==111 || opcode2==55 || opcode2==23 || read==19){return false;}
    int src1=(read>>15)&0x1F,dest=(write>>7)&0x1F;
    if((src1!=0) && (src1 == dest)){return true;}
    return false;
  }
  bool src2Hazard(int write,int read){
    bool hasrs2=false;
    int opcode1=write&0x7F,opcode2=read&0x7F;
    if(opcode1==35 || opcode1==99 || opcode1==0 || write==19){return false;}
    if(opcode2==111 || opcode2==55 || opcode2==23 || read==19){return false;}
    int src2=(read>>20)&0x1F,dest=(write>>7)&0x1F;
    if(opcode2==51 || opcode2==35 || opcode2==99){hasrs2=true;}
    if(hasrs2==true &&(src2!=0) && (src2 == dest)){return true;}
    return false;
  }
  bool hazardDetect(int instruction){
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
  void run_riscvsim(File f){
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
      print(RF);
      count++;
      transfer();
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
      if(address>=0x10000000)
      MEM[address]=instruct;
      else
      INS[address]=instruct;
    }
  }

void main() {
  var path='test.txt';
  var file= new File(path);
  var outFile=new File('out.txt');
  List<String> s=file.readAsLinesSync();
  for(int i=0;i<s.length;i++)
  {n.add(s[i]);}
  RF[2]=2147483644;
  buffer.add(new BTB(-1,-1,false));
  load_progmem();
  run_riscvsim(outFile);
}