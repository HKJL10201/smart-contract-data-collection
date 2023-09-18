// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Lottery{
    //All the players which send ether and enter the lottery will be in this array and their address will stored 
    address payable[] public players; //One of these players will win the lottery and entire amount will transfered to the address so it necessary to be payable
    address public manager;

    constructor() {
        manager = msg.sender; //The person who deploys the contract will be appointed as the manager
    }

    //The user can enter the lottery simply by sending 0.1ether to the  contract and for that we need the receive or fallback function
    receive() external payable { //By using this function now the contract will be able to receive ether sent to it
         require(msg.value == 0.1 ether);
         require(msg.sender != manager);
         players.push(payable(msg.sender));

    }

    //This is to get the balance of the contract 
    function getBalance() public view returns(uint){
        require(msg.sender == manager); //This is make sure only the manager can see the balance of the contract
        return address(this).balance;
    }
    
    //Now to select a winner we are basically generating a random number and taking the remainder with divding the number of players and the number we obtain will be the index of the person who will win the lotter
    //IMPPP but generating truly random numbers is really difficult in solidity so DO NOT USE THIS WHERE REAL MONEY IS INVOVLVED
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }

    //The problem with the abhove solution of the random block is the miner can manupulate and choose not to publish a block until he wishes to do so,in smart contracts the reccomended way to implement random numbers is by using an oracle
    function pickWinner() public {
        require(msg.sender == manager);
        require(players.length >= 10);

        uint r = random();
        uint index = r % (players.length);
        address payable winner;

        winner = players[index];
        payable(manager).transfer(getBalance()/10);
        winner.transfer(getBalance());
        players = new address payable[](0); //This is reseting the lottery
    }

}
