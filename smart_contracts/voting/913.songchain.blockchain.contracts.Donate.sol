
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";


contract Donate {
    address public owner;
    mapping(address => uint) balances;

    modifier onlyOwner() { 
        require(msg.sender == owner, "Not owner");
        _;
    }

    function donate() public payable {
        if (msg.value < 1) {
            console.log("Donation amount is too low");
            return;
        }
        balances[owner] += msg.value;
    }


    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney(address payable _to) public onlyOwner {
        _to.transfer(getBalance());
    }
}

// contract Donate {

//     address public owner;

//     struct Contributors {
//         uint id;
//         string name;
//         uint256 amount;
//         address sender_address;
//     }

//     constructor() {
//         owner = msg.sender;
//     }
    
//     modifier onlyOwner() { 
//         require(msg.sender == owner, "Not owner");
//         _;
//     }

//     uint256 id = 0;
//     mapping(uint => Contributors) public contributor;

//     function donate(string memory name) public payable {
//         console.log("Making donation!");
//         console.log("Name", name);
//         console.log("Amount", 3);
        

//         id += 1;
//         contributor[id] = Contributors(id, name, 3, msg.sender);
//     }

//     function getBalance() public view returns(uint) {
//         return address(this).balance;
//     }

//     function withdrawMoney(address payable _to) public onlyOwner {
//         _to.transfer(getBalance());
//     }

// }