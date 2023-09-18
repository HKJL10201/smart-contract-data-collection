//SPDX-License-Identifier:UNLICENSENSED

pragma solidity >=0.5.0 <0.9.0;

contract Lottery{

    address payable[] public TicketHolders;
    address public Trusty;
    constructor(){
        Trusty = msg.sender;
    }

    receive () payable external{
        require(msg.value == 0.1 ether);
        TicketHolders.push(payable(msg.sender));
    }

    function getTotalBalanceByTicketHolders() public view returns(uint){
        require(msg.sender == Trusty);
        return address(this).balance;
    }

    function HurrayWinner() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, TicketHolders.length)));
    }


    function PickFromTicketHolders() public{

        require(msg.sender == Trusty);
        require (TicketHolders.length >= 5);

        uint r = HurrayWinner();
        address payable winner;


        uint index = r % TicketHolders.length;

        winner = TicketHolders[index];

        winner.transfer(getTotalBalanceByTicketHolders());


        TicketHolders = new address payable[](0);
    }

}
