// SPDX-License-Identifier: MIT

/**************************************
    @title Vending Machine Silmuator
    @author Siddhant Shah
    @date July 01 2022
***************************************/

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";        // openzepplin library for generating IDs
import "@openzeppelin/contracts/utils/math/SafeMath.sol";   // openzepplin library to prevent overflow
import "@openzeppelin/contracts/utils/Strings.sol";         // uerd for convertind int to string

contract LuckyLotto {

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter lottoID;           // id for each lottery event
    Counters.Counter gamblerID;         // id of each gambler
    Counters.Counter OrganizerID;       // id of each organizer

    enum LottoType {STANDARD, VARIABLE}                             //
    enum LottoStatus {WAITING, ACTIVE, SOLD_OUT, TIMEUP, CONCLUDED, SUSPENDED }    //

    // Gambler object
    struct Gambler {
        address gamblerAddress;             // address of the gambler
        uint256 gamblerID;                  // ID of Gambler
        uint256 totalWins;                  // total number of lotto that gampler has won
        uint256 balance;                    // balance of gambler that her can withdraw
        uint256[] lottoAsParticipants;      // array of LOTTO ID where gambler participated
        uint256[] lottoAsOrganizer;         // array of LOTTO ID whihc was organized by gambler
    }

    // Lotto object
    struct LottoEvent {
        uint256 activeTime;                 // time at which LOTTO is eligible for participation
        uint256 drawTime;                   // time at which LOTTO is eligible for draw
        uint256 balance;                    // total balance of LOTTO, money pasy by gamblers to participate
        uint256 lottoPot;                   // total prize money of the LOTTO
        uint256 ticketPrice;                // price to be paid by gamblers to participate in lottery
        uint256 maxParticipants;            // maximum number of participants allowed in Lottery. If 0 then any number of Participants can enter.
        uint256 minParticipants;            // minimum number of participants required for lottery to be eligible to draw. If not met then lottery will be suspended.
        address[] participants;             // array of gambler's address who have participated
        address[] winners;                  // array of winner's address
        address organizer;                  // address or LOTTO organizer
        LottoType lottoType;                // tyype of lotto
        LottoStatus lottoStatus;            // status of lotto
        bool refunded;
    }

    LottoEvent lotto;                               // lotto object
    Gambler gambler;                                // gambler object
    mapping(uint256 => LottoEvent) lottoMapping;    // mapping Lotto ID to lottoEvent object
    mapping(address => Gambler) gamblerMapping;     // mapping gambler ID to gambler object

    uint256[] lottoIDArray;                         // array of lotto IDs
    address[] gamblerAddressArray;                  // array of lotto IDs
    address[] participantsArray;                    // array of address of gamblers who are participating in Lotto
    address[] organizersArray;                      // array of address of gamblers who are organizing Lotto

    // EVENT Definitions
    event GamblerAdded(address, uint256);           // event that will be emited if new gambler is added
    event LottoCreated(uint256, uint256);           // event that will be emited if new lotto is created
    event LottoStatusUpdated(uint256, LottoStatus); // event that will be emited if lotto's status is changed
    event LottoTicketSold(uint256, address);        // event that will be emited if new lotto is created
    event CannotParticipate(uint256, LottoStatus);  // event that will be emited whne user is not able to participate because either Lotto is soldout, suspended or concluded.
    event CannotDraw(uint256, LottoStatus);         // event that will be emited whne user is not able to Draw lotto.
    event LottoWinnersAnnounced(uint256, address winner1, address winner2, address winner3);        // event that will be emited when winners are announced
    event WithdrawSuccessfull(address, uint256);

    /* @title MODIFIER to ensure that gambler exists */
    modifier isGambler {
        require(gamblerMapping[msg.sender].gamblerID != 0, "Not a valid Gambler");
        // require(gamblerMapping[msg.sender].gamblerAddress == address(0), "Already a Gambler");
        _;
    }

    /* @title MODIFIER to ensure that gambler exists */
    modifier isLotto(uint256 _lottoID) {
        require(lottoMapping[_lottoID].organizer != address(0), "No such lotto exists");
        _;
    }

    /* @title MODIFIER to ensure gambler is not organizer of LOTTO */
    modifier isNotOrganizer(uint256 _lottoID) {
        require(lottoMapping[_lottoID].organizer != msg.sender, "Organizers are not allowed to participate");
        _;
    }

    /* @title MODIFIER to ensure Lotto is in ACTIVE state */
    modifier isLottoActive(uint256 _lottoID) {
        require(lottoMapping[_lottoID].lottoStatus == LottoStatus.ACTIVE, string.concat("Not Active. Current Status: ", Strings.toString(uint(lottoMapping[_lottoID].lottoStatus))));
        _;
    }

    /* @title MODIFIER to ensure lotto is not soldout */
    modifier isNotSoldOut(uint256 _lottoID) {
        // require(lottoMapping[_lottoID].maxParticipants > lottoMapping[_lottoID].participants.length, "Lotto has sold out");
        require(lottoMapping[_lottoID].lottoStatus != LottoStatus.SOLD_OUT, "Lotto has Sold Out");
        _;
    }

    /* @title MODIFIER to ensure lotto can be drawn */
    modifier isTimesUp(uint256 _lottoID) {
        require(lottoMapping[_lottoID].lottoStatus == LottoStatus.TIMEUP, string.concat("Lotto can not be drawn at this momemnt. Current Status: ", Strings.toString(uint(lottoMapping[_lottoID].lottoStatus))));
        _;
    }

    /* @title MODIFIER to ensure lotto has not been concluded */
    modifier isNotConcluded(uint256 _lottoID) {
        require(lottoMapping[_lottoID].lottoStatus != LottoStatus.CONCLUDED, "Lotto has been Concluded.");
        _;
    }

    /* @title MODIFIER to ensure lotto has not been concluded */
    modifier isRefunded(uint256 _lottoID) {
        require(!lottoMapping[_lottoID].refunded, "Lotto has already been Refunded.");
        _;
    }

    /* @title MODIFIER to ensure lotto has not been concluded */
    modifier isSuspended(uint256 _lottoID) {
        require(lottoMapping[_lottoID].lottoStatus == LottoStatus.SUSPENDED, string.concat("Lotto is not Suspended. Current Status", Strings.toString(uint(lottoMapping[_lottoID].lottoStatus))));
        _;
    }

    /* @title MODIFIER to ensure lotto has not been suspended */
    modifier isNotSuspended(uint256 _lottoID) {
        require(lottoMapping[_lottoID].lottoStatus != LottoStatus.SUSPENDED, "Lotto has been Suspended.");
        _;
    }

    /* @title MODIFIER to ensure lotto has met minimum prticipations requirement */
    modifier hasMinimumParticipants(uint _lottoID){
        require(lottoMapping[_lottoID].minParticipants <= lottoMapping[_lottoID].participants.length, "Minimum participation criteria not met");
        _;
    }

    /**
        * @dev UTILITY FUNCTION to check and update LOTTO status
        * @param _lottoID uint256: ID of the LOTTO
    */
    function checkLottoStatus(uint256 _lottoID) internal isNotConcluded(_lottoID) isNotSuspended(_lottoID) {
        LottoStatus status;
        if (lottoMapping[_lottoID].activeTime > block.timestamp) {
            status = LottoStatus.WAITING;
        } else {
            status = LottoStatus.ACTIVE;
        }

        if (status == LottoStatus.ACTIVE) {
            if (lottoMapping[_lottoID].maxParticipants <= lottoMapping[_lottoID].participants.length) {
                status = LottoStatus.SOLD_OUT;
            }

            if (lottoMapping[_lottoID].drawTime <= block.timestamp) {
                if (lottoMapping[_lottoID].minParticipants > lottoMapping[_lottoID].participants.length) {
                    status = LottoStatus.SUSPENDED;
                    lottoMapping[_lottoID].lottoStatus = LottoStatus.SUSPENDED;
                    emit LottoStatusUpdated(_lottoID, lottoMapping[_lottoID].lottoStatus);
                    refundSuspendedLottery(_lottoID);
                } else {
                    status = LottoStatus.TIMEUP;
                    lottoMapping[_lottoID].lottoStatus = LottoStatus.TIMEUP;
                    emit LottoStatusUpdated(_lottoID, lottoMapping[_lottoID].lottoStatus);
                }
            }
        }

        if (lottoMapping[_lottoID].lottoStatus != status) {
            lottoMapping[_lottoID].lottoStatus = status;
            emit LottoStatusUpdated(_lottoID, lottoMapping[_lottoID].lottoStatus);
        }
    }

    function refundSuspendedLottery(uint256 _lottoID) internal isRefunded(_lottoID) isSuspended(_lottoID) {
        for (uint256 i = 0; i< lottoMapping[_lottoID].participants.length; i++){
            require(lottoMapping[_lottoID].balance >= lottoMapping[_lottoID].ticketPrice, "Not Enough Funds to refund all participants");
            gamblerMapping[lottoMapping[_lottoID].participants[i]].balance += lottoMapping[_lottoID].ticketPrice;
            lottoMapping[_lottoID].balance += lottoMapping[_lottoID].ticketPrice;
        }

        require(address(this).balance >= lottoMapping[_lottoID].lottoPot, "Unable to refund to Organizer");
        gamblerMapping[lottoMapping[_lottoID].organizer].balance += lottoMapping[_lottoID].lottoPot;

        lottoMapping[_lottoID].refunded = true;
    }

    /**
        * @dev UTILITY FUNCTION to calculate prize money
        * @param _lottoID uint256: ID of the LOTTO
        * @param _position uint256: Winner number(1, 2, or 3)
        * @return uint256
    */
    function prizeCalculator(uint256 _lottoID, uint256 _position) view internal returns (uint256) {
        uint256 _percent;
        if (_position == 1) {
            _percent = 60;
        } else if (_position == 2) {
            _percent = 30;
        } if (_position == 3) {
            _percent = 10;
        }
        return lottoMapping[_lottoID].lottoPot * _percent / 100;
    }

    /**
        * @dev UTILITY FUNCTION to generate random number depending on input numbers
        * @param _randomNumber uint256: random number
        * @param _position uint256: Winner number(1, 2, or 3)
        * @return uint256
    */
    function generateRandomNumber(uint256 _randomNumber, uint256 _position) view internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.difficulty, _randomNumber, _position)));
    }

    /**
        * @dev UTILITY FUNCTION to check if gambler exists
        * @return bool
    */
    function gamblerExists() internal view returns (bool) {
        if (gamblerMapping[msg.sender].gamblerID == 0){
            return false;
        } else {
            return true;
        }
        // require(gamblerMapping[msg.sender].gamblerAddress == address(0), "Already a Gambler");
    }

    /**
        * @dev UTILITY FUNCTION to add a new Gambler
    */
    function addGambler() internal {
        if (!gamblerExists()) {
            gamblerID.increment();      // creating id gambler
            Gambler storage _gambler = gamblerMapping[msg.sender];     // created new gambled object
            _gambler.gamblerAddress = msg.sender;
            _gambler.gamblerID = gamblerID.current();

            gamblerAddressArray.push(msg.sender);       // adding gambler's address to the array
            emit GamblerAdded(msg.sender, gamblerID.current());
        }
    }

    /**
        * @dev FUNCTION to let users create a LOTTO
        * @param _ticketPrice uint256: price to be paid for entry
        * @param _minParticipants uint256: minimum number of participants required in tthe lottery
        * @param _maxParticipants uint256: maximum number of participants required in tthe lottery
        * @param _drawTime uint256: time at which lottery will be eligible for draw
        * @param _lottoType LottoType: type of LOTTO
    */
    function createLotto(uint256 _ticketPrice, uint256 _minParticipants, uint256 _maxParticipants, uint256 _drawTime, LottoType _lottoType) payable external {
        require(msg.value > _ticketPrice, "Pot Prize has to be greater then Ticket Price");
        lottoID.increment();                        // new lotto ID
        lottoIDArray.push(lottoID.current());       // push newly created lotto ID to array

        addGambler(); // adding gambler(organizer) if doesnot exists

        // create a LOTTOEVENT
        LottoEvent storage _lotto = lottoMapping[lottoID.current()];
        _lotto.organizer = msg.sender;
        _lotto.lottoPot = msg.value;
        _lotto.ticketPrice = _ticketPrice;
        _lotto.maxParticipants = _maxParticipants;
        _lotto.minParticipants = _minParticipants;
        _lotto.lottoType = _lottoType;
        _lotto.lottoStatus = LottoStatus.ACTIVE;
        _lotto.activeTime = block.timestamp;
        _lotto.drawTime = _drawTime;

        // adding gambler to the organizers array
        organizersArray.push(msg.sender);

        // adding lotto to the gambler's array which he organized
        gamblerMapping[msg.sender].lottoAsOrganizer.push(lottoID.current());

        emit LottoCreated(lottoID.current(), msg.value);
    }

    /**
        * @dev FUNCTION to let users to participate in LOTTO
        * @param _lottoID uint256: ID of the LOTTO
    */
    function participate(uint256 _lottoID) payable external isNotOrganizer(_lottoID) isLotto(_lottoID) isLottoActive(_lottoID) {
        checkLottoStatus(_lottoID);
        if (lottoMapping[_lottoID].lottoStatus == LottoStatus.ACTIVE) {
            require(msg.value >= lottoMapping[_lottoID].ticketPrice, "Please sent ethers that matches Ticket Price");

            // adding gambler to blockchain if not exists
            addGambler();

            // adding gambler to the lotto
            lottoMapping[_lottoID].participants.push(msg.sender);
            lottoMapping[_lottoID].balance += msg.value;
            participantsArray.push(msg.sender);

            // checking and updating lotto's status
            checkLottoStatus(_lottoID);

            // adding lotto to the gambler's state to array which has last of lotto he took part as participant
            gamblerMapping[msg.sender].lottoAsParticipants.push(_lottoID);

            emit LottoTicketSold(_lottoID, msg.sender);
        } else {
            emit CannotParticipate(_lottoID, lottoMapping[_lottoID].lottoStatus);
        }
    }

    /**
        * @dev FUNCTION to let everyone to make lucky draw
        * @param _lottoID uint256: ID of the LOTTO
    */
    function drawLotto(uint256 _lottoID) external isNotConcluded(_lottoID) isNotSuspended(_lottoID) {
        checkLottoStatus(_lottoID);
        if (lottoMapping[_lottoID].lottoStatus == LottoStatus.TIMEUP) {
            uint256 _randomNumber = 25;

            // getting 1st 2nd and 3rd winner
            for (uint8 i=1; i<=3; i++) {
                // getting winning participant's array index
                uint256 _winnerIndex = generateRandomNumber(_randomNumber, i) % lottoMapping[_lottoID].participants.length;
                // getting winning participant's address
                address _winnerAddress = lottoMapping[_lottoID].participants[_winnerIndex];
                // updating LOTTO object with winners address
                lottoMapping[_lottoID].winners.push(_winnerAddress);

                // updating winner's balance and reducing LOTTO balance
                uint256 prizeMoney = prizeCalculator(_lottoID, i);
                gamblerMapping[_winnerAddress].balance += prizeMoney;
            }

            // transfering lotto's balance to organizer
            gamblerMapping[lottoMapping[_lottoID].organizer].balance += lottoMapping[_lottoID].balance;
            lottoMapping[_lottoID].balance = 0;

            // updating lotto status
            lottoMapping[_lottoID].lottoStatus = LottoStatus.CONCLUDED;

            emit LottoWinnersAnnounced(_lottoID, lottoMapping[_lottoID].winners[0], lottoMapping[_lottoID].winners[1], lottoMapping[_lottoID].winners[2]);
        } else {
            emit CannotDraw(_lottoID, lottoMapping[_lottoID].lottoStatus);

        }
    }

    /**
        * @dev FUNCTION to let everyone to make lucky draw
        * @param _amount uint256: Amount user wants to withdraw
    */
    function withdraw(uint256 _amount) external {
        require(gamblerMapping[msg.sender].balance >= _amount, "Don\'t have sufficient balance");
        gamblerMapping[msg.sender].balance -= _amount;
        (bool _success, ) = payable(msg.sender).call{ value: _amount }("");      // transfering funds

        //  if transfer succeed
        if (_success) {
            emit WithdrawSuccessfull(msg.sender, _amount);      // emit event
        } else{
            revert ("Unable to sent transaction because of some reason.");
        }
    }

    /**
        * @dev FUNCTION to get LOTTO object
        * @param _lottoID uint256: ID of the LOTTO
        * @return LottoEvent
    */
    function getLotto(uint256 _lottoID) view external returns(LottoEvent memory) {
        return lottoMapping[_lottoID];
    }

    /**
        * @dev FUNCTION to get callers objects as gambler
        * @return Gambler
    */
    function getGambler() view external returns(Gambler memory) {
        return gamblerMapping[msg.sender];
    }
}