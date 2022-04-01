pragma solidity ^0.4.20; contract Lottery {
    
    address owner;
    uint deadlineToEnter;
    uint deadlineToClaim;
    uint minimumBet;
    uint pool;
    uint winningNumber;
    address[] winners;
    mapping(address => bytes32) players;
    
    function Lottery (uint daysTillEnd, uint daysToClaim, uint minimumEther) public {
        owner = msg.sender;
        deadlineToEnter = block.timestamp + (daysTillEnd * 1 days);
        deadlineToClaim = block.timestamp + (daysToClaim * 1 days);
        minimumBet = minimumEther;
    }
    
    function play(bytes32 hash) external payable {
        require(msg.value >= minimumBet * 1 ether);
        require(msg.sender != owner);
        require(hash != 0);
        // require(now <= deadlineToEnter);
        require(players[msg.sender] == 0);
        
        players[msg.sender] = hash;
        pool = pool + msg.value;
    }
    
    function winning(uint256 _winningNumber) external {
        require(msg.sender == owner);
        // require(now >= deadlineToEnter && now <= deadlineToClaim);
        
        winningNumber = _winningNumber;
    }
    function reveal (uint256 claim) external {
        // require(now <= deadlineToClaim);
        require(msg.sender != owner);
        
        
        bytes32 hashedClaim = sha256(winningNumber, claim);
        require(players[msg.sender] == hashedClaim);
        addPlayer (msg.sender);
    }
    
    function addPlayer(address claimAddress) internal {
        for(uint i = 0; i < winners.length; i++){
            require(winners[i] != claimAddress);
        }
        winners.push(claimAddress);
    }
    
    function done () external {
        require(msg.sender == owner);
        uint amountToSend = pool / winners.length;
        
        for(uint i = 0; i < winners.length; i++){
            winners[i].transfer(amountToSend);
        }
        selfdestruct(owner);
    }
  
    function getPool () public constant returns (uint) {
        return pool;
    }
    
    function getWinningNumber () public constant returns (uint) {
        return winningNumber;
    }
}
