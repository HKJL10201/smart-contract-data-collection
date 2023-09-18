//"SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.0;

contract Lottery {
  address public manager;
  address payable[] private participants;

  constructor() public {
    manager = msg.sender;
  }

  function enterLottery() public payable {
    require(msg.value >= 0.01 ether);
    participants.push( payable(msg.sender));
  }

  function pickWinner() public {
    require(msg.sender == manager);
    uint256 index = random() % participants.length;
    participants[index].transfer(address(this).balance);
    participants = new address payable[](0);
  }

  function random() private view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            block.difficulty,
            block.timestamp,
            participants
          )
        )
      );
  }
}
