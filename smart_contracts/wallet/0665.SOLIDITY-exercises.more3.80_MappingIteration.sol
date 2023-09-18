//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract MappingIteration {
    //Mappings are not iterable. You can use "length" method
    // nor you can use for loop on them.
    // To make iteration operations possible on maps, you will create a mapping
    // then another mapping to check if addresses are saved in the previous mapping.
    // then add each key to the array when you add them to the array.
    mapping(address=>uint) balances;
    mapping(address=>bool) inserted;
    address[] keys;

    // when you add keys-values to the mapping, then you can add keys to the 
    // other mapping and to the array as well.
    function addMapping(address _key, uint _val) external {
        balances[_key] = _val;
        if(!inserted[_key]){
            inserted[_key] = true;
            keys.push(_key);
        }
    }
    
    //get the length of mapping by getting the length of array.
    function getMappingLength() external view returns(uint){
        return keys.length;
    }
    // To get the value of any address, we can use the index number in array.
    function getMappingValues(uint index) external view returns(uint) {
        address targetAccount = keys[index];
        return balances[targetAccount];
    }

    //Another useful one: we can check the account value of last account in the mapping by using array.
    function getLastMapping() external view returns(uint) {
        address targetAccount = keys[keys.length-1];
        return balances[targetAccount];
    }


}
