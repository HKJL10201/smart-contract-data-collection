// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time

pragma solidity ^0.8.3;

// OpenZeppelin
import "./openzeppelin-solidity/contracts/Ownable.sol";
import "./openzeppelin-solidity/contracts/ERC20/SafeERC20.sol";

// Internal references
import "./ExecutionPrice.sol";
import "./interfaces/IExecutionPrice.sol";
import "./interfaces/IPriceManager.sol";

// Inheritance
import "./interfaces/IExecutionPriceFactory.sol";

contract ExecutionPriceFactory is IExecutionPriceFactory, Ownable {
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */

    uint256 public MAX_INDEX = 10000;
    uint256 public MINT_COST = 1e20; // 100 bond tokens

    /* ========== STATE VARIABLES ========== */

    address immutable TGEN;
    address immutable xTGEN;
    address immutable marketplace;
    address immutable bondToken;
    IPriceManager priceManager;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _TGEN, address _xTGEN, address _marketplace, address _bondToken) Ownable() {
        TGEN = _TGEN;
        xTGEN = _xTGEN;
        marketplace = _marketplace;
        bondToken = _bondToken;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Purchases the ExecutionPrice NFT at the given index.
     * @param _index index of the ExecutionPrice NFT.
     * @param _maximumNumberOfInvestors the maximum number of open orders the queue can have.
     * @param _tradingFee fee that is paid to the contract owner whenever an order is filled; denominated by 10000.
     * @param _minimumOrderSize minimum number of bond tokens per order.
     */
    function purchase(uint256 _index, uint256 _maximumNumberOfInvestors, uint256 _tradingFee, uint256 _minimumOrderSize) external priceManagerIsSet {
        require(_index > 0 && _index <= MAX_INDEX, "PriceManager: index out of range.");

        uint256 price = priceManager.calculatePrice(_index);

        // Bond tokens stay locked in this contract, effectively burning them.
        IERC20(bondToken).safeTransferFrom(msg.sender, address(this), MINT_COST);

        //Create ExecutionPrice contract and mint an NFT.
        address executionPriceAddress = address(new ExecutionPrice(TGEN, bondToken, marketplace, xTGEN));

        priceManager.register(_index, msg.sender, executionPriceAddress, price);

        ExecutionPrice(executionPriceAddress).initialize(price, _maximumNumberOfInvestors, _tradingFee, _minimumOrderSize, msg.sender);

        emit Purchased(msg.sender, _index);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Sets the address of the PriceManager contract.
     * @notice This function can only be called by the owner of this contract.
     * @param _priceManager Address of the PriceManager contract.
     */
    function setPriceManager(address _priceManager) external onlyOwner priceManagerIsNotSet {
        priceManager = IPriceManager(_priceManager);

        emit SetPriceManager(_priceManager);
    }

    /**
    * @dev Updates the owner of the given ExecutionPrice contract.
    * @notice This function can only be called by the PriceManager contract.
    * @param _executionPrice Address of the ExecutionPrice address.
    * @param _newOwner Address of the new owner for the ExecutionPrice contract.
    */
    function updateContractOwner(address _executionPrice, address _newOwner) external override priceManagerIsSet {
        require(msg.sender == address(priceManager), "ExecutionPriceFactory: Only the PriceManager contract can call this function.");

        IExecutionPrice(_executionPrice).updateContractOwner(_newOwner);
    }

    /* ========== MODIFIERS ========== */

    modifier priceManagerIsNotSet() {
        require(address(priceManager) == address(0), "ExecutionPriceFactory: PriceManager contract is already set.");
        _;
    }

    modifier priceManagerIsSet() {
        require(address(priceManager) != address(0), "ExecutionPriceFactory: PriceManager contract is not set.");
        _;
    }

    /* ========== EVENTS ========== */

    event Purchased(address indexed buyer, uint256 index);
    event SetPriceManager(address priceManager);
}