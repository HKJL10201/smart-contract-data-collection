// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Lottery{
        address public manager;

        address payable[] public customer;

        constructor(){
            manager = msg.sender;
        }
        function payEthe() external payable {
            require(msg.value >= 1 ether);

            customer.push( payable(msg.sender));
        }
        function getBlancd() public view returns(uint){
            require(msg.sender == manager);
            return address(this).balance;

        }

        function random() public view returns(uint){
            return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,customer.length)));
        }
        function winnerSelect()public {
              require(msg.sender==manager);
              require(customer.length>=3);
              uint  r = random()%customer.length;
              address payable winner;
              winner = customer[r];
              winner.transfer(getBlancd() );
        }

        function costmerList() public view returns(uint){
            return customer.length;
        }
        

}
