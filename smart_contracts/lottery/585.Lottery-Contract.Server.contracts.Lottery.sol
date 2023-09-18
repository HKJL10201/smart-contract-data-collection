pragma solidity ^0.5.0;


contract Lottery{
    address public manager;
    address payable[] public players;

    constructor()public {
        manager = msg.sender;
    }

    function enter()public payable {
        require(msg.value > .01 ether, 'must make an eligible bet');
        players.push(msg.sender);
    }

    function random() public view returns(uint){
      return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }

    function getPlayersCount() public view returns(uint){
        return players.length;
    }

    function pickWinner() public{
        uint index = random() % players.length;
        players[index].transfer(1 ether);
       delete players;
    }

}