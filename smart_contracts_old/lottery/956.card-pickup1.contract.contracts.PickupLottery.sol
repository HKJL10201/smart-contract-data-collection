// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./WithCards.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
    [[[ Simple Playing Card Lottery ]]]
*/
contract PickupLottery is WithCards, Ownable {
    uint256 private constant MAX_TIME_LIMIT = 6 * 30 * 24 * 60 * 60 * 1000;
    uint256 private constant MIN_TIME_LIMIT = 5 * 60 * 1000;
    uint256 private constant MAX_BONUS_PERCENTAGE = 95;

    // config params
    uint256 public roundFee = 0.01 * (10**18);
    uint256 public winningCard = 1;
    uint256 public pickupLimit = 40;
    // 1 week limit for single round
    uint256 public timeLimit = 7 * 24 * 60 * 60 * 1000;
    uint256 public bonusPercentage = 90;

    bool public started = false;
    uint256 public startedAt;
    uint256 public endedAt;

    address [] private _players;

    // player address + picked-up card
    mapping (address => uint256) private pickupStatus;

    // player address + paid fee
    mapping (address => uint256) private _balances;

    // player address + nick name
    mapping (address => bytes) private _nicknames;

    // player address + awarded bonus amount
    mapping (address => uint256) private _bonuses;

    string[] public winners;

    modifier onlyStopped() {
        require (!started, "It is only available after stopped round.");
        _;
    }

    modifier onlyStarted() {
        require (
            started && 
            (block.timestamp < startedAt + timeLimit) && 
            (_players.length < pickupLimit),
            "It is only available after start a round."
        );
        _;
    }

    event Started(uint256 startedTime);
    event Stopped(uint256 startedTime, uint256 stoppedTime);

    event FeeChanged(uint256 oldFee, uint256 newFee);
    event WinningCardChanged(uint256 oldCard, uint256 newCard);
    event PickupLimitChanged(uint256 oldLimit, uint256 newLimit);
    event TimeLimitChanged(uint256 oldLimit, uint256 newLimit);
    event BonusPercentageChanged(uint256 oldBonus, uint256 newBonus);

    event CardPicked(uint256 numberOfPicks);

    /**
        Owner's role
     */
    function setFee(uint256 _fee) external onlyOwner onlyStopped {
        require(_fee > 0, "Fee should not be zero.");
        emit FeeChanged(roundFee, _fee);
        roundFee = _fee;
    }

    function setWinningCard(uint256 _card) external onlyOwner onlyStopped onlyValidCard(_card) {
        emit WinningCardChanged(winningCard, _card);
        winningCard = _card;
    }

    function setPickupLimit(uint256 _limit) external onlyOwner onlyStopped {
        require(_limit > 0 && _limit < 55, "Pickup limit should be less than 55.");
        emit PickupLimitChanged(pickupLimit, _limit);
        pickupLimit = _limit;
    }

    function setTimeLimit(uint256 _limit) external onlyOwner onlyStopped {
        require(
            _limit > MIN_TIME_LIMIT && _limit < MAX_TIME_LIMIT,
            "Time limit should be between 5 minutes and 6 months."
        );
        emit TimeLimitChanged(timeLimit, _limit);

        timeLimit = _limit;
    }

    function setBonusPercentage(uint256 _bonusPercentage) external onlyOwner onlyStopped {
        require(
            _bonusPercentage > 0 && _bonusPercentage < MAX_BONUS_PERCENTAGE,
            "Winner's bonus should be less than 95% of all incomes."
        );
        emit BonusPercentageChanged(bonusPercentage, _bonusPercentage);
        bonusPercentage = _bonusPercentage;
    }

    // start()
    // generate randomized cards list
    // and record start time
    function start() external onlyOwner onlyStopped {
        // clear previous status
        for (uint i; i < _players.length; i++) {
            delete _balances[_players[i]];
            delete pickupStatus[_players[i]];
        }
        delete endedAt;
        delete _players;

        // reset new round
        generateCardsList();
        started = true;
        startedAt = block.timestamp;

        emit Started(startedAt);
    }

    function stop() external onlyOwner onlyStarted {
        _stop();
    }

    function _stop() internal onlyStarted {
        started = false;
        endedAt = block.timestamp;
        address _winner;

        // calculate total income, and find winner
        uint256 totalIncome;
        for (uint i = 0; i < _players.length; i++) {
            address player = _players[i];
            totalIncome += _balances[player];

            uint256 card = pickupStatus[player];
            if (card == winningCard) {
                _winner = player;
            }
        }

        if (_winner != address(0)) {
            _bonuses[_winner] += totalIncome.mul(bonusPercentage).div(100);
            winners.push(string(abi.encodePacked(_nicknames[_winner])));
        }

        emit Stopped(startedAt, endedAt);
    }

    // This will finish the round unexpectedly, so it will refund all balances to card holders
    // and reset all status
    function cancel() external onlyOwner onlyStarted {

    }

    function transfer(address payable recipient, uint256 amount) external onlyOwner{
        require(address(this).balance > amount, "Insufficient balance.");
        recipient.transfer(amount);
    }

    /**
        Player's role
     */
    function pick(bytes calldata nickName) external payable onlyStarted returns (uint256 card) {
        require(pickupStatus[msg.sender] == 0, "Player can pick up card at once.");
        require(msg.value >= roundFee, "Player must pay to pick up a card.");

        if (startedAt.add(timeLimit) < block.timestamp) {
            emit Stopped(startedAt, block.timestamp);
            revert("Sorry, but round is already expired!");
        }

        // upgrade nick name
        if (nickName.length > 0) {
            _nicknames[msg.sender] = nickName;
        }

        pickupStatus[msg.sender] = _cardsList[_players.length];
        _players.push(msg.sender);
        _balances[msg.sender] = msg.value;
        emit CardPicked(_players.length);

        if (_players.length >= pickupLimit) {
            _stop();
        }
        card = pickupStatus[msg.sender];
    }

    function picked() external view returns (uint256 card) {
        return pickupStatus[msg.sender];
    }

    function bonus() external view returns (uint256) {
        return _bonuses[msg.sender];
    }

    function withdraw() external returns (bool) {
        require(_bonuses[msg.sender] > 0, "Insufficient funds.");
        uint256 amount = _bonuses[msg.sender];
        _bonuses[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        return true;
    }

    /**
        Public role
     */
    function leftTime() external view returns (uint256) {
        return (startedAt.add(timeLimit) > block.timestamp) ? 
            startedAt.add(timeLimit).sub(block.timestamp) :
            0;
    }

    function progress() external view returns (uint) {
        return _players.length;
    }

    // returns all picked-up cards, without holders address
    function all() external view returns (uint256[] memory) {
        uint256[] memory cards = new uint256[](_players.length);
        for (uint i; i < _players.length; i++) {
            // if started, then show only my card. and if stopped then show all cards
            if (started) {
                cards[i] = _players[i] == msg.sender ? pickupStatus[msg.sender] : 0;
            } else {
                cards[i] = pickupStatus[_players[i]];
            }
        }
        return cards;
    }

    // returns latest winner
    function winner() external view returns (string memory result) {
        require(winners.length > 0, "Not winners yet!");
        result = winners[winners.length - 1];
    }
}
