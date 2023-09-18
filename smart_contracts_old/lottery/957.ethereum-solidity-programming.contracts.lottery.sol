/SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

contract Lottery{
    // declaring the state variables
    address payable[] public players;
    address public manager;
    
    constructor(){
        manager = msg.sender;
        players.push(payable(manager));
    }
    
    receive() payable external{
        //payble in order to transfer money, external because it s more efficient than public,
        //and only the players or other SM should use this function
        require(msg.value == 0.1 ether);
        require(msg.sender != manager, "The manager cannot participate");
        players.push(payable(msg.sender)); // convert player address to a payable one
    }
    
    function getBalance() private view returns(uint){ // balance in wei
        
        return address(this).balance;
    }
    
    function getBalanceManager() public view returns(uint){ // balance in wei
        require(msg.sender == manager);
        return getBalance();
    }
    
    function random() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    function pickWinner() public{
        require(players.length >= 2); // opt+maj+l -> |
        
        uint r = random();
        address payable winner;
        
        uint index = r % players.length;
        winner = players[index];
        
        
        payable(manager).transfer(uint(getBalance()/10)); // manager get 10% for him ?!
        winner.transfer(getBalance());
        
        players = new address payable[](0);
    }
}
