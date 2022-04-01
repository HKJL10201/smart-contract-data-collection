pragma solidity ^0.4.17;

contract Lottery {
    
    address public manager;
    address[] public players;

    function Lottery() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }

    function getPlayersList() public view returns (address[]) {
        return players;
    }

    // create a pseudo randomness function -dont use for realz
    function random() private view returns (uint) {
        // these are global variables with solidity
        // the uint() converts to an integar
        return uint(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public {
        // ensures the manager is the one who can call this method
        require(msg.sender == manager);
        uint winnerIndex = random() % players.length;
        // sends all the money that the contract has to the address of the winner
        players[winnerIndex].transfer(this.balance);
        // reset the players list so we can reuse the contract
        players = new address[](0);
    }
}