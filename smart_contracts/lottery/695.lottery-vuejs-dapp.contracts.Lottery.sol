pragma solidity ^0.4.0;

contract Lottery {
    address public manager;
    address[] public players;

    event LogWinner(address winner, uint amount);

    function Lottery() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }

    function random() private view returns (uint){
        return uint(sha3(now, players.length, block.difficulty));
    }

    function pickWinner() public restricted {
        require(msg.sender == manager);
        uint index = random() % players.length;
        LogWinner(players[index], this.balance);
        players[index].transfer(this.balance);
        players = new address[](0);
    }

    function getPlayers() public view returns (address[]){
        return players;
    }

    function getAddress() public view returns (address){
      return this;
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
}
