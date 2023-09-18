pragma solidity ^0.4.17;

contract Lottery{
    address public manager;
    address[] public players;

    constructor() public{
        manager = msg.sender;
    }

    function enter() public payable{
        require(msg.value > .01 ether);

        players.push(msg.sender);
    }

    function random() private view returns (uint){
        return uint(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public restricted {
        address winner = players[random() % players.length];

        // In-built transfer function to send all money
        // from lottery contract to the player
        winner.transfer(address(this).balance);
        players = new address[](0);
    }

    modifier restricted() {
        // Ensure the participant awarding the ether is the manager
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns(address[]) {
        // Return list of players
        return players;
    }
}
