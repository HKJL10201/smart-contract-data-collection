//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EcommerceWallet {
    address public owner;
    uint256 public balance;
  mapping(string => uint256) public inventory;
      
constructor() {
    owner = msg.sender;
    balance = 10000;

    // Initialize the inventory
    inventory["item1"] = 10; // Set the initial quantity of item1
    inventory["item2"] = 5;  // Set the initial quantity of item2
    // Add more items to the inventory if needed
}
function purchase(string memory item, uint256 quantity) public payable {
    require(quantity > 0, "Invalid quantity");
    require(msg.value >= quantity * priceOf(item), "Insufficient payment");
    require(inventory[item] >= quantity, "Item out of stock");

    uint256 totalCost = quantity * priceOf(item);

    // Transfer the payment to the contract owner
    payable(owner).transfer(totalCost);

    // Update the balance and inventory
    balance += totalCost;
    inventory[item] -= quantity;
}
function priceOf(string memory item) public pure returns (uint256) {
    if (keccak256(bytes(item)) == keccak256(bytes("item1"))) {
        return 100; // Set the price of item1
    } else if (keccak256(bytes(item)) == keccak256(bytes("item2"))) {
        return 200; // Set the price of item2
    }
    // Add more items and their respective prices if needed
    return 0; // Return 0 for items not in the inventory

    }

    function deposit() public payable {   // Deposit funds into the wallet
        balance += msg.value;
    
    }



    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
