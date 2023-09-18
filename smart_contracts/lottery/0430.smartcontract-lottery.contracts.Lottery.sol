//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Lottery is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum LotteryState {
        Opened,
        Closed,
        Finished
    }

    struct Record {
        mapping(address => uint256) entries;
        EnumerableSet.AddressSet players;
    }

    LotteryState public state;
    // Can only draw after this time.
    uint256 public drawTime;

    // For each allowed number, store the player addresses and entries.
    mapping(uint256 => Record) private records;
    // Store the entries count of each submit number.
    mapping(uint256 => uint256) public entriesCounts;

    uint256 public constant prizeRatio = 40;
    uint256 public constant smallestNumberAllowed = 1;
    uint256 public constant largestNumberAllowed = 49;

    uint256 public entryFee;
    uint256 public prizePerEntry;
    uint256 public winningNumber;

    event LotteryStateChanged(LotteryState newState);
    event NewEntry(address player, uint256 unit);
    event NumberDrawed(uint256 number);
    event NextDrawScheduled(uint256 entryFee, uint256 drawTime);

    modifier isState(LotteryState _state) {
        require(state == _state, "Invalid state for the action");
        _;
    }

    constructor(uint256 _entryFee, uint256 _drawTime) Ownable() {
        require(_entryFee > 0, "Entry fee must be positive");
        entryFee = _entryFee;
        drawTime = _drawTime;
        prizePerEntry = prizeRatio * entryFee;
    }

    function deposite() public payable onlyOwner {}

    function withdraw() public isState(LotteryState.Finished) onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// Set the entry fee, and next draw time.
    function scheduleNextDraw(uint256 _entryFee, uint256 _drawTime)
        public
        isState(LotteryState.Finished)
        onlyOwner
    {
        require(_entryFee > 0, "Entry fee must be positive");
        entryFee = _entryFee;
        drawTime = _drawTime;
        prizePerEntry = prizeRatio * entryFee;
        _changeState(LotteryState.Opened);
        emit NextDrawScheduled(_entryFee, _drawTime);
    }

    function resetState() private {
        winningNumber = 0;
        for (
            uint256 i = smallestNumberAllowed;
            i <= largestNumberAllowed;
            i++
        ) {
            Record storage _record = records[i];
            EnumerableSet.AddressSet storage _players = _record.players;

            while (_players.length() > 0) {
                address _player = _players.at(0);
                delete _record.entries[_player];
                _players.remove(_player);
            }
            delete entriesCounts[i];
        }
    }

    /// Submit a number
    function submitNumber(uint256 _number)
        public
        payable
        isState(LotteryState.Opened)
    {
        require(msg.value >= entryFee, "Minimum entry fee required");
        require(_number >= smallestNumberAllowed, "Number too small");
        require(_number <= largestNumberAllowed, "Number too large");
        uint256 _numEntries = SafeMath.div(msg.value, entryFee);
        uint256 newEntriesCount = entriesCounts[_number] + _numEntries;
        require(
            address(this).balance >=
                SafeMath.mul(newEntriesCount, prizePerEntry),
            "Contract balance too low"
        );

        Record storage _record = records[_number];
        _record.entries[msg.sender] += _numEntries;
        _record.players.add(msg.sender);
        entriesCounts[_number] = newEntriesCount;

        emit NewEntry(msg.sender, _number);
    }

    /// Draw the number, transfer the prize to winners,
    function drawNumber() public isState(LotteryState.Opened) {
        require(block.timestamp >= drawTime, "Too early to draw");
        _changeState(LotteryState.Closed);
        winningNumber = randomNumber();
        emit NumberDrawed(winningNumber);

        Record storage _record = records[winningNumber];
        EnumerableSet.AddressSet storage _players = _record.players;
        for (uint256 i = 0; i < _players.length(); i++) {
            address _winner = _players.at(i);
            uint256 _numEntries = _record.entries[_winner];
            if (_numEntries > 0) {
                uint256 _prize = SafeMath.mul(_numEntries, prizePerEntry);
                payable(_winner).transfer(_prize);
            }
        }
        resetState();
        _changeState(LotteryState.Finished);
    }

    function randomNumber() private view returns (uint256) {
        uint256 _numbers = largestNumberAllowed + 1;
        uint256[] memory _hashes = new uint256[](_numbers);

        // An attacker might figure out the winning number during mining stage.
        // However, if the attacker submit the winning number, the _addresses and _entries changes,
        // which cause the winnning number to change as well.
        for (
            uint256 i = smallestNumberAllowed;
            i <= largestNumberAllowed;
            i++
        ) {
            Record storage _record = records[i];
            EnumerableSet.AddressSet storage _players = _record.players;
            address[] memory _addresses = new address[](_players.length());
            uint256[] memory _entries = new uint256[](_players.length());
            for (uint256 j = 0; j < _players.length(); j++) {
                address _player = _players.at(j);
                _addresses[j] = _player;
                _entries[j] = _record.entries[_player];
            }
            uint256 _hash = uint256(
                keccak256(abi.encodePacked(_addresses, _entries))
            );
            _hashes[i] = _hash;
        }

        return
            (uint256(keccak256(abi.encodePacked(_hashes))) %
                (largestNumberAllowed)) + smallestNumberAllowed;
    }

    function _changeState(LotteryState _state) private {
        state = _state;
        emit LotteryStateChanged(state);
    }

    function getState() public view returns (LotteryState) {
        return state;
    }
}
