// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./strings.sol";

contract Escrow is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using strings for string;
    using strings for bytes32;

    uint256 private oracleFee;
    address private oracle;
    bytes32 private jobId;
    uint256 public currentBlock;

    struct Product {
        bytes32 deliveryStatus;
        Stage stage;
        uint256 id;
        uint256 price;
        uint256 lockPeriod;
        address owner;
        address buyer;
        // IERC20 currency;
        string trackingId;
        string name;
        string productURI;
    }

    enum Stage {
        Initiate,
        WaitForShipping,
        Shipping,
        Delivered,
        End
    }

    Product public product;

    event OrderInitiate(address indexed _buyer);
    event OrderCancel(address indexed _buyer);

    event ShipmentInprogress(string trackingNo);
    event ShipmentUpdated(bytes32 status);
    event OrderCompleted(string trackingNo);

    modifier validStage(Stage _stage, string memory message) {
        require(product.stage == _stage, message);
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == product.buyer, "Only Buyer");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == product.owner, "Only Owner");
        _;
    }

    constructor() {
        product.owner = msg.sender;
    }

    function init(
        string memory _name,
        bytes32 _jobId,
        address _link,
        address _oracle,
        address _seller,
        uint256 _id,
        uint256 _price,
        uint256 _lockPeriod,
        uint256 _oracleFee
    ) external onlyOwner {
        // setPublicChainlinkToken();
        setChainlinkToken(_link);
        oracle = _oracle;
        jobId = _jobId;
        oracleFee = _oracleFee;

        product.id = _id;
        product.lockPeriod = _lockPeriod;
        product.name = _name;
        product.stage = Stage.Initiate;
        product.owner = _seller;
        product.price = _price;
    }

    function setProductURI(string memory _productURI) public onlyOwner {
        product.productURI = _productURI;
    }

    function order()
        external
        payable
        validStage(Stage.Initiate, "Already have a buyer")
    {
        require(msg.sender != product.owner, "You can not buy from yourself");
        require(msg.value >= product.price, "Not enough fund");
        product.stage = Stage.WaitForShipping;
        product.buyer = msg.sender;
        currentBlock = block.number;
        // currency.transferFrom(msg.sender, address(this), price);
        emit OrderInitiate(product.buyer);
    }

    function isAbleToCancelOrder() public view returns (bool) {
        return
            block.number >= currentBlock + product.lockPeriod &&
            product.stage == Stage.WaitForShipping;
    }

    function isDeliveredFail() public view returns (bool) {
        return
            product.stage == Stage.Shipping &&
            product.deliveryStatus.bytes32ToString().compareStrings(
                "Exception"
            );
    }

    function cancelOrder() external onlyBuyer {
        require(isAbleToCancelOrder(), "Not allowed to cancel order");
        product.buyer = address(0);
        product.stage = Stage.Initiate;
        // currency.transfer(msg.sender, price);
        payable(msg.sender).transfer(address(this).balance);
        emit OrderCancel(msg.sender);
    }

    function updateShipment(string memory _trackingId)
        external
        onlyOwner
        validStage(Stage.WaitForShipping, "Invalid Stage")
    {
        require(bytes(_trackingId).length > 0, "trackingId must not empty");
        product.stage = Stage.Shipping;
        product.trackingId = _trackingId;
        emit ShipmentInprogress(product.trackingId);
    }

    function requestShippingDetail()
        external
        validStage(Stage.Shipping, "Need shipment")
    {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillShippingDetail.selector
        );

        req.add("trackingId", product.trackingId);
        bytes32 requestId = sendChainlinkRequestTo(oracle, req, oracleFee);
        emit ChainlinkRequested(requestId);
    }

    function fulfillShippingDetail(bytes32 _requestId, bytes32 _deliveryStatus)
        public
        recordChainlinkFulfillment(_requestId)
    {
        product.deliveryStatus = _deliveryStatus;
        if (_deliveryStatus.bytes32ToString().compareStrings("Delivered")) {
            product.stage = Stage.Delivered;
        }

        emit ShipmentUpdated(_deliveryStatus);
    }

    function reclaimBuyer(bool _reclaim) external onlyBuyer {
        require(isDeliveredFail(), "Delivered in progress");
        if (_reclaim) {
            payable(msg.sender).transfer(address(this).balance);
            product.stage = Stage.Initiate;
            product.buyer = address(0);
        } else {
            // let's seller resend the product again
            product.stage = Stage.WaitForShipping;
        }

        product.deliveryStatus = "";
    }

    function reclaimFund()
        external
        onlyOwner
        validStage(Stage.Delivered, "Invalid Stage")
    {
        // currency.transfer(msg.sender, address(this).balance);
        product.stage = Stage.End;
        payable(msg.sender).transfer(address(this).balance);
    }
}
