pragma solidity ^0.5.7;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./livepeerInterface/IController.sol";

contract LptOrderBook {

    using SafeMath for uint256;

    address private constant ZERO_ADDRESS = address(0);

    string internal constant ERROR_DELIVERED_BY_IN_PAST = "LPT_ORDER_DELIVERED_BY_IN_PAST";
    string internal constant ERROR_SELL_ORDER_COMMITTED_TO = "LPT_ORDER_SELL_ORDER_COMMITTED_TO";
    string internal constant ERROR_SELL_ORDER_NOT_COMMITTED_TO = "LPT_ORDER_SELL_ORDER_NOT_COMMITTED_TO";
    string internal constant ERROR_INITIALISED_ORDER = "LPT_ORDER_INITIALISED_ORDER";
    string internal constant ERROR_UNINITIALISED_ORDER = "LPT_ORDER_UNINITIALISED_ORDER";
    string internal constant ERROR_NOT_BUYER = "LPT_ORDER_NOT_BUYER";
    string internal constant ERROR_STILL_WITHIN_LOCK_PERIOD = "LPT_ORDER_STILL_WITHIN_LOCK_PERIOD";

    struct LptSellOrder {
        uint256 lptSellValue;
        uint256 daiPaymentValue;
        uint256 daiCollateralValue;
        uint256 deliveredByBlock;
        address buyerAddress;
    }

    IController livepeerController;
    IERC20 daiToken;
    mapping(address => LptSellOrder) public lptSellOrders; // One sell order per address for simplicity

    constructor(address _livepeerController, address _daiToken) public {
        livepeerController = IController(_livepeerController);
        daiToken = IERC20(_daiToken);
    }

    /*
    * @notice Create an LPT sell order, requires approval for this contract to spend `_daiCollateralValue` amount of DAI.
    * @param _lptSellValue Value of LPT to sell
    * @param _daiPaymentValue Value required in exchange for LPT
    * @param _daiCollateralValue Value of collateral
    * @param _deliveredByBlock Order filled or cancelled by this block or the collateral can be claimed
    */
    function createLptSellOrder(uint256 _lptSellValue, uint256 _daiPaymentValue, uint256 _daiCollateralValue, uint256 _deliveredByBlock) public {
        LptSellOrder storage lptSellOrder = lptSellOrders[msg.sender];

        require(lptSellOrder.daiCollateralValue == 0, ERROR_INITIALISED_ORDER);
        require(_deliveredByBlock > block.number, ERROR_DELIVERED_BY_IN_PAST);

        daiToken.transferFrom(msg.sender, address(this), _daiCollateralValue);

        lptSellOrders[msg.sender] = LptSellOrder(_lptSellValue, _daiPaymentValue, _daiCollateralValue, _deliveredByBlock, ZERO_ADDRESS);
    }

    /*
    * @notice Cancel an LPT sell order, must be executed by the sell order creator.
    */
    function cancelLptSellOrder() public {
        LptSellOrder storage lptSellOrder = lptSellOrders[msg.sender];

        require(lptSellOrder.buyerAddress == ZERO_ADDRESS, ERROR_SELL_ORDER_COMMITTED_TO);

        daiToken.transfer(msg.sender, lptSellOrder.daiCollateralValue);
        delete lptSellOrders[msg.sender];
    }

    /*
    * @notice Commit to buy LPT, requires approval for this contract to spend the payment amount in DAI.
    * @param _sellOrderCreator Address of sell order creator
    */
    function commitToBuyLpt(address _sellOrderCreator) public {
        LptSellOrder storage lptSellOrder = lptSellOrders[_sellOrderCreator];

        require(lptSellOrder.lptSellValue > 0, ERROR_UNINITIALISED_ORDER);
        require(lptSellOrder.buyerAddress == ZERO_ADDRESS, ERROR_SELL_ORDER_COMMITTED_TO);

        daiToken.transferFrom(msg.sender, address(this), lptSellOrder.daiPaymentValue);

        lptSellOrder.buyerAddress = msg.sender;
    }

    /*
    * @notice Claim collateral and payment after a sell order has been committed to but it hasn't been delivered by
    *         the block number specified.
    * @param _sellOrderCreator Address of sell order creator
    */
    function claimCollateralAndPayment(address _sellOrderCreator) public {
        LptSellOrder storage lptSellOrder = lptSellOrders[_sellOrderCreator];

        require(lptSellOrder.buyerAddress == msg.sender, ERROR_NOT_BUYER);
        require(lptSellOrder.deliveredByBlock < block.number, ERROR_STILL_WITHIN_LOCK_PERIOD);

        uint256 totalValue = lptSellOrder.daiPaymentValue.add(lptSellOrder.daiCollateralValue);
        daiToken.transfer(msg.sender, totalValue);
    }

    /*
    * @notice Fulfill sell order, requires approval for this contract spend the orders LPT value from the seller.
    *         Returns the collateral and payment to the LPT seller.
    */
    function fulfillSellOrder() public {
        LptSellOrder storage lptSellOrder = lptSellOrders[msg.sender];

        require(lptSellOrder.buyerAddress != ZERO_ADDRESS, ERROR_SELL_ORDER_NOT_COMMITTED_TO);

        IERC20 livepeerToken = IERC20(_getLivepeerContractAddress("LivepeerToken"));
        livepeerToken.transferFrom(msg.sender, lptSellOrder.buyerAddress, lptSellOrder.lptSellValue);

        uint256 totalValue = lptSellOrder.daiPaymentValue.add(lptSellOrder.daiCollateralValue);
        daiToken.transfer(msg.sender, totalValue);

        delete lptSellOrders[msg.sender];
    }

    function _getLivepeerContractAddress(string memory _livepeerContract) internal view returns (address) {
        bytes32 contractId = keccak256(abi.encodePacked(_livepeerContract));
        return livepeerController.getContract(contractId);
    }
}
