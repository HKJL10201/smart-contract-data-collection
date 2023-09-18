//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../WinnerPicker.sol";
import "./interface/ITicket.sol";

error Unauthorized();
error TransactionFailed();
error WinnerAlreadyChosen();
error InvalidInput();
error InvalidAmount();
error Unavailable();

/**
 * @author Asparuh Damyanov
 * @notice Upgradeable ERC721 lottery contract
 * @notice Ticket contract, which mintins tickets for a certain period of time then chooses a winner
 * @dev implemented OpenZeppelin's Beacon Proxy Pattern
 */

contract Ticket is ITicket, ERC721URIStorageUpgradeable, ReentrancyGuard {
    /**
     * Lottery Variables
     */

    WinnerPicker public WINNER_PICKER;
    uint256 public TICKET_PRICE;
    uint256 public id = 0;
    uint256 public START_BLOCK;
    uint256 public END_BLOCK;

    /**
     * Winner Variables
     */

    uint256 public bigWinnerTicketId;
    uint256 public smallWinnerTicketId;
    uint256 public smallWinnerRewardAmount;
    bool public pickedSmallWinner;
    bool public pickedBigWinner;
    bool public payedSmall;

    event WinnerChoosen(address indexed winner, uint256 indexed ticket);

    modifier fromBlock(uint256 blockNumber) {
        if (block.number < blockNumber) revert Unavailable();
        _;
    }

    modifier toBlock(uint256 blockNumber) {
        if (block.number > blockNumber) revert Unavailable();
        _;
    }

    modifier onlyWinnerPicker() {
        if (msg.sender != address(WINNER_PICKER)) revert Unauthorized();
        _;
    }

    /**
     * @notice Ticket can be initialized, for more info read on Proxy Patters
     * @dev _winnerPicked = address of VRF Consumer
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        uint64 _start,
        uint64 _end,
        uint128 _price,
        address _winnerPicker
    ) external override initializer {
        if (
            bytes(_name).length == 0 ||
            bytes(_symbol).length == 0 ||
            _price == 0 ||
            _start < block.number ||
            _end <= _start
        ) revert InvalidInput();

        __ERC721_init_unchained(_name, _symbol);

        START_BLOCK = _start;
        END_BLOCK = _end;
        TICKET_PRICE = _price;
        WINNER_PICKER = WinnerPicker(_winnerPicker);
    }

    /**
     * @notice Allows users to purchase tickets once the sale has begun and has not yet finished
     * */
    function buyTicket()
        external
        payable
        override
        fromBlock(START_BLOCK)
        toBlock(END_BLOCK)
    {
        if (msg.value != TICKET_PRICE) revert InvalidAmount();
        _purchaseTicket("");
    }

    /// @notice Allows users to purchase tickets using token uri
    /// @param _tokenUri The uri of the user's ticket pointing to an off-chain source of data
    function buyTicketWithURI(string calldata _tokenUri)
        external
        payable
        override
        fromBlock(START_BLOCK)
        toBlock(END_BLOCK)
    {
        if (msg.value != TICKET_PRICE) revert InvalidAmount();
        _purchaseTicket(_tokenUri);
    }

    /// @notice Purchases ticket for a user with an optional token uri
    /// @param _tokenUri The uri of the user's ticket pointing to an off-chain source of data
    function _purchaseTicket(string memory _tokenUri) private {
        _mint(msg.sender, id);
        if (bytes(_tokenUri).length != 0) _setTokenURI(id, _tokenUri);
        id++;
    }

    /// @notice Sends request to the vrf consumer to generate a random number for later use
    /// @dev Does not directly pick the winner, instead passes the signature of the callback function
    /// @dev that has to be invoked ones the random number is ready
    function pickWinner()
        external
        override
        fromBlock((START_BLOCK + END_BLOCK) / 2)
    {
        if (
            (block.number < END_BLOCK && pickedSmallWinner) ||
            (block.number >= END_BLOCK && pickedBigWinner)
        ) revert WinnerAlreadyChosen();

        _fundVrfConsumer();

        if (block.number < END_BLOCK) {
            WINNER_PICKER.getRandomNumber("pickSmallWinner(uint256)");
            pickedSmallWinner = true;
        } else {
            WINNER_PICKER.getRandomNumber("pickBigWinner(uint256)");
            pickedBigWinner = true;
        }
    }

    /** 
     @notice Selects the winning ticket and saves it as the lottery's small winner
     @notice Small winner will receive half (50%) of the current lottery's gathered funds
     @param _randomness Random number passed by the winner_picker contract
     @dev Winning ticket id is calculated using modulo division
     @dev Reverts if called from any contract that is not the winner picker */
    function pickSmallWinner(uint256 _randomness)
        external
        override
        onlyWinnerPicker
    {
        uint256 winningTokenId = _randomness % id;
        smallWinnerTicketId = winningTokenId;
        smallWinnerRewardAmount = address(this).balance / 2;
        emit WinnerChoosen(ownerOf(winningTokenId), winningTokenId);
    }

    /// @notice Selects the winning ticket and saves it as the lottery's big winner
    /// @param _randomness Random number passed by the winner_picker contract
    /// @dev Winning ticket id is calculated using modulo division
    /// @dev Reverts if called from any contract that is not the winner picker
    function pickBigWinner(uint256 _randomness)
        external
        override
        onlyWinnerPicker
    {
        uint256 winningTokenId = _randomness % id;
        bigWinnerTicketId = winningTokenId;
        emit WinnerChoosen(ownerOf(winningTokenId), winningTokenId);
    }

    /// @notice Transfers all gathered funds to this point from the lottery to winner
    function claimSurpriseReward()
        external
        override
        nonReentrant
        fromBlock(END_BLOCK)
    {
        address winner = ownerOf(smallWinnerTicketId);

        // checks
        if (msg.sender != winner) revert Unauthorized();
        if (payedSmall) revert();

        // effects
        payedSmall = true;

        // interaction
        (bool success, ) = msg.sender.call{value: smallWinnerRewardAmount}("");
        if (!success) revert TransactionFailed();
    }

    /// @notice Transfers all gathered funds left from the lottery to the big winner
    function claimBigReward()
        external
        override
        nonReentrant
        fromBlock(END_BLOCK)
    {
        address winner = ownerOf(bigWinnerTicketId);

        if (msg.sender != winner) revert Unauthorized();

        uint256 rewardAmount;
        if (payedSmall) {
            rewardAmount = address(this).balance;
        } else if (!payedSmall)
            rewardAmount = address(this).balance - smallWinnerRewardAmount;

        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        if (!success) revert TransactionFailed();
    }

    /** 
    @notice In order to later execute the pickWinner() function this contract needs a LINK balance
    @dev The user has to approve LINK token transfer for an amount of WINNER_PICKER.fee() before executing this function
    */
    function _fundVrfConsumer() private {
        LinkTokenInterface LINK = WINNER_PICKER.LINK_TOKEN();
        uint256 fee = WINNER_PICKER.fee();

        bool success = LINK.transferFrom(
            msg.sender,
            address(WINNER_PICKER),
            fee
        );
        if (!success) revert TransactionFailed();
    }

    /**
     * @notice Tracks whether the sale has started
     * @return bool A boolean showing whether the sale has started
     */
    function started() public view override returns (bool) {
        return block.number >= START_BLOCK;
    }

    /**
     * @notice Tracks whether the sale has finished
     * @return bool A boolean showing whether the sale has finished
     */
    function finished() public view override returns (bool) {
        return block.number > END_BLOCK;
    }
}
