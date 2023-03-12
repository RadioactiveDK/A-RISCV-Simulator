# Design Document: Functional Simulator for RISCV-32I ISA 
The document describes the design aspect of riscvSIM, a functional simulator for subset of RISCV-32I instruction set implemented using Dart programming language. 

## Input/Output: 

### Input 

Input to the simulator is MEM file that contains the encoded instruction and the corresponding address at which instruction is supposed to be stored, separated by    space. In addition to that, it also contains some information about data that is stored int the data section, which starts at address 0x10000000.  For example: 

Instruction segment looks like below: 
```
0x0 0x00400393
0x4 0x00C00493 
0x8 0x00938533 
0xC 0xEF000011 
```

The data section looks like: 
```
0x10000000 0x000F13C2 
0x10000004 0x1EAAA320 
```

### Functional Behavior and output 

The simulator reads the instruction from instruction memory, then performs decode, execute, memory operation and writeback. There are a total of 26 instructions supported by this simulator as mentioned in the document. 

The execution of instruction continues till it reaches instruction “swi 0x11” or next address in instruction memory has no data. In other words, as soon as the instruction reads “0xEF000011” or if no instruction is present at the next instruction address, simulator stops and writes the updated memory contents on to a memory text file.  

Along with the execution of instructions, the simulator also prints messages describing what actions it is performing in each stage, with the help of update in the structures that change in that stage. For example, for the third instruction above the following messages are printed. 

Fetch prints:
```
FETCH: Fetch instruction 0x00938533 from address 0x8
```

Decode prints:
```
DECODE: Operation is ADD, first source register x7, second source register x9, destination register is x10
DECODE:  Read registers x7 = 4, x9 = 12
```

Execute prints:
```
EXECUTE: ADD 4 and 12
```

Memory prints:
```
MEMORY: No memory operation
```

Writeback prints:
```
WRITEBACK: write 16 to x10
```

## Design of Simulator 
### Data structure
Registers, memories, intermediate output for each stage of instruction execution are declared globally so that these are accessible to all functions as dart language does not support argument passing by reference to functions. Registers use “list<int>” data structure provided by dart language. Register x2 is initialised with stack pointer 0x7FFFFFFC. Memory is implemented using "Map<int ,int>" data structure, keys represent addresses in memory and values correspond to the data stored at those addresses. Other intermediates like control, operand values, aluresult etc. are implemented with help of global int and boolean variables. 


### Simulator flow
There are two steps:
- First memory is loaded with input memory file by the load_progmem function 
- Simulator executes instructions one by one. 

In first step load_progmem function reads input file line by line and then converts hex string into decimal value of address and corresponding data and stores them in map. 

For the second step, there is infinite loop, which simulates all the instruction till the instruction sequence reads “SWI 0x11” or next instruction address has “0x00000000” as the value. On reading these two, fetch calls swi_exit function which stops the instruction loop and then calls write_datamemory function to stores the content of updated memory into an output memory file. 

## Implementations of functions
1. **FETCH**:  This function uses the pc updated by previous write_back and then gets the machine code in form of integer from MEMORY map, of the instruction present there and then obtains the binary form of machine code using dec2bin function which will then be used to decode the instuction in DECODE stage.
2. **DECODE**:  First it calculates values of opcode, fucnt3, funct7, source register rs1, source register rs2, and destination register rd. Next immediate is calculated based on the type of instruction with proper sign extension.Next, control path such as Rfwrite, resultselect, op2select, aluoperation are computed based on the value of opcode, funct3, and funct7 computed earlier. Then, values of operand1 and operand2 read from both source registers are obtained for execute stage. 
3. **EXECUTE**:  Firstly, based on the value of op2select, which acts like a mux, the second input to the ALU unit is selected. Next, according to the value of aluop computed in decode stage aluresult is selected form eight different options. Specifically, addition, subtraction, AND, OR, XOR, shift left logical, shift right logical, shift right arithmetic. Case of overflow is also taken care of. To implement logical right shift, simulator uses dec2bin and comp2 function, as the predefined right shift in dart language is arithmetic in nature. Along with computation of aluresult, branch target is also calculated in parallel in case of jal or B type instructions. Also, if instruction was B-type then the value of IsBranch is obtained on the basis of aluresult, which tells if branchtarget will be chosen in write_back stage. 
4. **MEMORY**:  In this simulator, the memory map has addresses as multiple of 4. So, to make it byte addressible the appropriate index ranging from 0 to 3 is obtained which tells the exact address. For example if Eaddress is 0x8 and index is 3, this means we want to access address 0x11 .  Now, if Memop is false then we just read from memory. Else, we write to the memory. To support storing and loading of bytes and short_word, bitmasks of 0xFF and 0xFFFF are used to extract correct bits from the 32 bits stored at the Eaddress. Then, the value is calculated using comp2 function which calculates value from the 2’s complement representation of a number. For storing sw, sh and sb functions are used for word, short, and byte respectively which update the memory map. Similarly, lw, lh and lb are used to read data into loadData variable. 
5. **WRITE_BACK**:  In this stage, the result that needs to be stored is selected by resultselect which acts like a mux and if the value of Rfwrite is true, then the result is stored at the destination register rd. If the value of isBranch is true the pc is updated to branchtarget, else it it is updated to pc+4; 

## Test plan
We test the simulator with following assembly programs:
1. Fibonacci Program 
2. Sum of the array of N elements. Initialize an array in the first loop with each element equal to its index. In the second loop find the sum of this array and store the result at Arr[N].    
3. Bubblesort program 
