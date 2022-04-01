    pragma solidity ^0.4.17; 
    
    contract Lottery {
        address public manager;
        address[] public players;
        
        constructor() public{
            manager = msg.sender;
        }
        
        function enter() public payable {
            require(msg.value > 0.01 ether);
            players.push(msg.sender);
        }
        
        function pickWinner() public restricted {
            
            uint index = random() % players.length;
            players[index].transfer(this.balance);
            players = new address[](0);
        }
        
        function random() private view returns(uint) {
            return uint(keccak256(block.difficulty, now, players));
        }
        
        // Return all the players in the Lottery
        function getPlayers() public view returns(address[]){
            return players;
        }
        
        // We use this modifier for all manager functions
        modifier restricted() {
            // Check that the manager is the one who is calling the function
            require(msg.sender == manager);
            _;
        }
    
    }