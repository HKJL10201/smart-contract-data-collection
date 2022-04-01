pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    modifier hasEth() {
        require(msg.value > .01 ether);
        _;
    }

    function Lottery() public payable {
        manager = msg.sender;
    }

    function enter() public payable hasEth {
        players.push(msg.sender);
    }

    function getPlayers() public view restricted returns (address[]) {
        return players;
    } 

    function random() private view returns (uint256) {
        return uint256(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public payable restricted returns (address) {
        uint winningNumber = random() % players.length;
        address winningPlayerAddress = players[winningNumber];
        winningPlayerAddress.transfer(this.balance);
        players = new address[](0);
        return winningPlayerAddress;
    }

    function getContractBalance() public view restricted returns (uint) {
        return this.balance;
    }
}