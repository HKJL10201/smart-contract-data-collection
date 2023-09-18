pragma solidity ^0.5.8;
/**
    INSTRUCTION:
    Send more then or equal to [minPayment] or 0.01 ETH to one of Wallet Contract address
    [wallet_0, wallet_1, wallet_2], after round end send to This contract 0 ETH
    transaction and if you choice won, take your winnings.

    BOT:      http://t.me/SmartLotteryGame_bot
    DAPP:     https://smartlottery.clab
    GITHUB:   https://github.com/SmartLotteryGames
    LICENSE:  Under proprietary rights. All rights reserved.
              Except <lib.SafeMath, cont.Ownable, lib.Address> under The MIT License (MIT)
    AUTHOR:   http://t.me/pironmind

*/

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ISecure.sol";
import "./Wallet.sol";


contract SmartLotteryGame is Ownable {
    using SafeMath for *;

    event Withdrawn(address indexed requestor, uint256 weiAmount);
    event Deposited(address indexed payee, uint256 weiAmount);
    event WinnerWallet(address indexed wallet, uint256 bank);

    string public version = '2.1.0';

    address public secure;

    uint public games = 32;
    uint256 public minPayment = 10**16;

    Wallet public wallet_0 = new Wallet(games, minPayment);
    Wallet public wallet_1 = new Wallet(games, minPayment);
    Wallet public wallet_2 = new Wallet(games, minPayment);

    uint256 public finishTime;
    uint256 constant roundDuration = 1 days;

    uint internal _nonceId = 0;
    uint internal _maxPlayers = 100;
    uint internal _tp;
    uint internal _winner;
    uint8[] internal _particWallets = new uint8[](0);
    uint256 internal _fund;
    uint256 internal _commission;
    uint256 internal _totalBetsWithoutCommission;

    mapping(uint => Wallet) public wallets;
    mapping(address => uint256) private _deposits;

    struct wins {
        address winner;
        uint256 time;
        address w0;
        address w1;
        address w2;
    }

    struct bet {
        address wallet;
        uint256 balance;
    }

    mapping(uint => wins) public gamesLog;

    modifier isReady() {
        require(secure != address(0));
        _;
    }

    modifier onlyWallets() {
        require(
            msg.sender == address(wallet_0) ||
            msg.sender == address(wallet_1) ||
            msg.sender == address(wallet_2)
        );
        _;
    }

    constructor() public {
        wallets[0] = wallet_0;
        wallets[1] = wallet_1;
        wallets[2] = wallet_2;
    }

    function _deposit(address payee, uint256 amount) internal {
        _deposits[payee] = _deposits[payee].add(amount);
        emit Deposited(payee, amount);
    }

    function _raiseFunds() internal returns (uint256) {
        _fund = _fund.add(wallet_0.finishDay());
        _fund = _fund.add(wallet_1.finishDay());
        return _fund.add(wallet_2.finishDay());
    }

    function _winnerSelection() internal {
        uint8 winner;
        for(uint8 i=0; i<3; i++) {
            if(wallets[i].totalPlayers() > 0) {
                _particWallets.push(i);
            }
        }
        // random choose one of three wallets
        winner = uint8(ISecure(secure)
            .getRandomNumber(
                uint8(_particWallets.length),
                uint8(_tp),
                uint(games),
                _nonceId
            ));

        _winner = _particWallets[winner];
    }

    function _distribute() internal {
        bet memory p;

        _tp = wallets[_winner].totalPlayers();
        uint256 accommulDeposit = 0;
        uint256 percents = 0;
        uint256 onDeposit = 0;

        _commission = _fund.mul(15).div(100);
        _totalBetsWithoutCommission = _fund.sub(_commission);

        for (uint8 i = 1; i <= _tp; i++) {
            (p.wallet, p.balance) = wallets[_winner].bets(i);
            percents = (p.balance)
            .mul(10000)
            .div(wallets[_winner].totalBets());
            onDeposit = _totalBetsWithoutCommission
            .mul(percents)
            .div(10000);
            accommulDeposit = accommulDeposit.add(onDeposit);
            _deposit(p.wallet, onDeposit);
        }
        _deposit(owner(), _fund.sub(accommulDeposit));
    }

    function _cleanState() internal {
        _fund = 0;
        _particWallets = new uint8[](0);
    }

    function _log(address winner, uint256 fund) internal {
        gamesLog[games].winner = winner;
        gamesLog[games].time = now;
        gamesLog[games].w0 = address(wallet_0);
        gamesLog[games].w1 = address(wallet_1);
        gamesLog[games].w2 = address(wallet_2);
        emit WinnerWallet(winner, fund);
    }

    function _paymentValidator(address _payee, uint256 _amount) internal {
        if( _payee != address(wallet_0) &&
        _payee != address(wallet_1) &&
        _payee != address(wallet_2))
        {
            if(_amount == uint(0)) {
                if(depositOf(_payee) != uint(0)) {
                    withdraw();
                } else {
                    revert("You have zero balance");
                }
            } else {
                revert("You can't do nonzero transaction");
            }
        }
    }

    function _closeWallets() internal returns (bool) {
        wallets[0].closeContract();
        wallets[1].closeContract();
        return wallets[2].closeContract();
    }

    function _issueWallets() internal returns (bool) {
        wallets[0] = wallet_0 = new Wallet(games, minPayment);
        wallets[1] = wallet_1 = new Wallet(games, minPayment);
        wallets[2] = wallet_2 = new Wallet(games, minPayment);
        return true;
    }

    function _switchWallets() internal {
        if(_closeWallets()) {
            _issueWallets();
        } else { revert("break on switch");}
    }

    function _totalPlayers() internal view returns(uint) {
        return wallets[0].totalPlayers()
        .add(wallets[1].totalPlayers())
        .add(wallets[2].totalPlayers());
    }

    function depositOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    function lastWinner() public view returns(address) {
        return gamesLog[games].winner;
    }

    function participate()
    external
    onlyWallets
    isReady
    {
        _nonceId = _nonceId.add(1);
        _tp = _totalPlayers();

        if (now >= finishTime && 1 == _tp) {
            finishTime = now.add(roundDuration);
        }

        if (now >= finishTime || _tp >= _maxPlayers) {
            // send all funds to this wallet
            _fund = _raiseFunds();
            // if it has participators
            if(_fund > 0) {
                // get winner
                _winnerSelection();
                // do distribute
                _distribute();
                // log data
                _log(address(wallets[_winner]), _fund);
                // clear state
                _cleanState();
                // set next game
                games = games.add(1);
                // issue new wallets
                return _switchWallets();
            }
        }
    }

    function setMinPayment(uint256 _value) public onlyOwner {
        minPayment = _value;
    }

    function setSecure(address _address) public onlyOwner returns (bool) {
        secure = _address;
        return true;
    }

    function withdraw() public {
        uint256 payment = _deposits[msg.sender];
        _deposits[msg.sender] = 0;
        msg.sender.transfer(payment);
        emit Withdrawn(msg.sender, payment);
    }

    function getFunds() public payable onlyWallets {}

    function() external payable {
        _paymentValidator(msg.sender, msg.value);
    }
}
