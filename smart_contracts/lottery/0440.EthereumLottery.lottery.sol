pragma solidity >=0.4.22 <0.6.0;

contract Lottery {
    
    address payable[] public players;
    
    address public owner;
    
    constructor() public {
        // save the owner
        owner = msg.sender;
    }
    
    function() external payable {
        require(msg.value > 0);
        players.push(msg.sender);
        
        if(players.length == 4) {
            payWinner();
            players = new address payable [](0);
        }
    }
    
    function getRandom() private view returns(uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, players.length)
            )
        );
    }
    
    function payWinner() private {
        uint256 randomNumber = getRandom();
        uint index = randomNumber % players.length;
        address payable winner = players[index];
        
        winner.transfer(address(this).balance);
    }
    
}
