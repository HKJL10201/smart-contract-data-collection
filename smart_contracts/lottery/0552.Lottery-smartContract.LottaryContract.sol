pragma solidity 0.6.12;

// Making players to Invest money in the contract.
// Displaying current balance in the contract.
// owner clicks a function then it should do,
    // select a player in random and send total money in the contract to a selected player account.

contract Lottery{
    
    address public owner;
    address payable[] public players;
    
    // creating constructor- to set or create a owner
    constructor () public{
        owner = msg.sender; // making contract deployer as a owner.
    }
    
    // event to the frontend
    event playerInvested(address player, uint amount);
    event winnerSelected(address winner, uint amount);
    
    // creating function invest - to make player to invest into the contract
    function invest() payable public{
        // owner must not invest
        require(msg.sender != owner,"Owner cannot invest.");
        
        // players must invest astleast 1 ether
        require(msg.value >= 1 ether,"Invest minimum of 1 ether.");
    
        // players must invest astleast 1 ether
        for (uint i = 0; i<players.length; i++){
            require(msg.sender != players[i],"Player can invest only one time.");
        }
        
        // pushing the invested players into players list
        players.push(msg.sender); // for maintaining(adding) players list- who invest in the contract
        
        emit playerInvested(msg.sender, msg.value);
    }
    
    // creating function getBalance -  to display the current balance in the contract 
    function getBalance() public view returns(uint){
        // only owner can able to see balance
        require(msg.sender == owner, "Only owner can able to see the balance.");
        return address(this).balance;
    }
    
    
    // creating function genRandom - to generate pseudo random number
    function genRandom() private view returns(uint){
        // pseudo random number(not to be used in production) - select a random number
        // for production use ORACLES to find a random number.
        // random number - global variables, encode it, hash it, convert to uint
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, players.length)));
    }
        
    // creating function selectWinner - to select a random player when owner clicks this function.
    function selectWinner() public{
        // only owner can able to select the winner
        require(msg.sender == owner, "Only owner can able to select the winner.");
        // calling random().
        uint random = genRandom();
        
        //modulo it with tge number of players in the contract
        uint index = random % players.length;
        
        // map the remainder of the modulo to the index of players in the contract
        address payable winner = players[index];
        emit winnerSelected(winner, address(this).balance);
         
        // transfer all the money in the contract to the address of selected players
        winner.transfer(address(this).balance);

        // finally make the player list empty
        players = new address payable[](0);
    }
    
}
