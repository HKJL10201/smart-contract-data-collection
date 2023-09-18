//SPDX-License-Identifier: None
// solium-disable linebreak-style
pragma solidity >=0.4.0;

import "./Lottery.sol";
import "./LotteryLogic.sol";
import "./LotteryStorage.sol";
import "./libs/Ownable.sol";

/**
@title The main service
@notice This contract contains all the functions and events that will be called from the front-end
@dev This contract should always be up as its logic is derived to LotteryLogic.sol
*/
contract LotteryService is Ownable {

    uint private numberOfLotteries;

    address lotteryLogic = address(new LotteryLogic()); // Creamos la lógica 1.0

    LotteryStorage lotteryStorage = new LotteryStorage(msg.sender);  // Creamos el storage 1.0

    // Lottery Logic
    /**
    @notice sets the address of the Logic contract
    @dev logic contract has all the logic needed in order to create, participate and raffle
    @param _lotteryLogic address of the Logic contract
    */
    function setLotteryLogic(address _lotteryLogic) public onlyOwner {
        lotteryLogic = _lotteryLogic;
    }

    /**
    @notice updates the address of the logic in case it is needed
    @dev the address is only changed if the lottery is working with an old version
    @param _lotteryId address of the lottery who needs to get the logic address changed
    */
    modifier checkLogicInterface(address _lotteryId) {
        /* Actualiza la interfaz de las Loterias en curso en caso de ser necesario */
        if (address(lotteryStorage.getLottery(_lotteryId).getLogicContract()) != lotteryLogic) {
            lotteryStorage.getLottery(_lotteryId).setLogicInterfaceAddress(lotteryLogic, msg.sender);
        }
        _;
    }

    // Lottery Storage
    /**
    @notice sets the address of the Storage contract
    @dev Storage has all lotteries saved in order to have an eternal storage
    @param _lotteryStorageAddr address of the Storage contract
    */
    function setLotteryStorage(address _lotteryStorageAddr) public onlyOwner {
        lotteryStorage = LotteryStorage(address(_lotteryStorageAddr));
        lotteryStorage.upgradeVersion(address(this), msg.sender);
    }

    /**
    @notice creates a new lottery in the system
    @dev when a new lottery is created, it needs to know where its logic its (setLogicInterfaceAddress)
    @param _max_participants number of participants a lottery will have
    @param _participant_cost the amount each participation costs
    @param _prize the amount the winner will get
    @param _pot the total amount the lottery needs to collect
    */
    function createLottery(uint _max_participants, uint _participant_cost, uint _prize, uint _pot) public {
        Lottery lottery = new Lottery(_max_participants, _participant_cost, _prize, _pot, lotteryLogic, msg.sender);

        lotteryStorage.setLottery(address(lottery), lottery);

        emit newLottery(address(lottery),_max_participants, _participant_cost, _prize, _pot, msg.sender);
    }

    /**
    @notice adds a new participant to the lottery
    @dev it calls the addParticipant function of the especified lottery. The new participant must pass the minimal requirements
    @dev the amount of the participation is owned by each lottery. CheckLogicInterface checks the version of the logic
    @param _lotteryId the address of the lottery to add the participant to
    */
    function addParticipant(address _lotteryId) public payable checkLogicInterface(_lotteryId) {
        lotteryStorage.getLottery(_lotteryId).addParticipant(msg.sender, msg.value);
        address(lotteryStorage.getLottery(_lotteryId)).transfer(msg.value); //Sends money to the Lottery

        emit newParticipant(_lotteryId,msg.sender);
    }

    /**
    @notice raffles the loterry prize among its participants
    @dev it calls each lottery raffle function. Only the owner of the lottery can raffle the prize (see rafflePrize in Lottery.sol)
    */
    function rafflePrize(address _lotteryId) public checkLogicInterface(_lotteryId){
        lotteryStorage.getLottery(_lotteryId).rafflePrize(lotteryStorage.getLotteries().length, msg.sender);

        emit hasFinished(_lotteryId);
    }

    /**
    @notice the address calling can withdraw the amount he deserves from the specified lottery
    @dev the lottery is the one that sends the amount
    @param _lotteryId the lottery to take the amount from
    */
    function withdrawParticipation(address _lotteryId) public payable checkLogicInterface(_lotteryId) {
        lotteryStorage.getLottery(_lotteryId).withdrawParticipation(msg.sender);
    }

    /**
    @notice gets all the lotteries in the system
    @dev the lotteries are stored in LotteryStorage contract
    @return array of Lottery
    */
    function getLotteries() public view returns(Lottery[] memory){
        return lotteryStorage.getLotteries();
    }

    /**
    @notice gets a lottery info
    @return all the information of a lottery
    */
    function getLottery(address _lotteryId) public view returns(address owner, address winner,
        uint max_participants, uint ticket_cost, uint prize, uint pot,
        address[] memory participants, string memory stage){
            Lottery lottery = lotteryStorage.getLottery(_lotteryId);
        return (
            lottery.getOwner(),lottery.getWinner(),
            lottery.getMaxParticipants(),lottery.getTicketCost(),
            lottery.getPrize(),lottery.getPot(),
            lottery.getParticipants(),lottery.getStage());
    }


    /**
    @notice gets the participants of the specified lottery
    @param _lotteryId the lottery to get the participants from
    @return address of all the participants
    */
    function getLotteryParticipants(address _lotteryId) public view returns (address[] memory){
        return lotteryStorage.getLottery(_lotteryId).getParticipants();
    }

    /**
    @notice gets the price to participate in the specified lottery
    @param _lotteryId the lottery to get the price from
    @return price of the lottery
    */
    function getTicketCost(address _lotteryId) public view returns(uint){
        return lotteryStorage.getLottery(_lotteryId).getTicketCost();
    }

    event newLottery(address loteryId, uint max_participants, uint participant_cost, uint prize, uint pot, address owner);
    event newParticipant(address lotteryId, address participant);
    event hasFinished(address loteryId);
}