// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 < 0.9.0;

contract Lottery{
    address manager;
    address payable[] public players;
    address payable public winner;

    // The project deployer will become the manager which controls the Lottery System
    constructor(){
        manager = msg.sender; // Global Variable
    }

    // Whenever we will recieve the Payment from a person
    // We will register the person as participant 
    receive() external payable {
        // It indicates that the person must have send atleast 2 ether
        // to be a Participant 
        require(msg.value ==  1 ether , "Please pay 0.1 ether only");
        players.push(payable(msg.sender));
    }

    function allPlayers() public view returns(address payable[] memory){
        return players;
    }

    // Returns the Total Balance of the Lottery
    function getBalance() public view returns(uint){
        
        // Only manager will be able to see the Balance
        require(msg.sender ==  manager , "You are not the manager");
        return address(this).balance;
    }

    // Selection of Lottery Winner
    function pickWinner() public {

        require(msg.sender == manager , "You are not the manager");
        require(players.length >= 3 , "Players are less than 3");

        uint random = uint(keccak256(abi.encodePacked(block.difficulty , block.timestamp , players.length)));
        uint index = (random % players.length);
        winner = players[index];
        winner.transfer(getBalance());
        players = new address payable[](0);
    }
}

// > transaction hash:    0xac770b21844b203bcfee2286b858259e2348d96081a3e42fb3c7a3256585ef26
//    > Blocks: 2            Seconds: 5
//    > contract address:    0xE4b0b53FF1914c4C710E283994f936Ed01585dA8
//    > block number:        37839004
//    > block timestamp:     1689142538
//    > account:             0xCEA4dE3283ee73EFc5446Da0516f9f01dB6dD34c
//    > balance:             6.187092302417848305     
//    > gas used:            679828 (0xa5f94)
//    > gas price:           2.500000017 gwei
//    > value sent:          0 ETH
//    > total cost:          0.001699570011557076 ETH


// ganache 0x7E10f651880c6ACb3Db5870081A1121069b0054E