//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

// Defining the state variables and the constructor
contract Lottery {
    address payable[] public players;
    address public manager;

    constructor(){
        manager = msg.sender;
    }

    // Entering the lottery
    receive() external payable {  // In order for the contract to receive ETH - Must be included in contract
        // Validation - The require statement
        require(msg.value == 0.2 ether, "You can only send 0.2 ETH!"); // We can assign a suffix for the unit we are using (ether)
        players.push(payable(msg.sender));  // Adding the player to the Players array
    }

    function getBalance() public view returns(uint){ // To access the balance of the contract
        // Only the manager of the contract can see the balance of the contract
        require(msg.sender == manager, "You are not authorized to view the balance of this contract!");
        return address(this).balance;
    }

    // Generate a random number in solidity in order to select the lottery winner
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    // Selecting the winner and sending contract balance
    function pickWinner() public {
        require(msg.sender == manager, "You are not authorized to select the winner!"); // Only contract owner can perform this
        require(players.length >= 5, "There are not enough entries to select a winner yet!"); // Must have at least 3 participants to select winner

        uint r = random(); // Calling the random() function to generate a random uint named `r`
        address payable winner; // The address that is selected and will receive all of the funds

        uint index = r % players.length; // This will result in a remainder that will be the index of the winning address
        winner = players[index]; // Assign the winning index value to the address
        
        // Transfer the contract balance to the selected winner
        winner.transfer(getBalance());
        players = new address payable[](0); // This resets the lottery and starts with an empty player[] array 
    }

}