// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


// contract Owner {
//     address owner;

//     constructor(){
//         owner = msg.sender;
//     }

//     modifier onlyOwner() {
//         require(msg.sender == owner, "You are not allowed");
//         _;
//     }
// }

import "./Ownable.sol";

contract InheritanceModifierExample is Owner { // The is keyword is used to take all the functionality from Owner contract.
    mapping (address => uint) public tokenBalance;

    // address owner;

    uint tokenPrice = 1 ether;

    constructor(){
        // owner = msg.sender;
        tokenBalance[msg.sender] = 100;
    }

    // modifier onlyOwner() {
    //     require(msg.sender == owner, "You are not allowed");
    //     _;
    // }

    function createNewToken() public onlyOwner { // Write the onlyOwner here in order to import it here for usage.
        // require(msg.sender == owner, "You are not allowed"); After writing the modifier there is no need to write this statement.
        tokenBalance[owner]++;
    }

    function burnToken() public onlyOwner { // Write the onlyOwner here in order to import it here for usage.
        // require(msg.sender == owner, "You are not allowed."); After writing the modifier there is no need to write this statement.
        tokenBalance[owner]--;
    }

    function purchaseToken() public payable {
        require((tokenBalance[owner] * tokenPrice) / msg.value > 0, "not enough tokens.");
        tokenBalance[owner] -= msg.value / tokenPrice;
        tokenBalance[msg.sender] += msg.value / tokenPrice;
    }

    function sendToken(address _to, uint _amount) public {
        require(tokenBalance[msg.sender] >= _amount, "Not enough tokens");
        tokenBalance[msg.sender] -= _amount;
        tokenBalance[_to] += _amount;
    }

}