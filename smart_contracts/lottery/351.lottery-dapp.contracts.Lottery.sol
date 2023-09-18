// SPDX-License-Identifier:MIT
pragma solidity 0.8.0;
contract Lottery {
    address public admin;
    uint256 public raffleCount = 0;
    mapping(uint256 => Raffle) public getRaffleByID;
    mapping(address => uint256[]) public getParticipantRaffles;

    // Raffle Data
    mapping(uint256 => mapping(address => uint256)) balance; //how much total amount  invested in a  raffle
    mapping(uint256 => mapping(address => uint256)) ticketsPurchased; // how much ticket a user bought ( total )
    mapping(uint256 => mapping(address => uint256[])) tickets; //show all ticketsID undera  user he bought
    mapping(uint256 => address[]) public raffleParticipants; //list of  perticipants for asingle raffle
    mapping(uint256 => uint256[]) public raffleTicketIDs; // list of solded Ticket  IDs  for s single raffle

    struct Raffle {
        uint256 ticketPrice;
        uint256 startTime;
        uint256 endTime;
        string raffleCategory;
        string raffleTitle;
        string raffleDescriptions;
        uint256 minimumParticipants;
        uint256 totalRaised;
        bool isTerminated;
        address winner;
        uint256 raffleID;
    }

    event TicketsPurchased(address indexed user, uint256 tickets);
    event LotteryTerminated(uint256 totalRaised, address winner);

    constructor() {
        admin = msg.sender;
    }

    modifier isTicketExistOnUser(uint256 _raffleID, uint256 _ticketID) {
        uint256[] memory usertickets = tickets[_raffleID][msg.sender];
        for (uint256 i = 0; i < usertickets.length; i++) {
            if (usertickets[i] == _ticketID) {
                _;
                return;
            }
        }
        revert();
    }
    modifier raffleExists(uint256 raffleID) {
        require(
            getRaffleByID[raffleID].ticketPrice > 0,
            "Raffle does not exist"
        );
        _;
    } 
    
    function getContractTotalBalance() external view onlyAdmin returns (uint256) {
        uint256 _balance =address(this).balance;
        return _balance;
    }
    function getContractBalance() external view onlyAdmin returns (uint256) {
        require(
            msg.sender == admin,
            "Only admin can transfer contract balance to admin"
        ); 
        uint256 totalNonTerminatedAmount = 0;
        // Iterate over all raffles and calculate the total amount from non-terminated raffles
        for (uint256 i = 0; i < raffleCount; i++) {
            Raffle storage raffle = getRaffleByID[i];
            if (!raffle.isTerminated) {
                totalNonTerminatedAmount += raffle.totalRaised;
            }
        }

        uint256 contractBalance = address(this).balance;
        uint256 withdrawableAmount = totalNonTerminatedAmount >= contractBalance
            ? 0
            : contractBalance - totalNonTerminatedAmount;
        return withdrawableAmount;
    }

    function transferBalanceToAdmin() external onlyAdmin {
        require(
            msg.sender == admin,
            "Only admin can transfer contract balance to admin"
        );
        require(address(this).balance > 0, "Contract balance is zero");

        uint256 totalNonTerminatedAmount = 0;

        // Iterate over all raffles and calculate the total amount from non-terminated raffles
        for (uint256 i = 0; i < raffleCount; i++) {
            Raffle storage raffle = getRaffleByID[i];
            if (!raffle.isTerminated) {
                totalNonTerminatedAmount += raffle.totalRaised;
            }
        }
        uint256 contractBalance = address(this).balance;
        uint256 withdrawableAmount = totalNonTerminatedAmount >= contractBalance
            ? 0
            : contractBalance - totalNonTerminatedAmount;
        require(withdrawableAmount > 0, "Not enough Amount to make a withdraw");
        address payable adminWallet = payable(admin);
        adminWallet.transfer(withdrawableAmount);
    }

    function addRaffleParticipant(uint256 _number, address _address) private {
        bool exists = false;
        for (uint256 i = 0; i < raffleParticipants[_number].length; i++) {
            if (raffleParticipants[_number][i] == _address) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            raffleParticipants[_number].push(_address);
        }
    }

    function getRaffleParticipants(uint256 _raffleID)
        public
        view
        returns (address[] memory)
    {
        return raffleParticipants[_raffleID];
    }

    function getRaffleTicketIDs(uint256 _raffleID)
        public
        view
        returns (uint256[] memory)
    {
        return raffleTicketIDs[_raffleID];
    }

    function createRaffle(
        uint256 _ticketPrice,
        uint256 _endTime,
        string memory _raffleCategory,
        string memory _raffleTitle,
        string memory _raffleDescriptions,
        uint256 _minimumParticipants
    ) public {
        require(msg.sender == admin, "Only the admin can create raffles");
        require(_ticketPrice > 0, "Ticket price must be greater than 0");
        require(
            _minimumParticipants > 0,
            "Minimum participants must be greater than 0"
        );
        uint256 _totalRaised = 0;
        uint256 _startTime = block.timestamp;
        bool _isTerminated = false;
        address _winner = address(0);
        Raffle memory newRaffle = Raffle(
            _ticketPrice,
            _startTime,
            _endTime = block.timestamp + (_endTime * 1 minutes),
            _raffleCategory,
            _raffleTitle,
            _raffleDescriptions,
            _minimumParticipants,
            _totalRaised,
            _isTerminated,
            _winner,
            raffleCount
        );
        getRaffleByID[raffleCount] = newRaffle;
        raffleCount++;
    }

    function getAllRaffles() public view returns (Raffle[] memory) {
        Raffle[] memory raffles = new Raffle[](raffleCount);
        for (uint256 i = 0; i < raffleCount; i++) {
            raffles[i] = getRaffleByID[i];
        }
        return raffles;
    }

    function timeRemaining(uint256 _raffleID)
        public
        view
        raffleExists(_raffleID)
        returns (uint256)
    {
        uint256 currentTime = block.timestamp;
        uint256 endTime = getRaffleByID[_raffleID].endTime;

        if (currentTime > endTime) {
            return 0;
        } else {
            return (endTime - currentTime);
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier duringPurchasePeriod(uint256 _raffleID) {
        uint256 startTime = getRaffleByID[_raffleID].startTime;
        uint256 endTime = getRaffleByID[_raffleID].endTime;

        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Ticket purchase period has ended"
        );
        _;
    }

    modifier lotteryNotTerminated(uint256 _raffleID) {
        bool isTerminated = getRaffleByID[_raffleID].isTerminated;
        require(!isTerminated, "Lottery has been terminated");
        _;
    }

    function purchaseTickets(uint256 _raffleID, uint256 ticketAmount)
        external
        payable
        raffleExists(_raffleID)
        duringPurchasePeriod(_raffleID)
        lotteryNotTerminated(_raffleID)
    {
        uint256 ticketPrice = getRaffleByID[_raffleID].ticketPrice;

        require(ticketAmount > 0, "Tickets must be greater than zero");
        require(
            msg.value == ticketPrice * ticketAmount,
            "Invalid amount sent(+,-)"
        );

        balance[_raffleID][msg.sender] += msg.value;
        ticketsPurchased[_raffleID][msg.sender] += ticketAmount;
        getRaffleByID[_raffleID].totalRaised += msg.value;
        addRaffleParticipant(_raffleID, msg.sender);
        for (uint256 i = 0; i < ticketAmount; i++) {
            uint256 ID = uint256(keccak256(abi.encodePacked(msg.sender, i)));
            tickets[_raffleID][msg.sender].push(ID);
            raffleTicketIDs[_raffleID].push(ID);
        }

        emit TicketsPurchased(msg.sender, ticketAmount);
    }

    function viewMyTickets(uint256 _raffleID)
        public
        view
        raffleExists(_raffleID)
        returns (uint256[] memory)
    {
        return tickets[_raffleID][msg.sender];
    }

    function viewUserParticipantOnRaffle(uint256 _raffleID)
        external
        view
        raffleExists(_raffleID)
        returns (uint256)
    {
        return balance[_raffleID][msg.sender];
    }

    struct LotteryDetails {
        Raffle raffle;
        uint256 balance;
        uint256 ticketsPurchased;
        uint256[] tickets;
    }

    function viewLotteryDetails(uint256 _raffleID)
        public
        view
        raffleExists(_raffleID)
        returns (LotteryDetails memory)
    {
        LotteryDetails memory currentLottery;
        currentLottery.raffle = getRaffleByID[_raffleID];
        currentLottery.balance = balance[_raffleID][msg.sender];
        currentLottery.ticketsPurchased = ticketsPurchased[_raffleID][
            msg.sender
        ];
        currentLottery.tickets = tickets[_raffleID][msg.sender];
        return currentLottery;
    }

    function selectWinner(uint256 _raffleID)
        public
        onlyAdmin
        raffleExists(_raffleID)
    {
        Raffle storage currentRaffle = getRaffleByID[_raffleID];
        uint256[] memory allTickets = raffleTicketIDs[_raffleID];
        require(allTickets.length > 0, "No tickets bought for this raffle");

        require(
            allTickets.length >= currentRaffle.minimumParticipants,
            "Not enough participants for this raffle"
        );

        // Select a random winner
        uint256 winnerIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp))
        ) % allTickets.length;
        address winnerAddress = address(0);
        for (uint256 i = 0; i < raffleParticipants[_raffleID].length; i++) {
            address participant = raffleParticipants[_raffleID][i];
            uint256[] memory participantTickets = tickets[_raffleID][
                participant
            ];
            for (uint256 j = 0; j < participantTickets.length; j++) {
                if (participantTickets[j] == allTickets[winnerIndex]) {
                    winnerAddress = participant;
                    break;
                }
            }
        }

        currentRaffle.winner = winnerAddress;
        currentRaffle.isTerminated = true;
        emit LotteryTerminated(currentRaffle.totalRaised, winnerAddress);
    }

    uint256[] private newTicketList;

    function cancelParticipant(uint256 _raffleID, uint256 _ticketID)
        public
        isTicketExistOnUser(_raffleID, _ticketID)
        raffleExists(_raffleID)
    {
        Raffle storage raffle = getRaffleByID[_raffleID];

        require(raffle.isTerminated == false, "Raffle Already Terminated");
        require(
            raffleParticipants[_raffleID].length < raffle.minimumParticipants,
            "Minimum Participants already Met"
        );

        uint256 ticketPrice = raffle.ticketPrice;
        balance[_raffleID][msg.sender] -= ticketPrice;
        ticketsPurchased[_raffleID][msg.sender] -= 1;

        uint256[] storage userTickets = tickets[_raffleID][msg.sender];
        uint256 ticketIndex;
        for (uint256 i = 0; i < userTickets.length; i++) {
            if (userTickets[i] == _ticketID) {
                ticketIndex = i;
                break;
            }
        }

        require(ticketIndex < userTickets.length, "Ticket not found");

        // Remove the canceled ticket from user's ticket list
        if (ticketIndex < userTickets.length - 1) {
            // Move the last ticket to the position of the canceled ticket
            userTickets[ticketIndex] = userTickets[userTickets.length - 1];
        }
        userTickets.pop();

        // Remove the canceled ticket ID from raffleTicketIDs
        uint256[] storage _raffleTicketIDs = raffleTicketIDs[_raffleID];
        for (uint256 i = 0; i < _raffleTicketIDs.length; i++) {
            if (_raffleTicketIDs[i] == _ticketID) {
                ticketIndex = i;
                break;
            }
        }

        require(ticketIndex < _raffleTicketIDs.length, "Ticket ID not found");

        // Remove the canceled ticket ID from _raffleTicketIDs
        if (ticketIndex < _raffleTicketIDs.length - 1) {
            // Move the last ticket ID to the position of the canceled ticket ID
            _raffleTicketIDs[ticketIndex] = _raffleTicketIDs[
                _raffleTicketIDs.length - 1
            ];
        }
        _raffleTicketIDs.pop();
        require(payable(msg.sender).send(ticketPrice), "Failed to send refund");
    }
}
