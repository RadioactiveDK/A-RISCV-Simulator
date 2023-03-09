import "dart:io";

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
bool Rfwrite = false, Memop = false, op2select = false, isBranch = false;
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
    value = value >> 1;
    i++;
  }
}

int comp2() {
  int c = t[31];
  if (c == 1) {
    for (int i = 0; i <= 31; i++) {
      t[i] = 1 - t[i];
    }
    int i = 0;
    while (i <= 31 && t[i] == 1) {
      b[i] = 0;
      i++;
    }
    if (i <= 31) {
      t[i] = 1;
    }
  }
  int sum = 0;
  for (int i = 31; i >= 0; i--) {
    sum = (2 * sum) + b[i];
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
}

void decode() {
  dec2bin(mcode);

  for (int i = 6; i >= 0; i--) {
    type = (2 * type) + b[i];
  }
  for (int i = 14; i >= 12; i--) {
    funct3 = (2 * funct3) + 1;
  }
  for (int i = 31; i >= 25; i--) {
    funct7 = (2 * funct7 + 1);
  }
  for (int i = 19; i >= 15; i--) {
    rs1 = (2 * rs1 + 1);
  }
  for (int i = 24; i >= 20; i--) {
    rs2 = (2 * rs2 + 1);
  }
  for (int i = 11; i >= 7; i--) {
    rd = (2 * rd + 1);
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
    for (int i = 12; i <= 32; i++) {
      im[i] = im[11];
    }
    //control
    op2select = true;
    Rfwrite = true;
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
    for (int i = 21; i <= 32; i++) {
      im[i] = im[20];
    }
    //control

    Rfwrite = true;
  }
  //u type
  else if (type == 55 || type == 23) {
    for (int i = 12; i <= 31; i++) {
      im[i] = b[i];
    }
    //control
    Rfwrite = true;
    if (type == 55)
      resultselect = 4; //lui
    else
      resultselect = 3; //auipc
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
    for (int i = 13; i <= 32; i++) {
      im[i] = im[12];
    }
  }
  //s type
  {
    for (int i = 7; i <= 11; i++) {
      im[i - 7] = b[i];
    }
    for (int i = 25; i <= 30; i++) {
      im[i - 20] = b[i];
    }
    for (int i = 12; i <= 32; i++) {
      im[i] = im[11];
    }
    op2select = true;
    Memop = true;
  }
//resultselect
  if (type == 3) resultselect = 1; //load mode
  if (type == 111 || type == 103) resultselect = 2; //jal|jalr

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
  else if (type == 51) {
    if (funct3 == 1) aluop = 5; //sll
    if (funct3 == 5 && funct7 == 32)
      aluop = 7; //sra
    else
      aluop = 6; //srl
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
      }
      break;

    case 1:
      {
        aluresult = operand1 - temp;
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
        aluresult = operand1 << temp;
      }
      break;

    //list use for srl
    case 6:
      {
        dec2bin(operand1);
        int i = 0;
        for (; i <= 31 - temp; i++) {
          t[i] = t[i + temp];
        }
        while (i <= 31) {
          t[i] = 0;
        }
        aluresult = comp2();
      }
      break;

    case 7:
      {
        aluresult = operand1 >> temp;
      }
      break;
  }
  //branch
  branchtarget = pc + immediate;
  if (type == 111)
    isBranch = true;
  else if (type == 99) {
    if (funct3 == 0 && aluresult == 0) isBranch = true;
    if (funct3 == 1 && aluresult != 0) isBranch = true;
    if (funct3 == 4 && aluresult < 0) isBranch = true;
    if (funct3 == 5 && aluresult >= 0) isBranch = true;
  }
}

void memory() {
  int Eaddress = aluresult - (aluresult % 4);
  int index = aluresult % 4;
  for (int i = 0; i < 32; i++) {
    t[i] = 0;
  }
  if (Memop == 0) {
    if (MEM[Eaddress] != null) {
      if (funct3 == 0) {
        lb(Eaddress, index);
      } else if (funct3 == 1) {
        lh(Eaddress, index);
      } else {
        lw(Eaddress);
      }
    } else
      loadData = 0;
  } else {
    if (MEM[Eaddress] == null)
      MEM[Eaddress] = 0;
    else {
      if (funct3 == 0) {
        sb(Eaddress, index);
      } else if (funct3 == 1) {
        sh(Eaddress, index);
      } else {
        sw(Eaddress);
      }
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

    RF[rd] = word;
  }
  if (isBranch == true) {
    pc = branchtarget;
  } else
    pc = pc + 4;
}

void reset_proc() {
  aluresult = 0; immediate = 0; operand1 = 0;  operand2 = 0; loadData = 0;  aluop = 0;  branchtarget = 0;  resultselect = 0;  rs1 = 0;
  rs2 = 0;  rd = 0;  type = 0;  funct3 = 0;  funct7 = 0;  pc = 0;
  Rfwrite = false;   Memop = false;  op2select = false;  isBranch = false; 
  for (int i = 0; i <= 31; i++) {
    RF[i] = 0;  b[i] = 0;  im[i] = 0;  t[i] = 0;
  }
}

void swi_exit() {
  exit(0);
}

void main() {}
