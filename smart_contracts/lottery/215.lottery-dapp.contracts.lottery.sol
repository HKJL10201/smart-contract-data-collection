pragma solidity ^0.4.0;

contract Lottery{
    //Manager address
    address public manager;

    //Particpants Array
    address[] public participants;

    constructor () public {
        manager = msg.sender;
    }

    function enterLottery() public payable{
        //participants need to pay an amount to enter the lottery
        require(msg.value > 0.01 ether);
        participants.push(msg.sender);

    }

    function pickWinner() public{
        //can only be called by manager
        require(msg.sender == manager);

        //pick a random index
        uint256 index = random() % participants.length;

        //transfer the amount
        participants[index].transfer(this.balance);


        //clear out all the participants
        participants = new address[](0);
    }


    function random() private view returns(uint256){
        return uint256(keccak256(block.difficulty, now, participants)); 
    }

}
