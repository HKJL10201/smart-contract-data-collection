pragma solidity ^0.4.17;


contract Lottery {
    // variables storage // will be forever stored on the etherum blockchain
    // using public or private does inssure the security of the data inside my Contract
    address public manager;
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        
        players.push(msg.sender);
    }
    
    // to get a hash and convert it to random number using uint function
    // Now => currentTime
    function random() private view returns(uint){
       return uint(keccak256(block.difficulty, now, players));
    }
    
    // Pick Winner function
    function pickWinner()  public restricted {
        // we use require so only the manager can call the function( to inforce security)
        //  require(msg.sender == manager);
        // to get a random players
        uint index = random() % players.length;
        // transfer the balance to winner
        players[index].transfer(this.balance);
        // Empty players arrays
        players = new address[](0);
    }
    
    // modifier keywords allows us to not repeat the same code
    modifier restricted()  {
        require(msg.sender == manager);
        _;
    }

    // to get the list of all the players
    function getPlayers() public view returns(address[]) {
        return players;
    }
    

}