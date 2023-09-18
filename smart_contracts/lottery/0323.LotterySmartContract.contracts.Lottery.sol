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

    function random() private view returns (uint256) {
        return uint256(keccak256(block.difficulty,now,players));
    }

    function getBalance() public view returns(uint) {
        return this.balance;
    }

    function pickWinner() public restricted{
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        resetContract();
    }

    function resetContract() private {
        players = new address[](0);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns(address[]) {
        return players;
    }
}