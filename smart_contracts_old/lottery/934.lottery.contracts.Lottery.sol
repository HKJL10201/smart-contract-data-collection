pragma solidity 0.4.17;

contract Lottery {

    address public manager;
    address[] public players;

    function Lottery() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value == 0.01 ether);

        players.push(msg.sender);
    }

    function getPlayers() public view returns(address[]) {
        return players;
    }

    function pickWinner() public required {
        uint randomValue = getRandom();
        uint playersCount = players.length ;
        uint playerIndex = randomValue % playersCount;
        address selectedPlayer = players[playerIndex];
        selectedPlayer.transfer(this.balance);
        players = new address[](0);
    }

    function getRandom() public view returns(uint) {
        uint randomValue = uint(keccak256(block.difficulty, now, players));
        return randomValue;
    }

    modifier required() {
        require(msg.sender == manager);
        _;
    }

}