// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// DEPLOYED TO 0xaC34aC2600be403426E9Bd6DE9b895bFbbDF8391 
contract Lottery {
    address payable public manager;
    address payable[] public participants;
    address payable public winner;

    event LotteryParticipant(
        address participant,
        uint time
    );
    event Winner(
        uint rewardRecieved,
        address winner ,
        uint noOfParticipants
    );

    constructor(){
        manager =payable(msg.sender);
    }
    error NotEnoughParticipants(uint required , uint current);

     receive() external payable {
        require(winner == address(0), "Lottery Already Finished");
        require(msg.value == 0.1 ether, " 0.1 ether is required to take part in Lottery");
        participants.push(payable(msg.sender));
        emit LotteryParticipant(msg.sender , block.timestamp);
    }

    
    // Using simple random function without integrating Oracles for easier depiction of logic
    function random() public view returns (uint){
        return uint(keccak256(abi.encodePacked(block.timestamp , msg.sender , participants.length)));
    }

    function declareWinner() public payable  {
        require(msg.sender == manager, "Only Manager can declare Lottery");
        if(participants.length < 4){
            revert NotEnoughParticipants({
                required : 4 ,
                current : participants.length
            });
        }   
        uint randomNumber = random() % participants.length ;   
        winner = participants[randomNumber];
        uint reward = address(this).balance;
        assert(winner != address(0));
        winner.transfer(reward);
        emit Winner(reward , winner , participants.length);
    }
    
    function newLottery() public {
        require(msg.sender == manager, "Only Manager can start new Lottery");
        require(address(this).balance == 0 , "New Lottery can be started if previous is Finished");
        delete participants;
        delete winner;
    }

}