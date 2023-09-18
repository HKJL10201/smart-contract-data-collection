// Sample contract to run cross contract execution, ie. call a contract from another one.

pragma solidity ^0.5.0;

contract Base {
    uint x;
    constructor() public {
        x = 10;
    }
    
    function setX(uint _x) public returns(bool){
        x = _x;
        return true;
    }
    
    function getX() public view returns(uint) {
        return x;
    }
}

contract Caller {
    function getBaseX(address baseAddress) public view returns(uint){
        Base baseContract = Base(baseAddress);
        return baseContract.getX();
    }
}
