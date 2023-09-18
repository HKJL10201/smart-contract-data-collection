// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.6 <0.9.0;

contract Candidates{
    function getBytes32ArrayForInput() pure public returns (bytes32[3] memory b32Arr) {
        b32Arr = [bytes32("ram"), bytes32("sham"), bytes32("raju")];
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
