// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Lottery {
    address payable[] public players;
    address payable public manager;
    
    constructor() {
        manager = payable(msg.sender);
        // players.push(payable(manager));
    }
    
    receive() external payable {
        require(msg.value == 0.1 ether, "Ticket cost is 0.1 ETH");
        require(msg.sender != manager);
        players.push(payable(msg.sender));
    }
    
    function getBalance() public view returns(uint) {
        require(msg.sender == manager, "Unauthorized");
        return address(this).balance;
    }
    
    function generateRandom() private view returns(uint) {
        // To generate true random numbers use chainlink service
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    function endLottery() public {
        require(msg.sender == manager, "Unauthorized");
        require(players.length >= 3, "Insufficient players");
        
        address payable winner;
        uint r = generateRandom();
        
        uint winnerIndex = r % players.length;
        winner = players[winnerIndex];
        
        uint totalPrize = getBalance();
        manager.transfer(totalPrize / 10); // 10% reward
        winner.transfer((totalPrize / 10) * 9);
        
        players = new address payable[](0);
    }
}