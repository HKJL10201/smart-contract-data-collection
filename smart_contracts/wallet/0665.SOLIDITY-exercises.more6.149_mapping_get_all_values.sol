//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;


contract Cities {

    mapping(uint => string) public citiesMapping;
    
    function addValues(uint _index, string memory _name) external {
        citiesMapping[_index] = _name;
    }

    function getAllMapping(uint _begin, uint _end) external view returns(string[5] memory) {
        string[5] memory citiesArray;
        for(uint i = _begin; i<_end; i++) {
            citiesArray[i] = citiesMapping[i];
        }
        return citiesArray;
    }


}