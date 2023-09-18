pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    function Lottery() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > 0.1 ether);
        players.push(msg.sender);
    }

    function random() private view returns (uint256) {
        /* FIXME:make a random function for development purposes */
        return uint256(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public isManager {
        uint256 index = random() % players.length;
        players[index].transfer(this.balance);
        /* The 0 in new address means how many dummy filing with be 0=None */
        players = new address[](0);
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }

    modifier isManager() {
        require(msg.sender == manager);
        /* _ is like children in react */
        _;
    }
}
