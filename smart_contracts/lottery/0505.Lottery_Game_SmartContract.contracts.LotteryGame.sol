//SPDX-License-Identifier: Unlicense

pragma solidity >=0.5.0 <0.9.0;

contract LotteryGame{

    address public manager;
    address payable[] public players;

    constructor()
    {
        manager=msg.sender;
    }

    receive() external payable{
        require(msg.value >=0.1 ether,"Minimum Contribution is not met");
        players.push(payable(msg.sender));
    } 

    function getBalance() public view returns(uint)
    {   
        require(msg.sender==manager,"Only manager can call this function");
        return address(this).balance;
    }

    function random() public view returns(uint)
    {
      return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function winner() public 
    {
        require(msg.sender==manager,"Only manager can call this function");
        require(players.length>=3,"Minimum players limit not met");
        uint r = random();
        uint index = r % players.length;
        address payable winner;
        winner = players[index];
        winner.transfer(getBalance());
    }


}
