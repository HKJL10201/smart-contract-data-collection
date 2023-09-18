pragma solidity >=0.6.0;

contract Lottery {
    address public manager;
    address[] public players;
    address public winner;

    constructor () {
        manager = msg.sender;
    }

    function enter() public payable {
        // require(msg.value > .01 ether);
        players.push(msg.sender);
    }

    function getPlayersLength() public view returns (uint) {
        return players.length;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function random() private view returns (uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }

    function pickWinner() public restricted {
        uint index = random() % players.length;
        winner = players[index];
        uint commission = address(this).balance * 1 / 10;
        uint winnerAmount = address(this).balance * 9 / 10;
        payable(manager).transfer(commission);
        payable(winner).transfer(winnerAmount);
        players = new address[](0);
    }

    modifier restricted (){
        require(msg.sender == manager);
        _;
    }
}