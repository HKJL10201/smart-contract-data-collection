// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//Deployed at GOERLI : 0xd5647f212280e1111ee1ea89ae3f8434415899b4
contract Lottery {

    address public owner;
    address[] public participants;
    uint256 public entryFee;

    enum STATE{
        OPEN,
        LOCKED,
        CLOSED
    }

    STATE public state;

    modifier inState(STATE _state) {
        require(state == _state, "Cant run this function in current state");
        _;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner can call this method.");
        _;
    }

    constructor(uint256 _entryFee) {
        owner = msg.sender;
        entryFee = _entryFee;
    }

    function participateInLottery() external payable inState(STATE.OPEN) {
        require(msg.value == entryFee, "Please send correct entry fee.");
        participants.push(msg.sender);
    }

    function getListOfParticipants() external view onlyOwner returns(address[] memory){
        
        return participants;
    }

    function getNumberOfParticipants() external view returns(uint256){
        return participants.length;
    }

    function lockLottery() external onlyOwner inState(STATE.OPEN){
       state = STATE.LOCKED;
    }

    function chooseWinner() external onlyOwner inState(STATE.LOCKED) returns(address){
        uint256 totalLotteryBalance = address(this).balance;
        uint256 winningPoolAmount =  (totalLotteryBalance * 9)/10;

        uint256 randomNumber = getRandomNumber(participants.length);

        //find winner
        address winner = participants[randomNumber];

        state = STATE.CLOSED;

        //transfer winning amount to winner
        payable(winner).transfer(winningPoolAmount);

        //transfer fee amount collectd to the owner
        payable(owner).transfer(address(this).balance);

        

        return winner;

    }

    function getRandomNumber(uint256 limit) internal view onlyOwner inState(STATE.LOCKED) returns(uint256){
        return (block.timestamp + block.difficulty)%limit;
    }



}