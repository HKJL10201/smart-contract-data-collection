pragma solidity ^0.5.8;

import "./SafeMath.sol";
import "./Address.sol";
import "./SmartLotteryGame.sol";

contract Wallet {
    using Address for address;
    using SafeMath for uint256;
    using SafeMath for uint8;

    SmartLotteryGame public slg;

    uint256 private _totalRised;
    uint8 private _players;
    bool closedOut = false;
    uint public gameId;
    uint256 public minPaymnent;

    struct bet {
        address wallet;
        uint256 balance;
    }

    mapping(uint8 => bet) public bets;

    modifier canAcceptPayment {
        require(msg.value >= minPaymnent);
        _;
    }

    modifier canDoTrx() {
        require(Address.isContract(msg.sender) != true);
        _;
    }

    modifier isClosedOut {
        require(!closedOut);
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == address(slg));
        _;
    }

    constructor(uint _gameId, uint256 _minPayment) public {
        slg = SmartLotteryGame(msg.sender);
        gameId = _gameId;
        minPaymnent = _minPayment;
    }

    function totalPlayers() public view returns(uint8) {
        return _players;
    }

    function totalBets() public view returns(uint256) {
        return _totalRised;
    }

    function finishDay() external onlyCreator returns(uint256) {
        uint256 balance = address(this).balance;
        if (balance >= minPaymnent) {
            slg.getFunds.value(balance)();
            return balance;
        } else {
            return 0;
        }
    }

    function closeContract() external onlyCreator returns(bool) {
        return closedOut = true;
    }

    function addPlayer(uint8 _id, address _player, uint256 _amount)
    internal
    returns(bool) {
        bets[_id].wallet = _player;
        bets[_id].balance = _amount;
        return true;
    }

    function()
    payable
    canAcceptPayment
    canDoTrx
    isClosedOut
    external {
        _totalRised = _totalRised.add(msg.value);
        _players = uint8((_players).add(1));
        addPlayer(_players, msg.sender, msg.value);
        slg.participate();
    }
}
