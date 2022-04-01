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

    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public restricted { //restricted is a function modifier
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0); //Dynamic and initiate with length of 0.
        // If you put (5) => [0x0000,0x0000,0x0000,0x0000,0x0000]
        // Dynamic because [] is empty. Not fixed tab.
    }

    modifier restricted() { //Exist to avoid code duplication
        require(msg.sender == manager);
        _; // _ represent all the code which is within the pickWinner method.
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}