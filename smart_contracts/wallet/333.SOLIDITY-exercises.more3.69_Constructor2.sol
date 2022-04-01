//SPDX-Licence-Identifier: GPL-3.0;

pragma solidity >=0.8.7;

contract ConstructorTest {
    uint public myNumber;
    address public myAddress;

    //Constructors are used to initiate state variables.
    //Constructors are executed only once when the contract is deployed.
    constructor(uint _n) {
        myAddress = msg.sender;
        myNumber = _n;
    }

    //Here how you return multiple values.
    function getValues() external view returns(address, uint) {
        return (myAddress, myNumber);
    }
}