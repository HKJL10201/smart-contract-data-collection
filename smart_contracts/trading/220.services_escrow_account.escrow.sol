// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "IArbitrable.sol";
import "IArbitrator.sol";
import "erc-1497/IEvidence.sol";

contract Escrow is IArbitrable, IEvidence {
    //variables
    address public buyer;
    address payable public seller;
    uint256 amountDeposited;
    uint256 public price;

    enum transactionState {
        NOT_INITIATED,
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        COMPLETE,
        DISPUTE
    }
    transactionState public currentState;
    bool public isBuyerIn;
    bool public isSellerIn;

    //arbitable variables
    uint256 public value;
    IArbitrator public arbitrator;
    string public agreement;
    uint256 public createdAt;
    uint256 public constant reclamationPeriod = 3 minutes; // Timeframe is short on purpose to be able to test it quickly. Not for production use.
    uint256 public constant arbitrationFeeDepositPeriod = 3 minutes; // Timeframe is short on purpose to be able to test it quickly. Not for production use.

    error InvalidStatus();
    error ReleasedTooEarly();
    error NotPayer();
    error NotArbitrator();
    error PayeeDepositStillPending();
    error ReclaimedTooLate();
    error InsufficientPayment(uint256 _available, uint256 _required);
    error InvalidRuling(uint256 _ruling, uint256 _numberOfChoices);

    enum Status {
        Initial,
        Reclaimed,
        Disputed,
        Resolved
    }
    Status public status;

    uint256 public reclaimedAt;

    enum RulingOptions {
        RefusedToArbitrate,
        PayerWins,
        PayeeWins
    }
    uint256 constant numberOfRulingOptions = 2; // Notice that option 0 is reserved for RefusedToArbitrate.

    //modifiers

    modifier buyerOnly() {
        require(msg.sender == buyer, "Only buyer can call message");
        _;
    }

    modifier sellerOnly() {
        require(msg.sender == seller, "Only seller can call the message");
        _;
    }

    modifier escrowNotInit() {
        require(currentState == transactionState.NOT_INITIATED);
        _;
    }

    //constructor
    constructor(
        address _buyer,
        address payable _seller,
        uint256 _price,
        IArbitrator _arbitrator,
        string memory _agreement
    ) payable {
        buyer = _buyer;
        seller = _seller;
        price = _price * (1 ether);
        arbitrator = _arbitrator;
        agreement = _agreement;
        createdAt = block.timestamp;
    }

    //functions

    function initEscrow() public escrowNotInit {
        if (msg.sender == buyer) {
            isBuyerIn = true;
        }
        if (msg.sender == seller) {
            isSellerIn = true;
        }
        if (isBuyerIn && isSellerIn) {
            currentState = transactionState.AWAITING_PAYMENT;
        }
    }

    function deposit() public payable buyerOnly {
        require(currentState == transactionState.AWAITING_PAYMENT);
        require(msg.value == price, "Wrong deposited amount");
        currentState = transactionState.AWAITING_DELIVERY;
    }

    function confirmDelivery() public payable buyerOnly {
        require(
            currentState == transactionState.AWAITING_DELIVERY,
            "Cannot confirm delivery"
        );
        seller.transfer(price);
        currentState = transactionState.COMPLETE;
    }

    function returnDeposit() public payable buyerOnly {
        require(
            currentState == transactionState.AWAITING_DELIVERY,
            "Cannot withdraw at this stage"
        );
        payable(msg.sender).transfer(price);
        currentState = transactionState.COMPLETE;
    }

    //Arbitrable functions

    function releaseFunds() public {
        if (status != Status.Initial) {
            revert InvalidStatus();
        }

        if (
            msg.sender != payer &&
            block.timestamp - createdAt <= reclamationPeriod
        ) {
            revert ReleasedTooEarly();
        }

        status = Status.Resolved;
        payee.send(value);
    }

    function reclaimFunds() public payable {
        if (status != Status.Initial && status != Status.Reclaimed) {
            revert InvalidStatus();
        }

        if (msg.sender != payer) {
            revert NotPayer();
        }

        if (status == Status.Reclaimed) {
            if (block.timestamp - reclaimedAt <= arbitrationFeeDepositPeriod) {
                revert PayeeDepositStillPending();
            }
            payer.send(address(this).balance);
            status = Status.Resolved;
        } else {
            if (block.timestamp - createdAt > reclamationPeriod) {
                revert ReclaimedTooLate();
            }
            uint256 requiredAmount = arbitrator.arbitrationCost("");
            if (msg.value < requiredAmount) {
                revert InsufficientPayment(msg.value, requiredAmount);
            }
            reclaimedAt = block.timestamp;
            status = Status.Reclaimed;
        }
    }

    function depositArbitrationFeeForPayee() public payable {
        if (status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        arbitrator.createDispute{value: msg.value}(numberOfRulingOptions, "");
        status = Status.Disputed;
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        if (msg.sender != address(arbitrator)) {
            revert NotArbitrator();
        }
        if (status != Status.Disputed) {
            revert InvalidStatus();
        }
        if (_ruling > numberOfRulingOptions) {
            revert InvalidRuling(_ruling, numberOfRulingOptions);
        }

        status = Status.Resolved;
        if (_ruling == uint256(RulingOptions.PayerWins))
            payer.send(address(this).balance);
        else if (_ruling == uint256(RulingOptions.PayeeWins))
            payee.send(address(this).balance);
        emit Ruling(arbitrator, _disputeID, _ruling);
    }

    function remainingTimeToReclaim() public view returns (uint256) {
        if (status != Status.Initial) {
            revert InvalidStatus();
        }
        return
            (block.timestamp - createdAt) > reclamationPeriod
                ? 0
                : (createdAt + reclamationPeriod - block.timestamp);
    }

    function remainingTimeToDepositArbitrationFee()
        public
        view
        returns (uint256)
    {
        if (status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        return
            (block.timestamp - reclaimedAt) > arbitrationFeeDepositPeriod
                ? 0
                : (reclaimedAt + arbitrationFeeDepositPeriod - block.timestamp);
    }
}
