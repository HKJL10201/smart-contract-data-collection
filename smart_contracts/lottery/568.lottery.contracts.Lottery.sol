//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.6.0 <= 0.9.0;

contract Lottery {
    
    address payable [] public players;
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "Owner required");
        _;
    }
    
    event theWinnerIs(address payable winner);
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    receive() external payable {
        require(msg.sender != owner, "Owner cannot partecipate");
        require(msg.value == 0.1 ether, "Value sent is not correct, you must send 0.1 ETH");
        players.push(payable(msg.sender));
    }
    
    function getRandomNumber() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    function payFee() internal {
        uint balance = getBalance();
        uint fee = (balance/100) * 10;
        payable(owner).transfer(fee);
    }
    
    function selectWinner() isOwner public {
        require(players.length >= 3, "Not enough players");
        uint r = getRandomNumber();
        
        uint index = r % players.length;
        
        address payable winner = players[index];
        
        payFee();
        
        winner.transfer(getBalance());
        
        emit theWinnerIs(winner);
        
        delete players;
    }
}