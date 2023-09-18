// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// import './LTRToken.sol';
import './THVToken.sol';

contract Lottery is VRFConsumerBaseV2 {

    // Event
    event LotteryTicketPurchased(address indexed _purchaser, uint256 _ticketID);
    event LotteryAmountPaid(address indexed _winner, uint64 _ticketID, uint256 _amount);

    // Storage vars
    uint64 public s_ticketPrice = 50;
    uint64 public s_ticketMax = 6;
    uint64 public winningNumber;
    address public s_owner;
    uint256 public ownedTickets;
    uint256 public prize;

    // vrf vars using Rinkeby testnet
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 100000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint64 public s_randomWords;
    uint256 public s_requestId;


    // Initialize Mapping
    // Each ticket can only buy by one player, otherwise the contract won't be able to pay
    address[7] public ticketOwner;
    mapping(address => uint64) public ticketsBought;
    address[] public players;

    // ERC20 Token
    // LTRToken public token;
    THVToken public token;

    // modifier
    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    constructor(uint64 subscriptionId, THVToken _token) VRFConsumerBaseV2(vrfCoordinator) {
        // require(msg.value == 0.005 ether); // acting as a prize for winner in case there is only one player => no need if using ERC20
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

        token = _token;
        token.setApproval(msg.sender, address(this), 1000000);
        token.transferFrom(msg.sender, address(this), 1000000);

        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    // Tickets may only be purchased through the buyTickets function
    fallback() payable external {
        revert();
    }

    receive() external payable {
        // custom function code
    }

    function buyTicket(uint64 _ticket) public returns (bool) {
        // require(msg.value == s_ticketPrice);
        require(_ticket > 0 && _ticket < s_ticketMax + 1);
        require(ticketOwner[_ticket] == address(0)); // no one bought it
        require(ticketsBought[msg.sender] < s_ticketMax);

        token.setApproval(msg.sender, address(this), s_ticketPrice);
        token.transferFrom(msg.sender, address(this), s_ticketPrice);

        prize += 50;
        ownedTickets += 1;

        // Avoid reentrancy attacks
        address purchaser = msg.sender;
        players.push(purchaser);
        ticketsBought[msg.sender] += 1;
        ticketOwner[_ticket] = purchaser;

        emit LotteryTicketPurchased(purchaser, _ticket);

        return true;
    }

    function claimReward() public returns (address) {

        // Winning player
        address winner = ticketOwner[winningNumber];
        require(msg.sender == winner, "You are not winner");

        // Prevent locked funds by sending to bad address
        // Prevent reentracy
        token.setApproval(address(this), winner, prize);
        token.transfer(winner, prize);
        emit LotteryAmountPaid(winner, winningNumber, prize);

        returnReward();
        reset();

        return msg.sender;
    }

    // Lottery Picker
    function requestRandomWords() external {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256, /* s_requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = uint64((randomWords[0] % 6) + 1);
        winningNumber = s_randomWords;
    }

    // Run when there is no winner
    function returnReward() public returns (uint256) {
        uint256 totalReward = 0;
        for (uint64 i = 0; i < ticketOwner.length; i++) {
            totalReward += (ticketsBought[ticketOwner[i]] * s_ticketPrice);
        }

        token.setApproval(address(this), s_owner, totalReward);
        token.transfer(s_owner, totalReward);

        return totalReward;
    }

    function reset() private returns (bool) {
        for (uint x = 0; x < players.length; x++) {
            ticketsBought[players[x]] = 0;
        }
        delete ticketOwner;
        delete players;

        ownedTickets = 0;
        winningNumber = 0;
        prize = 0;

        return true;
    }

    function getTicketsPurchased(address _player) public view returns (uint64) {
        return ticketsBought[_player];
    }

    function getCurrentPrize() public view returns (uint256) {
        return prize;
    }

    function getWinningNumber() public view returns (uint64) {
        return winningNumber;
    }

    function getBoughtTickets() public view returns (uint) {
        return ownedTickets;
    }

    function isBought(uint64 _ticket) public view returns (bool) {
        if (ticketOwner[_ticket] == address(0)) {
            return false;
        } else {
            return true;
        }
    }
}