pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;

library StringHelper {
    function toString(bytes32 x) public constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    function toStringArray(bytes32[] x) public constant returns (string[]) {
        string[] memory data;
        for (uint i=0; i<x.length; i++) {
            data[i] = toString(x[i]);
        }
        return data;
    }
    
    function toBytes32(string memory source) public constant returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
}