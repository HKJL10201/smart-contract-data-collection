 // SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Lottery
 * @dev Lottery Dapp
 */
contract Lottery {
    address payable[] public players;
    address public manager;
    
    constructor(){
        //add adiministrative Privilages for the contract
        manager = msg.sender;
    }
    
    receive() external payable{
        //receive the Eth from the players
        require(msg.value == 0.1 ether,"SEND 0.1 ETH");
        players.push(payable(msg.sender));
    }
    //Get the Balance of the Dapp
    function getBalance() public view returns(uint){
        require(msg.sender == manager, "NOT Accessable to players");
        return address(this).balance;
    }
    //Random number generator
    //note: donot use for production
    function random()public view returns(uint){
      return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }
    
    //get the Random lottery winner and transfer Funds
    function Pickwinner() public{
        require(msg.sender == manager);
        require(players.length >= 3);
        uint rand = random();
        address payable winner;
        
        uint i = rand % players.length;
        winner = players[i];
        winner.transfer(getBalance());
        // reset the lottery
        players = new address payable[](0);
        }
}