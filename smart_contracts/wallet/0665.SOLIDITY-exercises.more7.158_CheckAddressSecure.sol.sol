//SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

contract OnlyForEOA { 

    uint public flag;

    // bad
    modifier isNotContract(address _a){
        uint length;
        assembly { 
            length := extcodesize(_a) 
        }
        require(length == 0);
        _;
    }

    modifier onlyEOA2() {
        require(msg.sender == tx.origin, "this is a smart contract");
        _;
    }
    //if we do not use onlyEOA2, then FakeEOA will pass isNotContract security check and flag will have value 1
    function setFlag(uint i) public isNotContract(msg.sender) onlyEOA2 {
        flag = i;
    }
}

contract FakeEOA {
    //During construction phase, contract address does not have a function length inside, even if you have 
    //millions of variable and functions here like "word". 
    string internal word = "Some random values, has no effect on the constructor";
    constructor(address _a) {
        OnlyForEOA c = OnlyForEOA(_a);
        c.setFlag(1);
    }
}