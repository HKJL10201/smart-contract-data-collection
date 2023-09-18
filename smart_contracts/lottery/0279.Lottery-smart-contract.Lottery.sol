//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address payable[] public players;
    address public admin;
    
    constructor() {
        admin = msg.sender;
    }
    
    modifier onlyOwner() {
        require(admin == msg.sender, "You are not the owner");
        _;
    }
    
    function deposit() payable public {
        address payable participants;
        require(msg.value == 10 ether , "Must send 0.1 ether amount");
        require(msg.sender != admin);
        if(msg.sender != admin) {
            participants = payable(msg.sender);
            players.push(address(uint160(msg.sender)));
        }
    }
    function getBalance() public view onlyOwner returns(uint){
        return address(this).balance;
    }
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    function pickWinner() public onlyOwner returns (address) {
        require(players.length >= 3 , "Not enough players in the lottery");
        
        address payable winner;
        winner = players[random() % players.length];
        
        winner.transfer( (getBalance() * 80) / 100);
        payable(admin).transfer(getBalance());
        resetLottery(); 
        return winner;
    }
    
    function resetLottery() internal {
        players = new address payable[](0);
    }

}

