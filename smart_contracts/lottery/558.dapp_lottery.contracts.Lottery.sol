pragma solidity ^0.8.0;

import "./MOKToken.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Lottery is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    MOKToken public mokToken;
    address public feeAddress;
    uint256 public ticketPrice;
    uint256 public drawInterval;
    uint256 private lastDrawTime;
    uint256 public prizePool;
    uint256 private usageFees;

    mapping(address => uint256) public tickets;
    address[] public ticketEntries;

    constructor(
        MOKToken _mokToken,
        address _feeAddress,
        uint256 _ticketPrice,
        uint256 _drawInterval
    ) {
        mokToken = _mokToken;
        feeAddress = _feeAddress;
        ticketPrice = _ticketPrice;
        drawInterval = _drawInterval;

        _setupRole(OWNER_ROLE, _msgSender());
        _setRoleAdmin(MANAGER_ROLE, OWNER_ROLE);
    }

    function buyTickets(uint256 numTickets) external {
        uint256 totalPrice = ticketPrice * numTickets;
        mokToken.transferFrom(msg.sender, address(this), totalPrice);

        uint256 prizeShare = (totalPrice * 9500) / 10000;
        prizePool += prizeShare;

        uint256 feesShare = totalPrice - prizeShare;
        usageFees += feesShare;

        tickets[msg.sender] += numTickets;

        for (uint256 i = 0; i < numTickets; i++) {
            ticketEntries.push(msg.sender);
        }

        emit TicketsBought(msg.sender, numTickets);
    }

    event TicketsBought(address indexed player, uint256 numTickets);

    function drawWinner() external {
        require(hasRole(MANAGER_ROLE, msg.sender) || hasRole(OWNER_ROLE, msg.sender), "Not authorized");
        require(block.timestamp >= lastDrawTime + drawInterval, "Cannot draw yet");
        require(ticketEntries.length > 0, "No players in the lottery");

        uint256 winnerIndex = _pseudoRandom() % ticketEntries.length;
        address winner = ticketEntries[winnerIndex];

        mokToken.transfer(winner, prizePool);
        prizePool = 0;
        lastDrawTime = block.timestamp;

        for (uint256 i = 0; i < ticketEntries.length; i++) {
            tickets[ticketEntries[i]] = 0;
        }

        delete ticketEntries;

        emit WinnerDrawn(winner);
    }

    event WinnerDrawn(address indexed winner);

    function withdrawUsageFees() external {
        require(hasRole(OWNER_ROLE, msg.sender), "Not authorized");
        mokToken.transfer(feeAddress, usageFees);
        usageFees = 0;
    }

    function setTicketPrice(uint256 _ticketPrice) external {
        require(hasRole(OWNER_ROLE, msg.sender), "Not authorized");
        ticketPrice = _ticketPrice;

        emit TicketPriceSet(_ticketPrice);
    }

    event TicketPriceSet(uint256 ticketPrice);

    function _pseudoRandom() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, ticketEntries)));
    }
}
