//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Immutable{
 
    /*SOLIDITY DOC: State variables can be declared as constant or immutable. In both cases, 
    the variables cannot be modified after the contract has been constructed. 
    For constant variables, the value has to be fixed at compile-time, 
    while for immutable, it can still be assigned at construction time.*/

    uint immutable mynumber = 123;
    address immutable myaccount = msg.sender;
    bytes32 immutable mybytes = "hello";
    // string immutable mystring = "hello"; GIVES ERROR FOR STRING
    bool immutable mybool = true;

    uint constant mynumber1 = 123;
    // address constant myaccount1 = msg.sender; //GIVES ERROR because the value is not a compile time, it is a construction time value
    bytes32 constant mybytes1 = "hello";
    string constant mystring1 = "hello";
    bool constant mybool1 = true;
}

contract B{
    /*Immutable variables use less gas than regular state variables.
    So you can declare them as immutable when you can.
    Immutable variables can be initialized only once, when the contract is deployed.
    Compare to constant, immutable can also be declared in constructor */
    uint immutable mynumber;
    constructor(){
        mynumber = 222;
    }

    /* ERROR: cannot assign constant variable
    uint constant mynumber2; // ERROR: UNinitialized constant var. Constant variables must be initialized.
    constructor(){
        mynumber = 333;
    }
    */

}

contract C {
    uint constant X = 582;
    string constant TEXT = "abc";
    bytes32 constant MY_HASH = keccak256("abc");
    uint immutable decimals;
    uint immutable maxBalance;
    address immutable owner = msg.sender;

    constructor(uint _decimals, address _reference) {
        decimals = _decimals;
        // Assignments to immutables can even access the environment.
        maxBalance = _reference.balance;
    }

    function isBalanceTooHigh(address _other) public view returns (bool) {
        return _other.balance > maxBalance;
    }
}