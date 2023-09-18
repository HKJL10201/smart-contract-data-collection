// SPDX-License-Identifier: GPL-3.0
pragma solidity  >=0.5.0 <0.9.0;

contract Lottery{
    address public manager;
    address payable[] public players;
    address  payable public winner;

    constructor(){
        manager=msg.sender;
    }

     receive() external payable {
        require(msg.value == 1 ether);
        players.push(payable(msg.sender));
    }

    function totalAmountCollected() public view returns(uint){
        require(msg.sender==manager);
        return address(this).balance;
    }

    function randomNumberSelector() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }

    function selectWinner() public {
        require(msg.sender==manager);
        require(players.length>=3);
        // address payable winner;
        uint index=randomNumberSelector() % players.length;
        winner= players[index]; //winner
        winner.transfer(totalAmountCollected());
        players=new address payable [](0);
    }

}