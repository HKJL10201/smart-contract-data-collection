pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    function Lottery() public {
        // msg is a global variable in solidity to access the information of the transaction 
        // The sender address to create this contract (transaction)
        manager = msg.sender;
    }

    function enter() public payable {
        // Sender call this enter function require to pay .01 ETH 
        require(msg.value > .01 ether);

        // The sender address to call this payable function (transaction)
        players.push(msg.sender);
    }

    // Private helper function to generate a random number
    function random() private view returns (uint) {
        // keccak256() is a global function to hash values
        // block is global variable and difficulty is the BLOCK TIME
        // hashed value convert to uint
        return uint(keccak256(block.difficulty, now, players));
    }

    // below function used custom function modifier "restricted"
    function pickWinner() public restricted {
        uint index = random() % players.length;
        // palyers[index] return a player address, then each address has a transfer function to transfer
        // this.balance (this contract balance)
        players[index].transfer(this.balance);
        // Reset player (address array)
        players = new address[](0);
     }

    // custom function modifier which is similar to django decorator
    modifier restricted() {
        // Only the address/person who originally create this contract
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}