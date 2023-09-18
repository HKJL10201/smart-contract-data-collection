// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title A sample lottery contract
/// @author Bahador GhadamKheir
contract Lottery {
    using SafeMath for uint;

    address public lotteryStarter;
    address _lotteryAddress;
    uint starterFee;
    uint numberOfPlayers;

    struct LotteryInfo {
        bool lotteryStatus;
        address lotteryAddress;
        uint minimumEnteringAmount;
        uint totalDeposit;
        PlayerInfo[] player;
    }

    struct PlayerInfo {
        bool winner;
        address player;
        uint depositedAmount;
    }

    mapping(address => LotteryInfo) lottery;
    address[] lottaryReference;

    modifier onlyLotteryStarter() {
        require(msg.sender == lotteryStarter);
        _;
    }

    modifier activeLottery() {
        require(
            lottery[_lotteryAddress].lotteryStatus == true,
            "Lottery not started yet"
        );
        _;
    }

    event Deposit(address indexed participant, uint amount);
    event Winner(address indexed winner, uint winningAmount);

    constructor(uint _fee) {
        lotteryStarter = msg.sender;
        _lotteryAddress = address(this);
        starterFee = _fee;
        lottery[_lotteryAddress].lotteryAddress = _lotteryAddress;
    }

    function startLottery(
        uint _minimumEnteringAmount
    ) public onlyLotteryStarter {
        require(
            lottery[_lotteryAddress].lotteryStatus == false,
            "Lottery already started"
        );

        PlayerInfo memory _playerInfo = PlayerInfo(false, address(0), 0);

        lottery[_lotteryAddress].lotteryStatus = true;
        lottery[_lotteryAddress].minimumEnteringAmount = _minimumEnteringAmount;
        lottery[_lotteryAddress].totalDeposit = 0;
        lottery[_lotteryAddress].player.push(_playerInfo);
        numberOfPlayers = 1;

        lottaryReference.push(_lotteryAddress);
    }

    function enterLottery() public payable activeLottery {
        require(
            msg.value > lottery[_lotteryAddress].minimumEnteringAmount,
            "Minimum entering amount not passed"
        );

        uint deductedShare = calculateLotteryFee(msg.value);
        uint remainingShare = msg.value - deductedShare;

        PlayerInfo memory _playerInfo = PlayerInfo(
            false,
            msg.sender,
            remainingShare
        );

        payable(lotteryStarter).transfer(deductedShare);

        lottery[_lotteryAddress].totalDeposit += remainingShare;
        lottery[_lotteryAddress].player.push(_playerInfo);

        lottaryReference.push(msg.sender);

        emit Deposit(msg.sender, remainingShare);
    }

    function getPlayers(
        uint startRecord,
        uint endRecord
    ) public view returns (address[] memory, uint[] memory) {
        address[] memory _player = new address[](lottaryReference.length);
        uint[] memory _depositedAmount = new uint[](lottaryReference.length);
        for (uint i = startRecord; i <= endRecord; i++) {
            // address addressinArray = lottaryReference[0];
            _player[i - 1] = lottery[_lotteryAddress].player[i - 1].player;
            _depositedAmount[i - 1] = lottery[_lotteryAddress]
                .player[i - 1]
                .depositedAmount;
        }

        return (_player, _depositedAmount);
    }

    function stopLottery() external onlyLotteryStarter {
        require(
            lottery[_lotteryAddress].lotteryStatus == true,
            "Lottery already stoped"
        );
        lottery[_lotteryAddress].lotteryStatus == false;
    }

    function setFeePercent(uint256 lotteryFee) external onlyLotteryStarter {
        require(lotteryFee <= 20, "To high Fee is not acceptable!");
        starterFee = lotteryFee;
    }

    function calculateLotteryFee(
        uint256 _amount
    ) private view returns (uint256) {
        return _amount.mul(starterFee).div(10 ** 2);
    }
}
