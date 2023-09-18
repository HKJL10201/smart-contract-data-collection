//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Assembly {
    function addNumbers() external pure returns(uint){
        uint a = 1;
        uint b = 2;
        uint c;
        assembly {
            c:= add(a, b)
        }
        //Above, instead of saying "uint c = a+ b;", we used assembly
        return c;
    }

    function addNumbers2() external pure returns(uint){
        uint a = 1;
        uint c;
        assembly {
            let b := 5
            c:= add(a, b)
        }
        //Above, we used a memory variable inside assembly.
        return c;
    }
    
    function slotMemory() external pure returns(bytes memory) {
        bytes memory x;
        assembly {
            let a := mload(0x40) //mload loads a slot for your data. 0x40 finds the next free slot
            mstore(a, 1) //mstore puts the data(in this case a uint: 1) in the slot "a"
            sstore(a, 10) //this data will be persistent, saved in blockchain
            x := a //this is only for my sandbox, I want to see the slot. 
        }
        return x;
    }

}

/*assembly is a low l evel sub-language of solidity that let us to 
directly manipulate EVM opcodes.

Solidity is high level language and computers dont understand it. So, the code we write
is converted into bytecode by a compiler called "solc" so that EVM (which is an operating system
used to run smart contracts) will understand it. 

Solidity code that we write is compiled to a "low-level series of instructions" to be understood by the EVM. 
This low level series of instructions are called opcodes(operation codes).
Opcodes are also called elementary operations.

All opcodes have their hexadecimal counterparts: MSTORE - 0x52, SSTORE - 0x55

In total there are over 100 opcodes. When we use Assembly, we can directly manipulate these opcodes.
some opcodes: add(), mul(), sub(), div(), mload(), mstore()...

Assembly is used for cases when regular solidity is not enough to fix your
problem. So, actually it is not much used I guess.

Assembly manipulates memory and for this reason it is dangerous. So, better to avoid assembly
(Not sure if I understand this part. Whats wrong if it manipulates memory?)

assembly must be written inside solidity functions. 
assembly language can contain: let, if, functions, for loop
assembly language uses ":=" instead of "=",
assembly language does not contain semicolons ";"
"let" keyword helps to define local variables inside assembly code block

---MEMORY LAYOUT OF EVM---
in EVM everything is store in 256 bits slots.
slots are in bytes format (that's what i see from third function). 

simple data types such as uint, can be stored in a single slot.
For example, uint a = 5; --> here "a" is stored in a single slot.
On the other hand an array mapping can be stored on multiple slots.

Generally, assembly is used to target single slots. Generally it is used to 
manipulate uint related memory, thats why single slots.

mload() finds the data store in a specific memory slot
mstore() stores the data for this memory slot
sstore() store the data for this storage slot

*/