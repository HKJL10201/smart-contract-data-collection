pragma solidity ^0.6.0;

// The lottery contract
contract Lottery {
    // The address of the contract owner
    address public owner;

    // The current round number
    uint256 public roundNumber;

    // The number of tickets that have been sold
    uint256 public ticketsSold;

    // The price of each ticket in wei
    uint256 public ticketPrice;

    // The total prize pool in wei
    uint256 public prizePool;

    // The address of the winner
    address public winner;

    // An array to store the addresses of the ticket buyers
    address[] public ticketHolders;

    // A mapping from user addresses to their ticket counts
    mapping(address => uint256) public ticketCounts;

    // An array for keys of ticket counts
    address[] public ticketCountsKeys;

    // Max tickets emittable in one round
    uint256 public maxTicketCount;

    // Temp variable for proper cancelation of tickets
    address[] private newHolders;

    // An event to log when a ticket is purchased
    event TicketPurchased(
        address indexed purchaser,
        uint256 ticketCount,
        address referrer
    );

    // An event to log when a ticket is granted to referrer
    event TicketGranted(
        address indexed purchaser,
        address indexed referrer,
        uint256 ticketCount
    );

    // An event to log when a winner is selected
    event WinnerSelected(address indexed winner, uint256 prizeAmount);

    // The constructor sets the contract owner and ticket price
    constructor(uint256 _ticketPrice, uint256 _maxTicketCount) public {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        roundNumber = 1;
        maxTicketCount = _maxTicketCount;
    }

    // A function to sell tickets to the lottery
    function buyTicket(uint256 _ticketCount, address _referrer) public payable {
        require(
            msg.value == ticketPrice * _ticketCount,
            "Incorrect ticket price"
        );
        require(
            ticketsSold + _ticketCount <= maxTicketCount,
            "There are not enough tickets available"
        );
        require(_referrer != msg.sender, "You can not refer yourself");

        for (uint256 i = 0; i < _ticketCount; i++) {
            ticketHolders.push(msg.sender);
            ticketsSold++;
            prizePool += ticketPrice;
            ticketCounts[msg.sender]++;
            ticketCountsKeys.push(msg.sender);
        }

        emit TicketPurchased(msg.sender, ticketCounts[msg.sender], _referrer);

        // Here add some tickets to referrer
        uint256 add_to_referrer = _ticketCount / 3;
        uint256 granted = 0;

        for (uint256 i = 0; i < add_to_referrer; i++) {
            if (ticketsSold > (maxTicketCount * 4) / 5) {
                // Secure that after refer there will still be tickets
                break;
            }
            ticketHolders.push(_referrer);
            ticketsSold++;
            granted++;
        }
        emit TicketGranted(msg.sender, _referrer, granted);
    }

    // A function to sell tickets to the lottery
    function buyTicket(uint256 _ticketCount) public payable {
        require(
            msg.value == ticketPrice * _ticketCount,
            "Incorrect ticket price"
        );
        require(
            ticketsSold + _ticketCount <= maxTicketCount,
            "There are not enough tickets available"
        );

        for (uint256 i = 0; i < _ticketCount; i++) {
            ticketHolders.push(msg.sender);
            ticketsSold++;
            prizePool += ticketPrice;
            ticketCounts[msg.sender]++;
            ticketCountsKeys.push(msg.sender);
        }

        emit TicketPurchased(msg.sender, ticketCounts[msg.sender], address(0));
    }

    // A function to select a winner and distribute the prize
    function selectWinner() public payable {
        require(msg.sender == owner, "Only the owner can select a winner");
        require(
            ticketsSold > 0,
            "There must be at least one ticket sold to select a winner"
        );

        // Select a random ticket holder as the winner
        uint256 randomIndex = random();
        winner = ticketHolders[randomIndex];

        // Transfer the prize to the winner
        payable(winner).transfer(prizePool);

        emit WinnerSelected(winner, prizePool);

        // Start a new round
        roundNumber++;
        ticketsSold = 0;
        prizePool = 0;
        ticketHolders = new address[](0);
        for (uint256 i = 0; i < ticketCountsKeys.length; ++i) {
            ticketCounts[ticketCountsKeys[i]] = 0;
        }
        ticketCountsKeys = new address[](0);
        winner = address(0);
    }

    // A function to get a random number in the range 0 to the number of tickets sold
    function random() private view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(now, ticketHolders))) %
            ticketsSold;
    }

    function cancelTicketPurchase(uint256 _ticketCount) public {
        // Check if the winner has been selected
        require(
            winner == address(0),
            "Cannot cancel ticket purchase because winner has already been selected"
        );

        // Check if the caller has enough tickets to cancel
        require(
            ticketCounts[msg.sender] >= _ticketCount,
            "Cannot cancel ticket purchase because caller does not have enough tickets"
        );

        // Refund the ticket purchase value to the caller
        msg.sender.transfer(ticketPrice * _ticketCount);

        // Update the ticket count for the caller
        ticketCounts[msg.sender] -= _ticketCount;

        // Update the ticket count and prize pool
        ticketsSold -= _ticketCount;
        prizePool -= ticketPrice * _ticketCount;

        uint256 already_cancelled = 0;

        for (uint256 i = 0; i < ticketHolders.length; i++) {
            if (
                ticketHolders[i] == msg.sender &&
                already_cancelled < _ticketCount
            ) {
                already_cancelled++;
                continue;
            }
            newHolders.push(ticketHolders[i]);
        }
        ticketHolders = newHolders;
        newHolders = new address[](0);
    }
}
