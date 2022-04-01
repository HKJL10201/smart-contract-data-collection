pragma solidity ^0.4.17;

contract Blockttery {
    address public manager;
    address[] private players;
    uint16 public size;
    uint public price;
    address public winner;

    function Blockttery (uint16 _size, uint _price) public {
        manager = msg.sender;
        size = _size;
        price = _price;
    }

    function modifyPrice (uint _price) public admin {
        price = _price;
    }

    function modifySize (uint16 _size) public admin {
        size = _size;
    }

    function enter () public payable returns (address) {
        require(msg.value == price * 1000000000000000);
        players.push(msg.sender);
        if (getActualDrawSize() == size) {
            uint index = random() % players.length;
            winner = players[index];
            manager.transfer(this.balance * 5 / 100);
            winner.transfer(this.balance);
            players = new address[](0);
        }
    }

    function getPlayers () public view returns(address[]) {
        return players;
    }

    function getActualDrawSize () public view returns (uint) {
        return players.length;
    }

    modifier admin() {
        require(msg.sender == manager);
        _;
    }

    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
}