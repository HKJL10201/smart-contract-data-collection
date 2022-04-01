pragma solidity ^0.5.3;

contract Lotto {
  uint eth = 1000000000000000000; //1 eth in wei units
  uint contributors = 0;
  address payable[2] private users;

  function check() external view returns (bool bet_waiting, uint256 amount){
    return (contributors == 1, address(this).balance);
  }

  function() external payable {
    users[contributors++] = msg.sender;

    if (contributors > 1) {
      drawWinner();
    }
  }

  function drawWinner() private {
    uint random = uint(blockhash(block.number-1))%2; //not really a random number

    users[random].transfer(address(this).balance);

    contributors = 0;
    delete users;
  }
}
