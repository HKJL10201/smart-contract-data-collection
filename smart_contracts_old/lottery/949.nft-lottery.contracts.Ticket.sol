// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ITicket.sol";
import "./OwnableUpgradeable.sol";

import "hardhat/console.sol";

contract Ticket is OwnableUpgradeable, ITicket {
    using SafeMath for uint256;

    uint256 public override purchaseStartBlock;
    uint256 public override purchaseEndBlock;

    uint256 public override ticketPrice;
    uint256 public override latestLotteryId;
    uint256 public override prizePool;

    uint256 public override surpriseWinnerId;
    uint256 public override lotteryWinnerId;

    string public baseURI;
    mapping(uint256 => address) public override lotteryHolders;

    event UpdatedBaseURI(string _uri);
    event BoughtTicket(address user, uint256 lotteryId);
    event DeclaredSurpriseWinner(
        address surpriseWinner,
        uint256 winningAmount,
        uint256 blockNumber
    );
    event DeclaredLotteryWinner(
        address lotteryWinner,
        uint256 winningAmount,
        uint256 blockNumber
    );

    modifier canPurchase() {
        require(
            block.number >= purchaseStartBlock &&
                block.number <= purchaseEndBlock,
            "NOT_IN_PURCHASE_BLOCK_LIMITS"
        );
        _;
    }

    modifier isPurchaseEnded() {
        require(block.number > purchaseEndBlock, "PURCHASE_NOT_ENDED_YET");
        _;
    }

    function initialize(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _ticketPrice,
        address _newOwner,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) external override initializer {
        OwnableUpgradeable.__Ownable_init();
        OwnableUpgradeable.transferOwnership(_newOwner);
        __ERC721_init(_name, _symbol);

        baseURI = _uri;
        purchaseStartBlock = _startBlock;
        purchaseEndBlock = _endBlock;
        ticketPrice = _ticketPrice;
    }

    function buyTicket() external payable override canPurchase {
        require(msg.value == ticketPrice, "NOT_ENOUGH_AMOUNT");

        latestLotteryId = latestLotteryId.add(1);

        _mint(_msgSender(), latestLotteryId);
        lotteryHolders[latestLotteryId] = _msgSender();
        prizePool = prizePool + ticketPrice;

        emit BoughtTicket(_msgSender(), latestLotteryId);
    }

    function declareSurpriseWinner() external override onlyOwner canPurchase {
        require(surpriseWinnerId == 0, "SURPRISE_WINNER_ALREADY_DECLARED");

        surpriseWinnerId = generateRandomNumber();
        address surpriseWinner = lotteryHolders[surpriseWinnerId];
        uint256 winningAmount = prizePool.div(2);

        prizePool = prizePool.sub(winningAmount);
        _transferFunds(surpriseWinner, winningAmount);

        emit DeclaredSurpriseWinner(
            surpriseWinner,
            winningAmount,
            block.number
        );
    }

    function declareLotteryWinner()
        external
        override
        onlyOwner
        isPurchaseEnded
    {
        require(lotteryWinnerId == 0, "WINNER_ALREADY_DECLARED");
        lotteryWinnerId = generateRandomNumber();

        address lotteryWinner = lotteryHolders[lotteryWinnerId];
        uint256 winningAmount = prizePool;

        prizePool = 0;
        _transferFunds(lotteryWinner, winningAmount);

        emit DeclaredLotteryWinner(lotteryWinner, winningAmount, block.number);
    }

    function setBaseURI(string memory _uri) external override onlyOwner {
        baseURI = _uri;
        emit UpdatedBaseURI(_uri);
    }

    function getSurpriseWinner()
        external
        view
        override
        returns (address winner)
    {
        return lotteryHolders[surpriseWinnerId];
    }

    function getLotteryWinner()
        external
        view
        override
        returns (address winner)
    {
        return lotteryHolders[lotteryWinnerId];
    }

    function _transferFunds(address _to, uint256 _amount) internal {
        require(_to != address(0), "ZERO_ADDRESS");
        require(address(this).balance >= _amount, "INSUFFICIENT_BALANCE");

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "TRANSFER_REVERTED");
    }

    // NOTE: This should not be used for generating random number in real world
    function generateRandomNumber() internal view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    latestLotteryId
                )
            )
        ) % latestLotteryId;

        return randomNumber.add(1);
    }

    function _baseURI()
        internal
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return baseURI;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
