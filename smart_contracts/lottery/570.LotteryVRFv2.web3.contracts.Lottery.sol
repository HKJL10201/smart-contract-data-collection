// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

/**
 * @dev Implementation of a simple lottery contract using Chainlink's VRFv2.
 *
 * NOTES: This contract is supposed to be managed programatically, without the Chainlink's VRFv2
 * Subscription Manager Web [2]. `keyHash`, `LINK_TOKEN_CONTRACT` and `VRFConsumerBaseV2` addresses
 * must be setted properly. Currently setted to Polygon's Mumbai Testnet [4].
 *
 *  References:
 *  - Generate a pseudo-random number:
 *      - [1] https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number
 *      - [2] https://vrf.chain.link/chapel
 *      - [3] https://docs.chain.link/docs/vrf-contracts/#configurations
 *  - keyHash and COORDINATOR configuration:
 *      - [4] https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
 *  - Fund a contract:
 *      - [5] https://docs.chain.link/resources/fund-your-contract/
 *  - Subscription limits:
 *      - [6] https://docs.chain.link/vrf/v2/subscription/#subscription-limits
 */
contract Lottery is VRFConsumerBaseV2, ConfirmedOwner {
    // -----------------------
    // Chainlink's VRFv2 state variables.
    // -----------------------

    // Past requests Id.
    uint256[] public _requestIdHistory;

    // Last randomWordsRequest id.
    uint256 public _lastRequestId;

    // Your subscription ID.
    uint64 _s_subscriptionId;
    error NeedToCreateASubscription();

    /**
     * Depends on the number of requested values that you want sent to the
     * fulfillRandomWords() function. Storing each word costs about 20,000 gas,
     * so 100,000 is a safe default for this example contract. Test and adjust
     * this limit based on the network that you select, the size of the request,
     * and the processing of the callback request in the fulfillRandomWords()
     * function [1].
     */
    uint32 callbackGasLimit = 100_000;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    uint16 requestConfirmations = 3;

    struct RequestStatus {
        bool _fulfilled; // whether the request has been successfully fulfilled
        bool _exists; // whether a requestId exists
        uint256[] _randomWords;
    }

    // `requestId` --> `RequestStatus`
    mapping(uint256 => RequestStatus) public s_requests;
    error InvalidRequest(uint256 requestId, bool exists);
    error UnfulfilledRequest(uint256 requestId, bool fulfilled);

    // keyHash and COORDINATOR configuration [4].
    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    VRFCoordinatorV2Interface COORDINATOR;

    LinkTokenInterface LINKTOKEN;
    error InsufficientBalance();
    address private constant LINK_TOKEN_CONTRACT =
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // -----------------------
    // Lottery state variables.
    // -----------------------
    // Cost of each token. Note that 1 ether = 1000000000 gwei = 1000000000000000000 wei.
    // FIXME: Set a proper COST.
    uint256 private constant COST = (1 ether / 100);
    error InsufficientAmount(uint256 payedAmount, uint256 toPay);

    // Maximum supply of the collection.
    // FIXME: Set a proper MAX_SUPPLY.
    uint256 private constant MAX_SUPPLY = 5;
    error MaxSupplyExceeded();

    // Stores all the purchased tickets.
    uint256 private _allTokens;
    error NoPlayersInGame();

    // Lottery id.
    uint256 public _lotteryId = 1;

    // Lottery history.
    // `_lotteryId` --> winner
    mapping(uint256 => address) public _lotteryHistory;
    error InvalidLotteryHistory(uint256 lotteryId, address winner);

    // Mapping to determine the ownership of a ticket in a certain `_lotteryId`.
    // `_lotteryId` --> player
    mapping(uint256 => mapping(uint256 => address))
        private _ticketOwnershipHistory;

    // Mapping to determine the tickets of a certain address in a certain `_lotteryId`.
    // `_lotteryId` --> tickets[]
    mapping(uint256 => mapping(address => uint256[]))
        private _ticketByOwnerHistory;

    // Lets you know wether the mint is paused or not.
    bool public _isPaused = true;
    error OnlyCallableIfPaused();
    error MintPaused();

    // FIXME: Set a proper `_liquidity`, if applicable.
    address private _liquidity = 0xfaeAD884FDaDA5B42E8fdd61EdF6286E7FC61b0A;

    // Array to store (in order) the players.
    address[] private _players;

    // -----------------------
    // Constructor
    // -----------------------
    constructor()
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        LINKTOKEN = LinkTokenInterface(LINK_TOKEN_CONTRACT);
    }

    // Events.
    // -----------------------
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event SetWinnerAddress(address);
    event SuccessfulPayment(bool);

    // Modifiers.
    // -----------------------
    /**
     * @dev Checks that the lottery does not exist and so, it is not finished.
     */
    modifier onlyIfLotteryNotEnded() {
        uint256 lotteryId = _lotteryId;
        if (_lotteryHistory[lotteryId] != address(0)) {
            revert InvalidLotteryHistory(lotteryId, _lotteryHistory[lotteryId]);
        }
        _;
    }

    /**
     * @dev Checks that the lottery is paused.
     */
    modifier onlyIfIsPaused() {
        if (!_isPaused) {
            revert OnlyCallableIfPaused();
        }
        _;
    }

    // External.
    // -----------------------
    /**
     * @dev Top up a Chainlink's VRFv2 subscription.
     * @param amount uint256 Amount of LINK to send to the COORDINATOR.
     *
     * Requirements:
     *
     * - {onlyOwner} modifier.
     * getLINKBalance() must be greater than 0.
     *
     * Note: 1000000000000000000 = 1 LINK
     */
    function topUpSubscription(uint256 amount) external onlyOwner {
        if (getLINKBalance() <= 0) {
            revert InsufficientBalance();
        }

        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(_s_subscriptionId)
        );
    }

    /**
     * @dev Adds a consumer contract to the subscription.
     * @param consumerAddress address Consumer address.
     *
     * Requirements:
     *
     * - {onlyOwner} modifier.
     * - _s_subscriptionId must not be 0. This implies that there is no subscription.
     */
    function addConsumer(address consumerAddress) external onlyOwner {
        if (_s_subscriptionId == 0) {
            revert NeedToCreateASubscription();
        }

        COORDINATOR.addConsumer(_s_subscriptionId, consumerAddress);
    }

    /**
     * @dev Removes a consumer contract from the subscription.
     * @param consumerAddress address Consumer address.
     *
     * Requirements:
     *
     * - {onlyOwner} modifier.
     */
    function removeConsumer(address consumerAddress) external onlyOwner {
        COORDINATOR.removeConsumer(_s_subscriptionId, consumerAddress);
    }

    /**
     * @dev Cancel the subscription and send the remaining LINK to an address.
     * @param receivingWallet address Address that receives the remaining funds.
     *
     * Requirements:
     *
     * - {onlyOwner} modifier.
     */
    function cancelSubscription(address receivingWallet) external onlyOwner {
        COORDINATOR.cancelSubscription(_s_subscriptionId, receivingWallet);
        _s_subscriptionId = 0;
    }

    /**
     * @dev Transfer this contract's funds to an address.
     * @param amount uint256 Amount of LINK to send to `to`.
     * @param to address Receiver address.
     *
     * Requirements:
     *
     * - {onlyOwner} modifier.
     *
     * Note: 1000000000000000000 = 1 LINK
     */
    function withdraw(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }

    /**
     * @dev Submits the request to the VRF coordinator contract. See [1].
     *
     * Requirements:
     *
     * - {onlyOwner} modifier.
     * - {onlyIfIsPaused} modifier.
     * - The subscription must be sufficiently funded.
     */
    function requestRandomWords()
        external
        onlyOwner
        onlyIfIsPaused
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            _s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_requests[requestId] = RequestStatus({
            _randomWords: new uint256[](0),
            _exists: true,
            _fulfilled: false
        });

        _requestIdHistory.push(requestId);
        _lastRequestId = requestId;

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    /**
     * @dev Retrive request details for a given requestId. See [1].
     * @param requestId uint256 Request id to Chainlink's VRFv2 oracle.
     *
     * Requirements:
     *
     *  - {onlyOwner} modifier.
     *  - requestId must exist.
     */
    function getRequestStatus(
        uint256 requestId
    )
        external
        view
        onlyOwner
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        RequestStatus memory request = s_requests[requestId];

        if (!request._exists) {
            revert InvalidRequest(requestId, request._exists);
        }

        return (request._fulfilled, request._randomWords);
    }

    // Public.
    // -----------------------
    /**
     * @dev Change status of the boolean _isPaused.
     *
     * Requirements:
     *
     *  - {onlyOwner} modifier.
     */
    function playPause() public onlyOwner {
        _isPaused = !_isPaused;
    }

    /**
     * @dev Returns the current total supply.
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens;
    }

    /**
     * @dev Function that lists the amount of tickets given a lottery id and an address.
     * @param lotteryId uint256 ID of the lottery.
     * @param owner address Address of the tickets.
     */
    function ticketAmountByLotteryIdAndAddress(
        uint256 lotteryId,
        address owner
    ) public view returns (uint256) {
        return _ticketByOwnerHistory[lotteryId][owner].length;
    }

    /**
     * @dev Function that returns the address of a given ticket in a certain lotteryId.
     * @param lotteryId uint256 ID of the lottery.
     * @param ticketId uint256 Ticket ID.
     */
    function ticketOwnershipByLotteryIdAndTicketId(
        uint256 lotteryId,
        uint256 ticketId
    ) public view returns (address) {
        return _ticketOwnershipHistory[lotteryId][ticketId];
    }

    /**
     * @dev Function that lists the tickets given a lottery id and an address.
     * @param lotteryId uint256 ID of the lottery.
     * @param owner address Address of the tickets.
     */
    function ticketByLotteryIdAndAddress(
        uint256 lotteryId,
        address owner
    ) public view returns (uint256[] memory) {
        return _ticketByOwnerHistory[lotteryId][owner];
    }

    /**
     * @dev Function that allows minting a set of loto tickets.
     * @param amount uint256 Amount of tickets to mint.
     *
     * Requirements:
     *
     *  - {onlyIfLotteryNotEnded} modifier.
     *  - amount must be greater than 0, i.e., a minimum purchase of 1 unit.
     *  - amount must not exceed the MAX_SUPPLY.
     */
    function mint(uint256 amount) public payable onlyIfLotteryNotEnded {
        if (_isPaused) {
            revert MintPaused();
        }

        uint256 allTokens = totalSupply();
        require(amount > 0, "[Lottery]: The minimum amount is 1.");

        uint256 maxSupply = MAX_SUPPLY;
        if (allTokens + amount > maxSupply) {
            revert MaxSupplyExceeded();
        }

        if (msg.sender != owner()) {
            uint256 cost = COST;
            uint256 toPay = cost * amount;

            if (msg.value < toPay) {
                revert InsufficientAmount(msg.value, toPay);
            }
        }

        uint256 lotteryId = _lotteryId;
        for (uint256 i = 0; i < amount; i++) {
            _players.push(msg.sender);
            _ticketOwnershipHistory[lotteryId][allTokens + i] = msg.sender;
            _ticketByOwnerHistory[lotteryId][msg.sender].push(allTokens + i);
        }

        _allTokens += amount;
    }

    /**
     * @dev Function that computes the winner of the lottery.
     * @param salt string Deterministic string introduced by hand in order to prevent the random number
     * exploit.
     *
     * Requirements:
     *
     *  - {onlyOwner} modifier.
     *  - {onlyIfLotteryNotEnded} modifier.
     *  - Mint must be paused.
     *  - allTokens must not be 0, due to the fact that this means there are no players on the game.
     *  - The winner must hold at least 1 share.
     *  - Call functions must succeed.
     *
     * Emits {SuccessfulPayment} events.
     */
    function computeWinner(
        string memory salt
    ) public onlyOwner onlyIfLotteryNotEnded onlyIfIsPaused {
        // Retrieve in-game tokens.
        uint256 allTokens = totalSupply();

        // Check if there are players.
        if (allTokens <= 0) {
            revert NoPlayersInGame();
        }

        // Check if last request exists.
        uint256 lastRequestId = _lastRequestId;
        RequestStatus memory request = s_requests[lastRequestId];
        if (!request._exists) {
            revert InvalidRequest(lastRequestId, request._exists);
        }

        // Check if last request if fulfilled.
        if (!request._fulfilled) {
            revert UnfulfilledRequest(lastRequestId, request._fulfilled);
        }

        address[] memory players = _players;

        /**
         * Compute a random number using hash(array of random words with a deterministic salt)
         * modulo total existing supply (equal to the length of players, due to the fact that this
         * array stores the address of each purchased ticket).
         */
        uint256 random = uint256(
            keccak256(abi.encodePacked(request._randomWords, salt))
        ) % players.length;

        // Select winner address.
        address winnerAddress = players[random];
        uint256 lotteryId = _lotteryId;
        require(winnerAddress != address(0), "[Lottery]: Invalid address.");
        require(
            ticketAmountByLotteryIdAndAddress(lotteryId, winnerAddress) > 0,
            "[Lottery]: Winner balance is lower than 1."
        );
        require(
            ticketOwnershipByLotteryIdAndTicketId(lotteryId, random) ==
                winnerAddress,
            "[Lottery]: The property of the winner ticket does not match with the winner address."
        );

        // Send the prize to the winner, e.g., 90% of the total amount.
        // FIXME: Check this percentages in production.
        (bool success, ) = winnerAddress.call{
            value: (address(this).balance * 90) / 100
        }("");
        require(success, "[Lottery]: Call to Winner failed.");
        emit SuccessfulPayment(success);

        // Save the rest of the balance in a Liquidity address.
        // FIXME: Only use this if `_liquidity` variable is declared.
        (success, ) = _liquidity.call{value: address(this).balance}("");
        require(success, "[Lottery]: Call to Liquidity failed.");
        emit SuccessfulPayment(success);

        // Update and reset lottery values.
        _lotteryHistory[lotteryId] = winnerAddress;
        emit SetWinnerAddress(winnerAddress);

        _lotteryId++;
        _players = new address[](0);
        _allTokens = 0;
        _lastRequestId = 0;
    }

    /**
     * @dev Create a new subscription when the contract is initially deployed.
     *
     * Requirements:
     *
     *  - {onlyOwner} modifier.
     */
    function createNewSubscription() public onlyOwner {
        _s_subscriptionId = COORDINATOR.createSubscription();
    }

    /**
     * @dev Get this contract's LINK balance, in order to fund the COORDINATOR afterwards.
     */
    function getLINKBalance() public view onlyOwner returns (uint256) {
        return LINKTOKEN.balanceOf(address(this));
    }

    // Internal.
    // -----------------------
    /**
     * @dev Receives random values and stores them with your contract. See [1].
     * @param requestId uint256 Request id to Chainlink's VRFv2 oracle.
     * @param randomWords uint256[] Requested random wordss associated to `requestId`.
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        RequestStatus memory request = s_requests[requestId];

        if (!request._exists) {
            revert InvalidRequest(requestId, request._exists);
        }

        s_requests[requestId]._fulfilled = true;
        s_requests[requestId]._randomWords = randomWords;

        emit RequestFulfilled(requestId, randomWords);
    }
}
