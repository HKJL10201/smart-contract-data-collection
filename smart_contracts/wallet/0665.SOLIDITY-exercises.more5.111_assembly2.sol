//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Assembly {

    function assemblySize(address a) external view returns(string memory){
        uint size;
        address myAddress = a;//why i need this line?
        assembly {
           size := extcodesize(myAddress)
        }
        if(size == 0) {
            return "regular";
        } else {
            return "smart contract";
        }
        /*extcodesize() is used to tell us if an address is smart contract or a regular address.
        This is done by checking the "code" field of an address if it is empty or not. If empty("0"), then 
        this is regular address. If not empty, then it is smart contract address.
        This operation can only be done by using solidity assembly.
         */

    function bytes32Cast() external {
        bytes memory data1 = new bytes(10); // bytes(10) means 10*32
        bytes32 data2;
        assembly {
            data2 := mload(add(data1, 32))
        }
        /* converting bytes to bytes32 can only be done by using the assembly.
        Because the size of bytes32 is smaller than the size of bytes. So, when we use assembly,
        we are not converting whole bytes value, we are just converting the first 32 bytes of our bytes value.
        So, we will read the first 32 value of bytes into bytes32. */    
    }
}
