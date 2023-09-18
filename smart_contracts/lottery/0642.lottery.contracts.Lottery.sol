pragma solidity 0.7.0;

/* 
    we can compile this smart contract to its bytecode and abi by running the
    following commands at the base directory:

    $ solcjs ./contracts/Inbox.sol --bin
    $ solcjs ./contracts/Inbox.sol --abi

    this will create text files within our directory which will need to be copied into
    contractArtifacts.js
*/

contract Lottery {
    address public manager;
    
    // array of players who are allowed by the contract to reveive funds
    address payable [] public players;
    
    // assigns the role of manager to whoever deploys the contract to the network
    constructor() {
        manager = msg.sender;
    }
    
    // allows function calls to be restricted to the manager
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function length() public view returns(uint) {
        return players.length;
    }
    
    function enter() public payable {
        require(msg.value > .005 ether);
        
        require(msg.sender != manager);
        
        players.push(msg.sender);
    }
    
    function rand() private view returns(uint256) {
        // create pseudorandom unsigned integer from 1-1000
        // https://stackoverflow.com/questions/58188832/solidity-generate-unpredictable-random-number-that-does-not-depend-on-input
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
        seed = (seed - ((seed / 1000) * 1000)) + 1;
    
        // create pseudorandom unsigned integer
        uint random = uint(keccak256(abi.encodePacked(block.coinbase)));
        
        return random / seed;
    }
    
    function pickWinner() public restricted {
        // need more than two lottery entries to call this function
        require(length() > 1);
        
        // generates an index based on the remainder of a pseudorandom
        // number and the number of players in the lottery
        uint index = rand() % players.length;
        
        // picks the winner and assigns to variable
        address payable x = players[index];
        
        // pays the winner the balance of the contract
        x.transfer(address(this).balance);
        
        // resets the contract's state
        players = new address payable [](0);
    }
    
    function getPlayers() public view returns (address payable [] memory) {
        return players;
    }
}