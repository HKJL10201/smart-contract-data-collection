// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@iden3/contracts/ZKPVerifier.sol";
import "@iden3/contracts/lib/GenesisUtils.sol";
import "@iden3/contracts/interfaces/ICircuitValidator.sol";
import "./helpers/ByteHasher.sol";
import "./interfaces/IWorldId.sol";

contract LeP2PEscrow is AccessControl, ZKPVerifier {
    using ByteHasher for bytes;

    /// @notice Thrown when attempting to reuse a nullifier
	error AlreadyRegisteredNullifier();

    struct Order {
        address seller;
        uint256 amount;
        uint256 fiatToTokenExchangeRate;
        string iban;
        address buyer;
        string paymentProof;
    }

    event OrderCreated(uint256 id, address seller, uint256 amount, uint256 fiatToTokenExchangeRate, string iban);
    event OrderCancelled(uint256 id, string reason);
    event OrderPayed(uint256 id, address buyer, string paymentProof);
    event OrderReserved(uint256 id, address buyer);
    event OrderCompleted(uint256 id, address buyer, string paymentProof);
    event OrderReleased(uint256 id, string reason);

    mapping(uint256 => Order) public orders;
    
    bytes32 public constant ARBITRATOR_ROLE = keccak256("ARBITRATOR_ROLE");
    uint256 public nextOrderId = 1;
    IERC20 public token;
    uint256 public constant MAX_AMOUNT_NON_VERIFIED = 1000 * 1e6;

    /// @dev The World ID instance that will be used for verifying proofs
	IWorldId internal immutable _worldId;

	/// @dev The contract's external worldcoin nullifier hash
	uint256 internal immutable _worldcoinExternalNullifier;

	/// @dev The World ID group ID (always 1)
	uint256 internal immutable _worldcoinGroupId = 1;

	/// @dev Whether an address has a verified worldcoin nullifier hash. Used to guarantee that an address is a verified human
	mapping(address => uint256) internal _addressToWorldcoinNullifierHash;

    /// @dev Whether an address has a verified kyc id
    mapping(address => uint256) internal _addressToKycId;

    mapping(address => uint256) public userVolume;

    /// @dev The request ID for the transfer circuit
    uint64 public constant KYC_REQUEST_ID = 1;


	/// @param worldId_ The WorldID instance that will verify the proofs
	/// @param appId The World ID app ID
	/// @param actionId The World ID action ID
	/// @param token_ The token that will be used for payments
	constructor(IWorldId worldId_, string memory appId, string memory actionId, IERC20 token_) {
        require(address(worldId_) != address(0), "World ID address cannot be 0");
        require(bytes(appId).length > 0, "App ID cannot be empty");
        require(bytes(actionId).length > 0, "Action ID cannot be empty");
        require(address(token_) != address(0), "Token address cannot be 0");
		_worldcoinExternalNullifier = abi.encodePacked(abi.encodePacked(appId).hashToField(), actionId).hashToField();
		_worldId = worldId_;
        token = token_;
        _setupRole(ARBITRATOR_ROLE, _msgSender());
	}

    /**
    * @dev Creates an order to be published in the File Node
    * @param amount Amount of tokens to be sold
    * @param fiatToTokenExchangeRate Fiat to token exchange rate
    * @param iban IBAN of the seller
    */
    function createOrder(uint256 amount, uint256 fiatToTokenExchangeRate, string memory iban) onlyVerifiedHuman external {
        // Check that the amount to be sold is greater than 0
        require(amount > 0, "Amount must be greater than 0");
        
        // Check that the exchange rate is greater than 0
        require(fiatToTokenExchangeRate > 0, "Exchange rate must be greater than 0");
        
        // Check that the IBAN is not empty
        require(bytes(iban).length > 0, "IBAN must not be empty");

        _volumeCheckKYC(_msgSender(), userVolume[_msgSender()] + amount);

        userVolume[_msgSender()] += amount;
        
        // Create order to be published
        orders[nextOrderId] = Order({
            seller: _msgSender(),
            amount: amount,
            fiatToTokenExchangeRate: fiatToTokenExchangeRate,
            iban: iban,
            buyer: address(0),
            paymentProof: ""
        });
        
        // Emit event to be saved in the File Node
        emit OrderCreated(nextOrderId, _msgSender(), amount, fiatToTokenExchangeRate, iban);

        nextOrderId++;

        // Transfer tokens to this contract to hold them
        token.transferFrom(_msgSender(), address(this), amount);
    }
    
    function reserveOrder(uint256 id) onlyVerifiedHuman external {
        Order storage order = orders[id];
        require(order.seller != address(0), "Order does not exist");
        require(order.buyer == address(0), "Order already has a buyer");
        _volumeCheckKYC(_msgSender(), userVolume[_msgSender()] + order.amount);

        userVolume[_msgSender()] += order.amount;
        
        emit OrderReserved(id, _msgSender());
        order.buyer = _msgSender();
    }
    
    function submitPayment(uint256 id, string memory ipfsHash) external {
        Order storage order = orders[id];
        require(order.seller != address(0), "Order does not exist");
        require(_msgSender() == order.buyer, "Not the buyer");

        emit OrderPayed(id, _msgSender(), ipfsHash);
        order.paymentProof = ipfsHash;
    }
    
    function confirmOrder(uint256 id) external {
        Order storage order = orders[id];
        address buyer = order.buyer;
        uint256 amount = order.amount;

        require(order.seller != address(0), "Order does not exist");
        require(_msgSender() == order.seller, "Not the seller");
        require(buyer != address(0), "Order has no buyer");

        emit OrderCompleted(id, order.buyer, order.paymentProof);

        delete orders[id];

        token.transfer(buyer, amount);
    }
    
    function arbitrateCompleteOrder(uint256 id) external {
        Order storage order = orders[id];
        address buyer = order.buyer;
        uint256 amount = order.amount;

        require(order.seller != address(0), "Order does not exist");
        require(hasRole(ARBITRATOR_ROLE, _msgSender()), "Not an arbitrator");
        require(order.buyer != address(0), "Order has no buyer");

        emit OrderCompleted(id, order.buyer, order.paymentProof);

        delete orders[id];

        token.transfer(buyer, amount);

    }

    function cancelOrderSeller(uint256 id, string memory reason) external {
        // Retrieve the order to be cancelled
        Order storage order = orders[id];

        bool isSeller = _msgSender() == order.seller;
        bool isOrderOnSellerSide = order.buyer == address(0);
        bool isOrderExistant = order.seller != address(0);

        // Check that the order exists
        require(isOrderExistant, "Order does not exist");
        require(isSeller, "Not the seller");
        require(isOrderOnSellerSide, "Order is on buyer side");

        _cancelOrder(id, reason);
    }

    function cancelOrderArbitrator(uint256 id, string memory reason) external {
        // Retrieve the order to be cancelled
        Order storage order = orders[id];

        bool isArbitrator = hasRole(ARBITRATOR_ROLE, _msgSender());
        bool isOrderExistant = order.seller != address(0);

        // Check that the order exists
        require(isOrderExistant, "Order does not exist");

        // Check that the sender is the arbitrator
        require(isArbitrator, "Not the seller");


        _cancelOrder(id, reason);
    }

    function _cancelOrder(uint256 id, string memory reason) private {
        Order storage order = orders[id];
        address seller = order.seller;
        uint256 amount = order.amount;

        // Emit event of order cancellation to be saved in the File Node
        emit OrderCancelled(id, reason);
        

        userVolume[seller] -= order.amount;


        // Delete the order
        delete orders[id];

        // Transfer tokens back to the seller
        token.transfer(seller, amount);
    }

    
    function releaseOrderBuyer(uint256 id, string memory reason) external {
        Order storage order = orders[id];

        bool isBuyer = _msgSender() == order.buyer;
        bool isOrderExistant = order.seller != address(0);

        require(isOrderExistant, "Order does not exist");
        require(isBuyer, "Not the buyer");

        _releaseOrder(id, reason);
    }

    function releaseOrderArbitrator(uint256 id, string memory reason) external {
        Order storage order = orders[id];

        bool isArbitrator = hasRole(ARBITRATOR_ROLE, _msgSender());
        bool isOrderExistant = order.seller != address(0);

        require(isOrderExistant, "Order does not exist");
        require(isArbitrator, "Not an arbitrator");

        _releaseOrder(id, reason);
    }

    function _releaseOrder(uint256 id, string memory reason) private {
        Order storage order = orders[id];
        emit OrderReleased(id, reason);
        userVolume[order.buyer] -= order.amount;
        delete orders[id].buyer;
    }

    // World ID Verification

    /// @param signal An arbitrary input from the user, usually the user's wallet address (check README for further details)
	/// @param root The root of the Merkle tree (returned by the JS widget).
	/// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
	/// @param proof The zero-knowledge proof that demonstrates the claimer is registered with World ID (returned by the JS widget).
	function verifyAndRegister(address signal, uint256 root, uint256 nullifierHash, uint256[8] calldata proof) public {
    require(nullifierHash != 0, "Nullifier hash cannot be 0");
		// First, we make sure this person hasn't done this before
		if (_addressToWorldcoinNullifierHash[_msgSender()] != 0) revert AlreadyRegisteredNullifier();

		// We should verify the proof before registering the user, but we continue to have issues with the verifier: https://dashboard.tenderly.co/tx/polygon-mumbai/0x3767fac3d7d0f8ec50894c9b04ca93497bbf525727b54b0690a7894820640b01

		// _worldId.verifyProof(
		// 	root,
		// 	_worldcoinGroupId,
		// 	abi.encodePacked(signal).hashToField(),
		// 	nullifierHash,
		// 	_worldcoinExternalNullifier,
		// 	proof
		// );

		// We now record the user has done this, so they can't do it again (proof of uniqueness)
		_addressToWorldcoinNullifierHash[_msgSender()] = nullifierHash;
	}
    

    modifier onlyVerifiedHuman() {
        require(_addressToWorldcoinNullifierHash[_msgSender()] != 0, "Address not registered");
        _;
    }

    function _volumeCheckKYC(address user, uint256 amount) view internal {
        if(amount > MAX_AMOUNT_NON_VERIFIED) {
            require(_addressToKycId[user] != 0, "Address needs to be kycd for amounts greater than 1000");
        }
    }

    // Polygon ID Verification

    function _beforeProofSubmit(
        uint64, /* requestId */
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal view override {
        // check that the challenge input of the proof is equal to the _msgSender() 
        address addr = GenesisUtils.int256ToAddress(
            inputs[validator.getChallengeInputIndex()]
        );
        require(
            _msgSender() == addr,
            "address in the proof is not a sender address"
        );
    }

    function _afterProofSubmit(
        uint64 requestId,
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal override {
        require(
            requestId == KYC_REQUEST_ID && _addressToKycId[_msgSender()] == 0,
            "proof can not be submitted more than once"
        );

        uint256 id = inputs[validator.getChallengeInputIndex()];
        _addressToKycId[_msgSender()] = id;
    }

    function isKycVerified() external view returns (bool) {
        return _addressToKycId[_msgSender()] != 0;
    }

    function isVerifiedHuman() external view returns (bool) {
        return _addressToWorldcoinNullifierHash[_msgSender()] != 0;
    }
}
