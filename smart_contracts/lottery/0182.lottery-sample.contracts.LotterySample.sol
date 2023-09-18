// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LotterySample is ReentrancyGuard, Ownable {
    uint256 public constant ticketPrice = 0.01 ether;
    uint256 public constant ticketCommission = 0.001 ether; // commition per ticket
    uint256 public constant duration = 1 weeks; // The duration set for the lottery
    uint256 public constant maxTicketPerUser = 100; // Maximum ticket purchase by 1 address
    uint256 public expiration; // Timeout in case That the lottery was not carried out.

    uint256 public operatorTotalCommission = 0; // the total commission balance
    address public lastWinner; // the last winner of the lottery
    uint256 public lastWinnerAmount; // the last winner amount of the lottery

    mapping(address => bool) public operators; // list array of the operator lottery
    mapping(address => uint256) public winnings; // maps the winners to they winnings amount
    mapping(address => uint256) public purchaseLimits; // maps the address to their limit to buy
    address[] public tickets; //array of purchased Tickets

    // modifier to check if caller is the lottery operator
    modifier onlyOperator() {
        require((operators[msg.sender]), "Caller is not the lottery operator");
        _;
    }

    // modifier to check if caller is a winner
    modifier onlyWinner() {
        require(isWinner(), "Caller is not a winner");
        _;
    }

    // The owner of the contract and the operator is different address
    // The operator is a scheduler address that will call the drawTicket after expiration
    constructor() {
        expiration = block.timestamp + duration;
    }

    // Set Operator
    function setOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    // return all the tickets
    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    // return the amount winners received
    function getWinningsForAddress(address addr) public view returns (uint256) {
        return winnings[addr];
    }

    function buyTickets() external payable nonReentrant {
        require(block.timestamp < expiration, "The lottery is expired");
        require(msg.value % ticketPrice == 0, "the value must be multiple of");

        uint256 numOfTicketsToBuy = msg.value / ticketPrice;

        require(
            numOfTicketsToBuy <=
                (maxTicketPerUser - purchaseLimits[msg.sender]),
            "Can't buy more than the limit"
        );

        for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
            purchaseLimits[msg.sender] = purchaseLimits[msg.sender] + 1;
            tickets.push(msg.sender);
        }
    }

    function random(uint _number) private view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % _number;
    }

    function drawWinnerTicket() public onlyOperator {
        require(tickets.length > 0, "No tickets were purchased");
        
        uint256 winningTicket = random(tickets.length);

        address winner = tickets[winningTicket];
        lastWinner = winner;
        winnings[winner] += (tickets.length * (ticketPrice - ticketCommission));
        lastWinnerAmount = winnings[winner];
        operatorTotalCommission += (tickets.length * ticketCommission);
        delete tickets;
        expiration = block.timestamp + duration;
    }

    function restartDraw() public onlyOperator {
        require(tickets.length == 0, "Cannot Restart Draw as Draw is in play");

        delete tickets;
        expiration = block.timestamp + duration;
    }

    function checkWinningsAmount() public view returns (uint256) {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = winnings[winner];

        return reward2Transfer;
    }

    function withdrawWinnings() external nonReentrant onlyWinner {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = winnings[winner];
        winnings[winner] = 0;

        winner.transfer(reward2Transfer);
    }

    function refundAll() public {
        require(block.timestamp >= expiration, "the lottery not expired yet");

        for (uint256 i = 0; i < tickets.length; i++) {
            address payable to = payable(tickets[i]);
            tickets[i] = address(0);
            to.transfer(ticketPrice);
        }
        delete tickets;
    }

    function withdrawCommission() public onlyOwner {
        address payable operator = payable(msg.sender);

        uint256 commission2Transfer = operatorTotalCommission;
        operatorTotalCommission = 0;

        operator.transfer(commission2Transfer);
    }

    function isWinner() public view returns (bool) {
        return winnings[msg.sender] > 0;
    }

    function currentWinningReward() public view returns (uint256) {
        return tickets.length * ticketPrice;
    }

    function getPurchaseLimits() public view returns (uint256) {
        return maxTicketPerUser - purchaseLimits[msg.sender];
    }
}
