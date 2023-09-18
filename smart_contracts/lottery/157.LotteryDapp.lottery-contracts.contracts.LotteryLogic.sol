//SPDX-License-Identifier: None
pragma solidity >=0.4.0;

import "./libs/Ownable.sol";
import "./Lottery.sol";
import "./libs/SafeMath.sol";

/**
@title The logic for the lotteries
@notice This contract contains all the logic needed by the lottery system to work
@dev The idea is that this logic can change as it´s needed while the system remains avaiable
*/
contract LotteryLogic is Ownable {

    using SafeMath for uint256;

    /**
    @notice requirements needed to participate in a lottery
    @dev As this function will be called from another contract, it can`t be a modifier
    @param _lottery lottery someone wants to participate in
    @param _participant the address who wants to participate
    @param _value amount sent in order to participate
    */
    function passMinimalRequirements(Lottery _lottery, address _participant, uint _value) public view returns (bool) {
        if (_lottery.hasParticipant(_participant)) return false;
        if (_value != _lottery.getTicketCost()) return false;
        if (!_lottery.isCurrentStageByValue("LotteryActive")) return false;
        return true;
    }

    /**
    @notice adds a participant to a lottery
    @dev At the end, we must check wether the lottery is able to finish or have to fail
    @param _lottery lottery to participate in
    @param _participant the address of the participant
    @param _cost amount needed to participate in the lottery
    */
    function addParticipant(Lottery _lottery, address _participant, uint _cost) public payable {
        require(passMinimalRequirements(_lottery, _participant, _cost), "No has pasado los requisitos minimos");
        _lottery.setParticipantState(_participant, true);
        _lottery.newParticipant(_participant);
        _lottery.allowForPull(_participant, _cost);
        checkLotteryParticipation(_lottery);
    }

    /**
    @notice checks if the lottery has to change its stage to Finish, Failed or none
    @param _lottery lottery to check
    */
    function checkLotteryParticipation(Lottery _lottery) public {
        if(_lottery.getParticipants().length == _lottery.getMaxParticipants()) {
            if(_lottery.getMaxParticipants().mul(_lottery.getTicketCost()) < _lottery.getPot()){ //safeMath
                _lottery.setStageByValue("LotteryFailed");
            }else {
                _lottery.setStageByValue("LotteryFinished");
            }
        }
    }

    /**
    @notice raffles the lottery prize amnong its participants
    @dev lottery must have finished in order to raffle the prize. Winner and Owner can withraw their money after the raffle
    @param _lottery lottery to raffle its prize
    @param _seed number of lotteries registered in the system
    */
    function rafflePrize(Lottery _lottery, uint _seed) public {
        require(_lottery.isCurrentStageByValue("LotteryFinished"), "Lottery not Finished");
        uint winnerIndex = uint(keccak256(
            abi.encodePacked(block.difficulty + block.timestamp + _seed))
            ).mod(_lottery.getMaxParticipants()); // safeMath
        _lottery.setWinner(_lottery.getParticipants()[winnerIndex]);
        _lottery.setStageByValue("LotteryTerminated");

        //Anotaciones de dinero
        _lottery.setUserCredits(_lottery.getWinner(), 0);
        _lottery.setUserCredits(_lottery.getOwner(), 0);
        _lottery.allowForPull(_lottery.getWinner(), _lottery.getPrize());
        _lottery.allowForPull(_lottery.getOwner(), _lottery.getPot().sub(_lottery.getPrize())); //safeMath
    }

    /**
    @notice transfers the receiver the money he deserves
    @dev if lottery has failed, all participants will receive their money back
    @param _lottery lottery the receiver wants to get his money from
    @param _receiver address that will receive the money
    */
    function withdrawParticipation(Lottery _lottery, address payable _receiver) public {

        if(_lottery.isCurrentStageByValue("LotteryFailed")){
            payWei(_lottery, _receiver);
        }

        if(_lottery.isCurrentStageByValue("LotteryTerminated")){

            if (_receiver == _lottery.getWinner() || _receiver == _lottery.getOwner()) {
                payWei(_lottery, _receiver);
            }
        }
    }

    /**
    @notice check credit to be paid and pay the wei
    @param _lottery lottery the receiver wants to get his money from
    @param _receiver address that will receive the money
    @dev have the requirements to pay the wei
    */
    function payWei(Lottery _lottery, address payable _receiver) internal {

        uint amount = _lottery.getUserCredits(_receiver);

        require(amount != 0,"No eth to receive");
        require(_lottery.getBalance() >= amount,"Contract has not enougth eth");

        _lottery.setUserCredits(_receiver,0);
        _lottery.sendWei(_receiver,amount);
    }

}