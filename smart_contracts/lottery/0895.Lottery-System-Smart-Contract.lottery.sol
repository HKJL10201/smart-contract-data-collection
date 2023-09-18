//SPDX-License-Identifier : GPL-3.0

pragma solidity >=0.5.0 < 0.9.0;

contract Lottery{
    address public manager;
    address payable[] public participants;

    constructor() {
        manager = msg.sender;
    }

    //This triggers when the contract is paid 
    receive()  external payable{
        require(msg.value==0.01 ether);
        participants.push(payable(msg.sender));
    }

        //Used to check contract balance
    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public view returns(uint){
    return uint( keccak256(abi.encodePacked(block.difficulty  , block.timestamp , participants.length)));
    }

    function selectWinner() public payable  {
        require(msg.sender == manager);
        require(participants.length >= 3);
        uint r = random();
        uint index = r %participants.length;

        address payable winner;
        winner = participants[index];
        winner.transfer(getBalance());
        participants= new address payable[](0);        // This is to reset the participants array
    }
}