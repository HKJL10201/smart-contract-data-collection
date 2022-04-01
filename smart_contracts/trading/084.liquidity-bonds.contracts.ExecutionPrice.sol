// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin
import "./openzeppelin-solidity/contracts/ERC20/SafeERC20.sol";
import "./openzeppelin-solidity/contracts/ERC20/IERC20.sol";
import "./openzeppelin-solidity/contracts/SafeMath.sol";

// Inheritance
import './interfaces/IExecutionPrice.sol';

// Interfaces
import './interfaces/IPriceManager.sol';
import './interfaces/ILiquidityBond.sol';

contract ExecutionPrice is IExecutionPrice {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Order {
        address user;
        uint256 quantity;
        uint256 amountFilled;
    }

    struct Params {
        uint256 price; // Number of TGEN per bond token
        uint256 maximumNumberOfInvestors;
        uint256 tradingFee;
        uint256 minimumOrderSize;
        address owner;
    }

    uint256 constant MIN_MINIMUM_ORDER_VALUE = 1e18; // $1
    uint256 constant MAX_MINIMUM_ORDER_VALUE = 1e20; // $100
    uint256 constant MIN_MAXIMUM_NUMBER_OF_INVESTORS = 10;
    uint256 constant MAX_MAXIMUM_NUMBER_OF_INVESTORS = 50;
    uint256 constant MAX_TRADING_FEE = 300; // 3%, with 10000 as denominator

    IERC20 immutable TGEN;
    IERC20 immutable bondToken;
    address factory;
    address immutable marketplace;
    address immutable xTGEN;

    Params public params;

    uint256 public startIndex = 1;
    uint256 public endIndex = 1;

    // Number of tokens in the queue.
    // When the queue is a 'buy queue', this represents 
    uint256 public numberOfTokensAvailable;

    // Order index => order info.
    mapping(uint256 => Order) public orderBook;

    // If a user's index is < startIndex, the order is considered filled.
    mapping(address => uint256) public orderIndex;

    // Specifies whether the queue consists of orders to buy bond tokens or orders to sell bond tokens.
    // If true, the queue will hold TGEN and executing an order will act as a 'sell' (users receive bond tokens).
    // If false, the queue will hold bond tokens and executing an order will act as a 'buy' (users receive TGEN).
    bool public isBuyQueue;

    bool internal initialized;

    constructor(address _TGEN, address _bondToken, address _marketplace, address _xTGEN) {
        TGEN = IERC20(_TGEN);
        bondToken = IERC20(_bondToken);
        factory = msg.sender;
        marketplace = _marketplace;
        xTGEN = _xTGEN;
        isBuyQueue = true;

        params = Params({
            price: 1e18,
            maximumNumberOfInvestors: 20,
            tradingFee: 50,
            minimumOrderSize: 1e16,
            owner: address(0)
        });
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Creates an order to buy bond tokens.
     * @notice Executes existing 'sell' orders before adding this order.
     * @param _amount number of bond tokens to buy.
     */
    function buy(uint256 _amount) public override isInitialized {
        require(_amount >= params.minimumOrderSize, "ExecutionPrice: amount must be above minimum order size.");

        TGEN.safeTransferFrom(msg.sender, address(this), _amount.mul(params.price).div(1e18));

        // Add order to queue or update existing order.
        if (isBuyQueue) {
            // Update existing order.
            if (orderIndex[msg.sender] >= startIndex) {
                orderBook[orderIndex[msg.sender]].quantity = orderBook[orderIndex[msg.sender]].quantity.add(_amount);
                numberOfTokensAvailable = numberOfTokensAvailable.add(_amount);
            }
            // Add order to queue.
            else {
                require(endIndex.sub(startIndex) <= params.maximumNumberOfInvestors, "ExecutionPrice: queue is full.");
                _append(msg.sender, _amount);
            }

            emit Buy(msg.sender, _amount, 0);
        }
        // Fill as much of the order as possible, and add remainder as a new order.
        else {
            uint256 filledAmount = _executeOrder(_amount);

            // Not enough sell orders to fill this buy order.
            // Queue becomes a 'buy queue' and this becomes the first order in the queue.
            if (filledAmount < _amount) {
                isBuyQueue = !isBuyQueue;
                _append(msg.sender, _amount.sub(filledAmount));
            }

            bondToken.safeTransfer(msg.sender, filledAmount);

            emit Buy(msg.sender, _amount, filledAmount);
        }
    }

    /**
     * @dev Creates an order to sell bond tokens.
     * @notice Executes existing 'buy' orders before adding this order.
     * @param _amount number of bond tokens to sell.
     */
    function sell(uint256 _amount) public override isInitialized {
        require(_amount >= params.minimumOrderSize, "ExecutionPrice: amount must be above minimum order size.");

        bondToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Fill as much of the order as possible, and add remainder as a new order.
        if (isBuyQueue) {
            uint256 filledAmount = _executeOrder(_amount);

            // Not enough buy orders to fill this sell order.
            // Queue becomes a 'sell queue' and this becomes the first order in the queue.
            if (filledAmount < _amount) {
                isBuyQueue = !isBuyQueue;
                _append(msg.sender, _amount.sub(filledAmount));
            }

            TGEN.safeTransfer(msg.sender, filledAmount);

            emit Sell(msg.sender, _amount, filledAmount);
        }
        // Add order to queue.
        else {
            // Update existing order.
            if (orderIndex[msg.sender] >= startIndex) {
                orderBook[orderIndex[msg.sender]].quantity = orderBook[orderIndex[msg.sender]].quantity.add(_amount);
                numberOfTokensAvailable = numberOfTokensAvailable.add(_amount);
            }
            // Add order to queue.
            else {
                require(endIndex.sub(startIndex) <= params.maximumNumberOfInvestors, "ExecutionPrice: queue is full.");
                _append(msg.sender, _amount);
            }

            emit Sell(msg.sender, _amount, 0);
        }
    }

   /**
     * @dev Updates the order quantity and transaction type (buy vs. sell).
     * @notice If the transaction type is different from the original type,
     *          existing orders will be executed before updating this order.
     * @param _amount number of bond tokens to buy/sell.
     * @param _buy whether this is a 'buy' order.
     */
    function updateOrder(uint256 _amount, bool _buy) external override isInitialized {
        require(_amount >= params.minimumOrderSize, "ExecutionPrice: amount must be above minimum order size.");

        // User's previous order is filled, so treat this as a new order.
        if (orderIndex[msg.sender] < startIndex) {
            if (_buy) {
                buy(_amount);
            }
            else {
                sell(_amount);
            }

            return;
        }

        // Order is same type as the queue.
        if ((_buy && isBuyQueue) || (!_buy && !isBuyQueue)) {
            // Cancels the order if the new amount is less than the filled amount.
            if (_amount < orderBook[orderIndex[msg.sender]].amountFilled) {
                numberOfTokensAvailable = numberOfTokensAvailable.sub(orderBook[orderIndex[msg.sender]].quantity.sub(orderBook[orderIndex[msg.sender]].amountFilled));
                orderBook[orderIndex[msg.sender]].quantity = orderBook[orderIndex[msg.sender]].amountFilled;
            }
            // Amount is less than previous amount, so release tokens held in escrow.
            else if (_amount <= orderBook[orderIndex[msg.sender]].quantity) {
                numberOfTokensAvailable = numberOfTokensAvailable.sub(orderBook[orderIndex[msg.sender]].quantity.sub(_amount));

                if (_buy) {
                    TGEN.transfer(msg.sender, (orderBook[orderIndex[msg.sender]].quantity.sub(_amount)).mul(params.price).div(1e18));
                }
                else {
                    bondToken.transfer(msg.sender, orderBook[orderIndex[msg.sender]].quantity.sub(_amount));
                }
                
                orderBook[orderIndex[msg.sender]].quantity = _amount;

                emit UpdatedOrder(msg.sender, _amount, _buy);
            }
            // Amount is more than previous amount, so transfer tokens to this contract to hold in escrow.
            else {
                numberOfTokensAvailable = numberOfTokensAvailable.add(_amount).sub(orderBook[orderIndex[msg.sender]].quantity);

                if (_buy) {
                    TGEN.safeTransferFrom(msg.sender, address(this), (_amount.sub(orderBook[orderIndex[msg.sender]].quantity)).mul(params.price).div(1e18));
                }
                else {
                    bondToken.safeTransferFrom(msg.sender, address(this), _amount.sub(orderBook[orderIndex[msg.sender]].quantity));
                }

                orderBook[orderIndex[msg.sender]].quantity = _amount;

                emit UpdatedOrder(msg.sender, _amount, _buy);
            }
        }
        // Order type is different from that of the queue.
        // Releases user's tokens from escrow, cancels the existing order, and create order opposite the queue's type.
        else {
            numberOfTokensAvailable = numberOfTokensAvailable.sub(orderBook[orderIndex[msg.sender]].quantity.sub(orderBook[orderIndex[msg.sender]].amountFilled));

            if (_buy) {
                bondToken.transfer(msg.sender, orderBook[orderIndex[msg.sender]].quantity.sub(orderBook[orderIndex[msg.sender]].amountFilled));

                orderBook[orderIndex[msg.sender]].amountFilled = 0;
                orderBook[orderIndex[msg.sender]].quantity = 0;

                buy(_amount);
            }
            else {
                TGEN.transfer(msg.sender, orderBook[orderIndex[msg.sender]].quantity.sub(orderBook[orderIndex[msg.sender]].amountFilled));

                orderBook[orderIndex[msg.sender]].amountFilled = 0;
                orderBook[orderIndex[msg.sender]].quantity = 0;

                sell(_amount);
            }
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Adds an order to the end of the queue.
     * @param _user address of the user placing this order.
     * @param _amount number of bond tokens.
     */
    function _append(address _user, uint256 _amount) internal {
        orderBook[endIndex] = Order({
            user: _user,
            quantity: _amount,
            amountFilled: 0
        });

        numberOfTokensAvailable = numberOfTokensAvailable.add(_amount);
        orderIndex[_user] = endIndex;
        endIndex = endIndex.add(1);
    }

    /**
     * @dev Executes an order based on the queue type.
     * @notice If queue is a 'buy queue', this will be treated as a 'sell' order. 
     * @notice Fee is paid in bond tokens if queue is a 'sell queue'.
     * @param _amount number of bond tokens.
     * @return totalFilledAmount - number of bond tokens bought/sold.
     */
    function _executeOrder(uint256 _amount) internal returns (uint256 totalFilledAmount) {
        uint256 filledAmount;

        // Claim bond token rewards accumulated while tokens were in escrow.
        uint256 initialBalance = TGEN.balanceOf(address(this));
        ILiquidityBond(address(bondToken)).getReward();
        uint256 newBalance = TGEN.balanceOf(address(this));

        {
        // Save gas by getting endIndex once, instead of after each loop iteration.
        uint256 start = startIndex;
        uint256 end = endIndex;

        // Iterate over each open order until given order is filled or there's no more open orders.
        // This loop is bounded by 'maximumNumberOfInvestors', which cannot be more than 50.
        for (; start < end; start++) {
            filledAmount = (_amount.sub(totalFilledAmount) > orderBook[start].quantity.sub(orderBook[start].amountFilled)) ?
                            orderBook[start].quantity.sub(orderBook[start].amountFilled) :
                            _amount.sub(totalFilledAmount);
            totalFilledAmount = totalFilledAmount.add(filledAmount);
            orderBook[start].amountFilled = orderBook[start].amountFilled.add(filledAmount);

            if (isBuyQueue) {
                bondToken.transfer(orderBook[start].user, filledAmount.mul(10000 - params.tradingFee).div(10000));
            }
            else {
                TGEN.transfer(orderBook[start].user, filledAmount.mul(params.price).mul(10000 - params.tradingFee).div(1e18).div(10000));
            }

            // Exit early when order is filled.
            if (totalFilledAmount == _amount) {
                break;
            }

            // Avoid skipping last order if it was partially filled.
            if (totalFilledAmount < _amount && filledAmount < orderBook[start].quantity) {
                break;
            }
        }

        startIndex = start;
        }

        // Send trading fee to contract owner.
        // If owner is the marketplace contract (NFT held in escrow while listed for sale), transfer TGEN to xTGEN contract
        // and burn bond tokens.
        if (isBuyQueue) {
            bondToken.transfer((params.owner == marketplace) ? address(0) : params.owner, totalFilledAmount.mul(params.tradingFee).div(10000));
        }
        else {
            TGEN.transfer((params.owner == marketplace) ? xTGEN : params.owner, totalFilledAmount.mul(params.price).mul(params.tradingFee).div(1e18).div(10000));
        }

        numberOfTokensAvailable = numberOfTokensAvailable.sub(totalFilledAmount);

        // Transfer accumulated rewards to xTGEN contract.
        TGEN.safeTransfer(xTGEN, newBalance.sub(initialBalance));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Updates the trading fee for this ExecutionPrice.
     * @notice This function is meant to be called by the contract owner.
     * @param _newFee the new trading fee.
     */
    function updateTradingFee(uint256 _newFee) external override onlyOwner isInitialized {
        require(_newFee >= 0 && _newFee <= MAX_TRADING_FEE, "ExecutionPrice: trading fee out of range.");

        params.tradingFee = _newFee;

        emit UpdatedTradingFee(_newFee);
    }

    /**
     * @dev Updates the minimum order size for this ExecutionPrice.
     * @notice This function is meant to be called by the contract owner.
     * @param _newSize the new minimum order size.
     */
    function updateMinimumOrderSize(uint256 _newSize) external override onlyOwner isInitialized {
        require(_newSize.mul(params.price).div(1e18) >= MIN_MINIMUM_ORDER_VALUE, "ExecutionPrice: minimum order size is too low.");
        require(_newSize.mul(params.price).div(1e18) <= MAX_MINIMUM_ORDER_VALUE, "ExecutionPrice: minimum order size is too high.");

        params.minimumOrderSize = _newSize;

        emit UpdatedMinimumOrderSize(_newSize);
    }

    /**
     * @dev Updates the owner of this ExecutionPrice.
     * @notice This function is meant to be called by the ExecutionPriceFactory contract whenever the
     *          ExecutionPrice NFT is purchased by another user.
     * @param _newOwner the new contract owner.
     */
    function updateContractOwner(address _newOwner) external override onlyFactory isInitialized {
        require(_newOwner != address(0) && _newOwner != params.owner, "ExecutionPrice: invalid address for new owner.");

        params.owner = _newOwner;

        emit UpdatedOwner(_newOwner);
    }

    /**
     * @dev Initializes the contract's parameters.
     * @notice This function is meant to be called by the ExecutionPriceFactory contract when creating this contract.
     * @param _price the price of each bond token.
     * @param _maximumNumberOfInvestors the maximum number of open orders the queue can have.
     * @param _tradingFee fee that is paid to the contract owner whenever an order is filled; denominated by 10000.
     * @param _minimumOrderSize minimum number of bond tokens per order.
     * @param _owner address of the contract owner.
     */
    function initialize(uint256 _price, uint256 _maximumNumberOfInvestors, uint256 _tradingFee, uint256 _minimumOrderSize, address _owner) external override onlyFactory isNotInitialized {
        require(_maximumNumberOfInvestors >= MIN_MAXIMUM_NUMBER_OF_INVESTORS, "ExecutionPrice: maximum number of investors is too low.");
        require(_maximumNumberOfInvestors <= MAX_MAXIMUM_NUMBER_OF_INVESTORS, "ExecutionPrice: maximum number of investors is too high.");
        require(_tradingFee >= 0 && _tradingFee <= MAX_TRADING_FEE, "ExecutionPrice: trading fee out of range.");
        require(_minimumOrderSize.mul(_price).div(1e18) >= MIN_MINIMUM_ORDER_VALUE, "ExecutionPrice: minimum order size is too low.");
        require(_minimumOrderSize.mul(_price).div(1e18) <= MAX_MINIMUM_ORDER_VALUE, "ExecutionPrice: minimum order size is too high.");

        params = Params({
            price: _price,
            maximumNumberOfInvestors: _maximumNumberOfInvestors,
            tradingFee: _tradingFee,
            minimumOrderSize: _minimumOrderSize,
            owner: _owner
        });

        initialized = true;

        emit InitializedContract(_price, _maximumNumberOfInvestors, _tradingFee, _minimumOrderSize, _owner);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyFactory() {
        require(msg.sender == factory, "ExecutionPrice: only the ExecutionPriceFactory contract can call this function.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == params.owner, "ExecutionPrice: only the contract owner can call this function.");
        _;
    }

    modifier isNotInitialized() {
        require(!initialized, "ExecutionPrice: contract must not be initialized.");
        _;
    }

    modifier isInitialized() {
        require(initialized, "ExecutionPrice: contract must be initialized.");
        _;
    }

    /* ========== EVENTS ========== */

    event Buy(address indexed user, uint256 numberOfTokens, uint256 filledAmount);
    event Sell(address indexed user, uint256 numberOfTokens, uint256 filledAmount);
    event UpdatedOwner(address newOwner);
    event UpdatedTradingFee(uint256 newFee);
    event UpdatedMinimumOrderSize(uint256 newOrderSize);
    event UpdatedOrder(address indexed user, uint256 numberOfTokens, bool isBuyOrder);
    event InitializedContract(uint256 price, uint256 maximumNumberOfInvestors, uint256 tradingFee, uint256 minimumOrderSize, address owner);
}