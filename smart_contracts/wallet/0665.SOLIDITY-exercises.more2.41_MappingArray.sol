//SPDX-Licence-Identifier

pragma solidity >=0.8.7;

contract MappingArray{
    mapping(uint => uint[]) mappingArray;

    function createArray(uint _x, uint _a, uint _b, uint _c) external {
        uint[3] memory myArray = [_a, _b, _c];
        mappingArray[_x] = myArray;
    }

    function getElementMapping(uint _k) external view returns(uint[] memory) {
        return mappingArray[_k];
    }

    
}