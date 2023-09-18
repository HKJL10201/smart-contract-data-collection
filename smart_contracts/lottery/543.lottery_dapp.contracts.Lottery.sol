pragma solidity >=0.4.21 <0.6.0;

contract Lottery {
    address public manager;
    address[] players;
    address public winner;

    constructor () public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value == 10000000000000000);

        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }

    function pickWinner() public restricted {
        uint index = random() % players.length;
        manager.transfer(address(this).balance / 5);
        players[index].transfer(address(this).balance);
        winner = players[index];
        players = new address[](0);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}
