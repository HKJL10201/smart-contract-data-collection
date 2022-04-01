pragma solidity ^0.4.20;


contract Lottery {
    address public manager;
    address[] public players;

    function Lottery() public {
        manager = msg.sender;   // msg.sender address of caller
    }

    function enter() public payable {
        require(msg.value > .01 ether); // the amount of value the caller sent!
        players.push(msg.sender);
    }

    function pickWinner() public owner {
        address winner = players[random() % players.length];
        players = new address[](0); // reset players
        winner.transfer(address(this).balance); // transfer all values from contract account
    }

    function contractBalance() public view owner returns (uint256) {
        return address(this).balance;
    }

    // Creates a custom modifier for function
    modifier owner {
        require(msg.sender == manager); // First statement of function
        _;  // All other statements
    }

    function random() public view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }

}
