//SPDX-License-Identifier: None
// solium-disable linebreak-style
pragma solidity >=0.4.0;

import "./libs/Ownable.sol";

/**
@title The interface of the logic behind the lotteries
@notice This contract only defines the functions needed and implemented in LotteryLogic
*/
interface LogicInterface {
    function addParticipant(Lottery _ml, address _participant, uint _cost) external;
    function checkLotteryParticipation(Lottery _ml) external returns (bool);
    function rafflePrize(Lottery _ml, uint _seed) external;
    function withdrawParticipation(Lottery _ml, address _receiver) external;
}

/**
@title The lotteries created by the users
@notice This contract saves the participations of the users and the information relative to each created lottery
*/
contract Lottery {

    address[] public participants;
    mapping (address => bool) regParticipants;

    mapping (address => uint) credits;

    uint max_participants;
    uint ticket_cost;
    uint pot;
    uint prize;

    address winner;
    address owner;

    Stages stage;

    enum Stages {
        LotteryActive,
        LotteryFinished,
        LotteryTerminated,
        LotteryFailed
    }

    LogicInterface logicContract;

    constructor(uint _max_participants, uint _ticket_cost, uint _prize, uint _pot, address _lotteryLogic, address _sender) public {
        require(_max_participants > 0, "El numero de participantes tiene que ser superior a 0");
        require(_ticket_cost > 0, "El coste de cada ticket tiene que ser superior a 0");
        require(_prize > 0, "El premio tiene que ser superior a 0");
        require(_pot > 0, "El bote tiene que ser superior a 0");
        max_participants = _max_participants;
        ticket_cost = _ticket_cost;
        prize = _prize;
        pot = _pot;
        stage = Stages.LotteryActive;
        logicContract = LogicInterface(_lotteryLogic);
        owner = _sender;
    }

    /**
    @notice fallback function to receive the participations
    */
    function() external payable {

    }

    /**
    @notice sets the address of the logic
    @param _address address of the interface
    @param _sender address that wants to set the interface address
    */
    function setLogicInterfaceAddress(address _address, address _sender) external  {
        require(_sender == owner, "Solo el dueño de la loteria");
        logicContract = LogicInterface(_address);
    }

    /**
    @notice gets the address where the logic contract is set
    @return logicContract
    */
    function getLogicContract() public view returns (LogicInterface) {
        return logicContract;
    }

    /**
    @notice raffles the prize among the participants
    @dev only the owner of the lottery can do so
    @param _seed value of the system to make the raffle
    @param _sender the address asking to raffle the prize
    */
    function rafflePrize(uint _seed, address _sender) public  {
        require(_sender == owner, "Solo el dueño de la loteria");
        logicContract.rafflePrize(this, _seed);
    }

    /**
    @notice adds a participant to the lottery
    @dev the logic for adding a participant is in LotteryLogic.sol
    @param _participant the address of the participant
    @param _cost amount needed to participate in the lottery
    */
    function addParticipant(address _participant, uint _cost) public {
        logicContract.addParticipant(this, _participant, _cost);
    }

    // getters/setters participant
    /**
    @notice adds a participant to the mapping regParticipants
    @param _participant address of the participant
    @param _state state of the participant
    */
    function setParticipantState(address _participant, bool _state) external{
        regParticipants[_participant] = _state;
    }

    /**
    @notice adds a participant to the array participants
    @param _participant address of the participant
    */
    function newParticipant(address _participant) external{
        participants.push(_participant);
    }

    /**
    @notice gets the amount of address allowed to participate
    @return the maximum participants allowed
    */
    function getMaxParticipants() public view returns(uint){
        return max_participants;
    }

    /**
    @notice gets all the participants of the lottery
    @return the address of all the participants
    */
    function getParticipants() public view returns(address[] memory){
        return participants;
    }

    /**
    @notice checks if an address has already participated in the lottery
    @param _participant the address of the participant to check
    @return true of the address is in regParticipants
    */
    function hasParticipant(address _participant) public view returns(bool){
        return regParticipants[_participant];
    }

    // getters/setters ticket_cost
    /**
    @notice gets the price to pay for participating in the lottery
    @return the price
    */
    function getTicketCost() public view returns(uint){
        return ticket_cost;
    }

    // getters/setters pot
    /**
    @notice gets the pot of the lottery
    @return pot of the lottery
    */
    function getPot() public view returns(uint){
        return pot;
    }

    // getters/setters prize
    /**
    @notice gets the prize of winning the lottery
    @return prizes of the lottery
    */
    function getPrize() public view returns(uint){
        return prize;
    }

    // getters/setters winner
    /**
    @notice gets the winner of the lottery
    @return address of the winner of the lottery
    */
    function getWinner() public view returns(address){
        return winner;
    }

    /**
    @notice sets the winner of the lottery
    @param _winner address of the winner
    */
    function setWinner(address _winner) public {
        winner = _winner;
    }

    // getters/setters stage

    /**
    @notice gets the current stage of the lottery
    @return stage of the lottery as a string
    */
    function getStage() public view returns(string memory){
        if (Stages.LotteryActive == stage ) return "LotteryActive";
        if (Stages.LotteryFinished == stage ) return "LotteryFinished";
        if (Stages.LotteryTerminated == stage ) return "LotteryTerminated";
        if (Stages.LotteryFailed == stage ) return "LotteryFailed";
    }

    /**
    @notice gets the stage by its string
    @param _value the stage as a string
    @return stage of the lottery as a Stage
    */
    function getStagesByValue(string memory _value) public pure returns (Stages) {
        if (keccak256(abi.encodePacked(_value)) == keccak256(abi.encodePacked("LotteryActive"))) return Stages.LotteryActive;
        else if (keccak256(abi.encodePacked(_value)) == keccak256(abi.encodePacked("LotteryFinished"))) return Stages.LotteryFinished;
        else if (keccak256(abi.encodePacked(_value)) == keccak256(abi.encodePacked("LotteryTerminated"))) return Stages.LotteryTerminated;
        else if (keccak256(abi.encodePacked(_value)) == keccak256(abi.encodePacked("LotteryFailed"))) return Stages.LotteryFailed;
    }

    /**
    @notice sets the stage of the lottery
    @param _stage the stage to be set
    */
    function setStage(Stages _stage) internal {
        stage = _stage;
    }

    /**
    @notice sets the stage of the lottery by a string
    @param _value the stage string to be set
    */
    function setStageByValue(string calldata _value) external {
        setStage(getStagesByValue(_value));
    }

    /**
    @notice checks if the lottery is at a specified stage
    @param _value the stage string to compare to
    */
    function isCurrentStageByValue(string memory _value) public view returns (bool) {
        if (getStagesByValue(_value) == stage) {
            return true;
        }
        return false;
    }

    /**
    @notice gets the owner of the lottery
    @return the addresss of the owner
    */
    function getOwner()public view returns(address){
        return owner;
    }

    /**
    @notice gets the balance of the lottery
    @return the balance
    */
    function getBalance()public view returns(uint){
        return address(this).balance;
    }

    // Functions to apply Pull over Push and Checks Effects Interactions patterns

    /**
    @notice allow an address to receive some amount
    @dev this is only a way to take note of who can withdraw founds
    @param receiver the address that will receive the amount
    @param amount corresponding amount of wei
    */
    function allowForPull(address receiver, uint amount) external {
        credits[receiver] += amount;
    }

    /**
    @notice let a user withdraw his founds
    @dev main logic in LotteryLogic.sol
    @param _user the addres who wants to withraw its eth
    */
    function withdrawParticipation(address _user) public {
        logicContract.withdrawParticipation(this, _user);
    }

    /**
    @notice gets the amount deserved by a user (participant or owner)
    @param _user the addres to check its amount
    */
    function getUserCredits(address _user) public view returns(uint){
        return credits[_user];
    }

    /**
    @notice sets the amount deserved by a user (participant or owner)
    @param _user the addres to sets the new ammount
    @param _amount the amount
    */
    function setUserCredits(address _user, uint _amount) public {
        credits[_user] = _amount;
    }

    /**
    @notice sends some amount to an address
    @param _to the address to send the amount to
    @param _amount the amount to be sent
    */
    function sendWei(address payable _to, uint _amount) public {
        _to.transfer(_amount);
    }
}