pragma solidity ^0.4.24;

contract Lottery {
    address public manager;

    address[] public players;

    constructor() public{
        manager=msg.sender;
    }

    function enterThePlayer() public payable {
      require(msg.value==0.05 ether);
      players.push(msg.sender);
    }

    function getAllPlayers() public view returns(address[]) {
      return players;
    }

    function pickWinner() public restricted {
      uint index=random() % players.length;
      players[index].transfer(address(this).balance);
      //Initiate players with dynamic address array with zero address i.e. the empty address

      players=new address[](0);
    }

    function random() private view returns (uint8){
      return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))));
    }

    modifier restricted(){
      require (msg.sender==manager);
      _;
    }

}
