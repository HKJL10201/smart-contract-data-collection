// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time

pragma solidity ^0.8.3;

import "./openzeppelin-solidity/contracts/SafeMath.sol";
import "./openzeppelin-solidity/contracts/ERC20/SafeERC20.sol";
import "./openzeppelin-solidity/contracts/ERC1155/ERC1155.sol";

// Internal references
import "./ExecutionPrice.sol";
import "./interfaces/IExecutionPrice.sol";
import "./interfaces/IExecutionPriceFactory.sol";

// Inheritance
import "./interfaces/IPriceManager.sol";

contract PriceManager is IPriceManager, ERC1155 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct ExecutionPriceInfo {
        address owner;
        address contractAddress;
        uint256 price;
        uint256 index;
    }

    /* ========== CONSTANTS ========== */

    uint256 public MAX_INDEX = 10000;
    uint256 public MINT_COST = 1e20; // 100 bond tokens

    /* ========== STATE VARIABLES ========== */

    IExecutionPriceFactory public factory;

    uint256 public numberOfMints;
    mapping(uint256 => ExecutionPriceInfo) public executionPrices;
    mapping(address => uint256) public reverseLookup; // Start at index 1.

    /* ========== CONSTRUCTOR ========== */

    constructor(address _factory) ERC1155() {
        require(_factory != address(0), "PriceManager: invalid address for factory.");

        factory = IExecutionPriceFactory(_factory);
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Calculates the price of an ExecutionPrice NFT, given its index.
     * @param _index index of the ExecutionPrice NFT.
     */
    function calculatePrice(uint256 _index) public view override returns (uint256) {
        require (_index > 0 && _index <= MAX_INDEX, "PriceManager: index out of range.");

        if (executionPrices[_index].price > 0) {
            return executionPrices[_index].price;
        }

        uint256 result = 1e18;
        uint256 index = _index.sub(1);
        uint256 i;

        // Check 1's digit.
        // Each iteration is 1.01^1.
        for (i = 0; i < index % 10; i++) {
            result = result.mul(101).div(100);
        }

        index = index.div(10);

        // Check 10's digit.
        // Each iteration is 1.01^10 => ~1.1046x increase.
        for (i = 0; i < index % 10; i++) {
            result = result.mul(11046).div(10000);
        }

        index = index.div(10);

        // Check 100's digit.
        // Each iteration is 1.01^100 => ~2.7048x increase.
        for (i = 0; i < index % 10; i++) {
            result = result.mul(27048).div(10000);
        }

        index = index.div(10);

        // Check 1000's digit.
        // Each iteration is 1.01^1000 => ~20959.1556x increase.
        for (i = 0; i < index % 10; i++) {
            result = result.mul(209591556).div(10000);
        }

        return result;
    }

    /**
     * @dev Checks whether the given ExecutionPrice is registered in PriceManager.
     * @param _contractAddress address of the ExecutionPrice contract.
     * @return (bool) whether the address is registered.
     */
    function executionPriceExists(address _contractAddress) public view override returns (bool) {
        return executionPrices[reverseLookup[_contractAddress]].owner != address(0);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Transfers tokens from seller to buyer.
    * @param from Address of the seller.
    * @param to Address of the buyer.
    * @param id The index of the ExecutionPrice contract.
    * @param amount Number of tokens to transfer for the given ID. Expected to equal 1.
    * @param data Bytes data
    */
    function safeTransferFrom(address from, address to, uint id, uint amount, bytes memory data) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "PriceManager: caller is not owner nor approved."
        );
        require(amount == 1, "PriceManager: amount must be 1.");
        require(from == executionPrices[id].owner, "PriceManager: only the NFT owner can transfer.");

        // Update the owner of the ExecutionPrice contract.
        factory.updateContractOwner(executionPrices[id].contractAddress, to);
        executionPrices[id].owner = to;

        _safeTransferFrom(from, to, id, amount, data);
    }

    // Prevent transfer of multiple NFTs in one transaction.
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public override {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Registers the NFT at the given index.
     * @notice Assumes parameters were checked by the calling function.
     * @param _index index of the ExecutionPrice NFT.
     * @param _owner Address of the NFT's owner.
     * @param _contractAddress Address of the ExecutionPrice associated with this NFT.
     * @param _price The price at which trades in the ExecutionPrice NFT will execute.
     */
    function register(uint256 _index, address _owner, address _contractAddress, uint256 _price) external override onlyFactory notMinted(_index) {
        _mint(_owner, _index, 1, "");

        numberOfMints = numberOfMints.add(1);
        reverseLookup[_contractAddress] = _index;
        executionPrices[_index] = ExecutionPriceInfo({
            owner: _owner,
            contractAddress: _contractAddress,
            price: _price,
            index: _index
        });

        emit Registered(_index, _owner, _contractAddress, _price);
    }

    /* ========== MODIFIERS ========== */

    modifier notMinted(uint256 _index) {
        require(executionPrices[_index].owner  == address(0), "PriceManager: already minted.");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == address(factory), "PriceManager: only the factory contract can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event Purchased(address indexed buyer, uint256 index);
    event Registered(uint256 indexed index, address owner, address contractAddress, uint256 price);
}