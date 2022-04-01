pragma solidity ^0.4.23;

/* 
 If/when we start using engima, this will become a secret contract.

*/

contract UserAccount {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

}