// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AddressCheck {

    function checkAddress(address _addr) external view returns(string memory){
        uint length;
        assembly {
            length := extcodesize(_addr)
        }

        if(length > 0) {
            return "This is a Smart Contract Address";
        } else {
            return "This is an Account Address (EOA)";
        }
    }
    modifier onlyEOA1() {
        uint length;
        address myAddress = msg.sender;
        assembly {
            length := extcodesize(myAddress)
        }
        require(length == 0, "this is a smart contract");
        _;    
    }

    modifier onlyEOA2() {
        require(msg.sender == tx.origin, "this is a smart contract");
        _;
    }

    function something() external onlyEOA1 onlyEOA2 view returns(string memory) {
        return "you are an EOA";
    }

}