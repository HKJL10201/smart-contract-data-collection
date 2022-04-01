// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// import "@nomiclabs/buidler/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC20Base.sol";

contract ACDMPlatform is AccessControl, ReentrancyGuard {
    enum Round {
        Sale,
        Trade
    }

    Round public round;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public roundNum;
    uint256 public tokenPriceGWEI = 10000 gwei;
    uint256 public saleFirstRefCommission = 50;
    uint256 public saleSecondRefCommission = 30;
    uint256 public tradeCommision = 25; //2.5
    uint256 public roundDuration = 3 days;
    uint256 public roundStartTime;
    uint256 public tokensForSale = 100000;
    uint256 public amountTradedGWEI = 0 gwei;
    uint256 public orderId;

    address public token;

    struct Order {
        uint256 orderId;
        uint256 tokenAmount;
        uint256 tokenPriceGWEI;
        address creator;
    }

    mapping(address => address) public referrals;
    mapping(uint256 => Order) public orders;
    mapping(address => uint256) private _balances;

    event UserRegistered(address _newUser, address _referral);
    event DepositReceived(address _payer, uint256 _amount);
    event OrderClosed(
        uint256 indexed _roundNum,
        address _creator,
        uint256 indexed _orderId
    );
    event OrderPlaced(
        uint256 indexed _roundNum,
        address _creator,
        uint256 indexed _orderId
    );
    event SaleRoundStarted(
        uint256 _roundNum,
        uint256 _tokensForSale,
        uint256 _tokenPriceGWEI
    );
    event TradeRoundStarted(uint256 _roundNum);
    event TokenTraded(uint256 _roundNum, uint256 _orderId, uint256 _amount);
    event OrderRemoved(uint256 _roundNum, uint256 _orderId);

    constructor(address _tokenAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        token = _tokenAddress;
        roundStartTime = block.timestamp;
        round = Round.Sale;
    }

    modifier onRound(Round _round) {
        require(round == _round, "Round: invalid");
        _;
    }

    function startSaleRound() external onlyRole(ADMIN_ROLE) {
        _finishTradeRound();
        round = Round.Sale;
        roundNum++;
        roundStartTime = block.timestamp;
        ERC20Base(token).mint(address(this), tokensForSale);

        emit SaleRoundStarted(roundNum, tokensForSale, tokenPriceGWEI);
    }

    function _finishSaleRound() internal onRound(Round.Sale) {
        require(
            block.timestamp - roundStartTime > roundDuration ||
                ERC20Base(token).balanceOf(address(this)) == 0,
            "Round: finishing not allowed"
        );
        uint256 amountLeft = ERC20Base(token).balanceOf(address(this));
        require(amountLeft < tokensForSale, "Balance: tokens unsold");
        ERC20Base(token).burn(address(this), amountLeft);
    }

    function startTradePeriod() external onlyRole(ADMIN_ROLE) {
        _finishSaleRound();
        round = Round.Trade;
        roundNum++;
        roundStartTime = block.timestamp;

        emit TradeRoundStarted(roundNum);
    }

    function _finishTradeRound() internal onRound(Round.Trade) {
        require(
            block.timestamp - roundStartTime > roundDuration,
            "Round: finishing not allowed"
        );

        tokensForSale = amountTradedGWEI / tokenPriceGWEI;
        tokenPriceGWEI = (tokenPriceGWEI * 103) / 100 + 4000 gwei;
        amountTradedGWEI = 0 gwei;

        uint256 i;

        for (i = 0; i < orderId; i++) {
            if (orders[i].tokenAmount > 0) {
                uint256 tokensLeft = orders[i].tokenAmount;
                orders[i].tokenAmount = 0;
                ERC20Base(token).transfer(orders[i].creator, tokensLeft);
            }
            delete orders[i];
        }
        orderId = 0;
    }

    function register(address referral) external {
        require(msg.sender != referral, "Access: self-referral not allowed");
        require(
            referrals[msg.sender] == address(0),
            "Access: user already registered"
        );
        referrals[msg.sender] = referral;

        emit UserRegistered(msg.sender, referral);
    }

    function _paySaleCommision(
        address referral1,
        address referral2,
        uint256 _value
    ) internal returns (bool) {
        (bool success1, ) = referral1.call{
            value: (_value * saleFirstRefCommission) / 1000
        }("");
        require(success1, "Transfer: failed commission to first referral");
        if (referral2 != address(0)) {
            (bool success2, ) = referral2.call{
                value: (_value * saleSecondRefCommission) / 1000
            }("");
            require(success2, "Transfer: failed commission to second referral");
        }
        return true;
    }

    function buyTokens(uint256 _amount)
        external
        payable
        nonReentrant
        onRound(Round.Sale)
    {
        require(
            msg.value == tokenPriceGWEI * _amount,
            "Balance: amount sent is invalid"
        );
        require(
            ERC20Base(token).balanceOf(address(this)) >= _amount,
            "Balance: insufficient token supply"
        );

        require(
            referrals[msg.sender] != address(0),
            "Access: user not registered"
        );
        address referral1 = referrals[msg.sender];
        address referral2 = referrals[referral1];

        require(
            _paySaleCommision(referral1, referral2, msg.value),
            "Transaction: payment reverted"
        );

        ERC20Base(token).transfer(msg.sender, _amount);
        // amountTradedGWEI += msg.value;
    }

    function addOrder(uint256 _amount, uint256 _price)
        external
        onRound(Round.Trade)
    {
        require(
            referrals[msg.sender] != address(0),
            "Access: user not registered"
        );
        require(
            ERC20Base(token).balanceOf(msg.sender) >= _amount,
            "Balance: insufficient balance of tokens"
        );

        ERC20Base(token).transferFrom(msg.sender, address(this), _amount);
        orders[orderId] = Order(orderId, _amount, _price, msg.sender);
        // orderCreators[msg.sender] = orderId;

        emit OrderPlaced(roundNum, msg.sender, orderId);
        orderId++;
    }

    function removeOrder(uint256 _orderId)
        external
        onRound(Round.Trade)
        nonReentrant
    {
        require(
            orders[_orderId].creator == msg.sender,
            "Access: restriced to order creator"
        );

        uint256 tokensDue = orders[orderId].tokenAmount;
        delete orders[orderId];
        ERC20Base(token).transfer(msg.sender, tokensDue);

        emit OrderRemoved(roundNum, _orderId);
    }

    function _payTradeCommisions(address _creator, uint256 _saleValue)
        internal
        returns (bool)
    {
        _balances[_creator] += (_saleValue * 950) / 1000;

        (bool success1, ) = referrals[_creator].call{
            value: (_saleValue * 25) / 1000
        }("");
        require(
            success1,
            "Transfer: failed to send commission to first referral"
        );

        if (referrals[referrals[_creator]] != address(0)) {
            (bool success2, ) = referrals[referrals[_creator]].call{
                value: (_saleValue * 25) / 1000
            }("");
            require(
                success2,
                "Transfer: failed to send commission to second referral"
            );
        }

        return true;
    }

    function redeemOrder(uint256 _amount, uint256 _orderId)
        external
        payable
        nonReentrant
        onRound(Round.Trade)
    {
        require(
            orders[_orderId].tokenAmount >= _amount,
            "Balance: amount requested is invalid"
        );
        require(
            msg.value == _amount * orders[_orderId].tokenPriceGWEI,
            "Balance: invalid eth value sent"
        );

        require(_payTradeCommisions(orders[_orderId].creator, msg.value));

        orders[_orderId].tokenAmount -= _amount;
        ERC20Base(token).transfer(msg.sender, _amount);
        amountTradedGWEI += msg.value;

        emit TokenTraded(roundNum, _orderId, _amount);
    }

    function getOrderInfo(uint256 _orderId)
        external
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        return (
            orders[_orderId].tokenAmount,
            orders[_orderId].tokenPriceGWEI,
            orders[_orderId].creator
        );
    }

    function withdraw() external nonReentrant {
        uint256 withdrawalAmount = _balances[msg.sender];
        _balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: withdrawalAmount}("");
        require(success, "Transanction: withrawal failed");
    }

    function getBalance() external view returns (uint256) {
        return _balances[msg.sender];
    }

    receive() external payable {
        _balances[msg.sender] += msg.value;
        emit DepositReceived(msg.sender, msg.value);
    }
}
