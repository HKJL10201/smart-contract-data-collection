// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address payable public receiver;
    address payable public manager;
    address payable public winner;

    uint256 public price;
    uint256 public totaltickets;
    uint256 public ticketsleft;

    receive() external payable {}

    constructor() {
        receiver = payable(address(this));
        manager = payable(msg.sender);
    }

    function getManager() external view returns (address) {
        return manager;
    }

    function getReceiver() external view returns (address) {
        return receiver;
    }

    /////////////////////////////////////////Manger-Section////////////////////////////////////////////////////////
    modifier onlyManager() {
        require(
            msg.sender == manager,
            "Only the manager can call this function."
        );
        _;
    }

    modifier onlyParticipant() {
        require(msg.sender != manager, "The manager cannot participate.");
        _;
    }

    function set(uint256 _totaltickets, uint256 _price) external onlyManager {
        require(_totaltickets >= 3, "You need to have atleast 3 tickets!");
        totaltickets = _totaltickets;
        ticketsleft = _totaltickets;
        price = (_price);
    }

    function getTickets() public view returns (uint256) {
        return totaltickets;
    }

    function getTicketsleft() external view returns (uint256) {
        return ticketsleft;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function getfundsneeded() public view returns (uint256) {
        return ((totaltickets) * (price));
    }

    /////////////////////////////////////////Participation-Section////////////////////////////////////////////////////////

    struct Participant {
        string participantName;
        address participantAddress;
        uint256 participantTime;
        uint256 participantTickets;
    }

    Participant[] participants;
    mapping(address => bool) public hasParticipated;
    address[] public frequencies;

    function participate(string memory name, uint256 tickets)
        external
        payable
        onlyParticipant
    {
        address payable buyer = payable(msg.sender);
        uint256 cost = (tickets) * (getPrice());
        require(
            hasParticipated[msg.sender] == false,
            "You have already participated!"
        );
        require(
            tickets < (getTickets() / 2),
            "You cannot buy more than half of the total tickets!"
        );
        require(cost <= buyer.balance, "Not enough balance in your account!");
        require(tickets <= ticketsleft, "Not enough tickets available!");

        uint256 extraAmount = (msg.value) - (cost);
        (buyer).transfer(extraAmount);
        Participant memory object = Participant(
            name,
            msg.sender,
            block.timestamp,
            tickets
        );
        participants.push(object);
        hasParticipated[msg.sender] = true;
        for (uint256 i = 0; i < tickets; i++) {
            frequencies.push(msg.sender);
        }
        ticketsleft = ticketsleft - tickets;
    }

    function getParticipants() external view returns (Participant[] memory) {
        return participants;
    }

    /////////////////////////////////////////Winner-Section////////////////////////////////////////////////////////

    function reset() public {
        for (uint256 i = 0; i < participants.length; i++) {
            hasParticipated[participants[i].participantAddress] = false;
        }
    }

    function withdrawFunds() public payable returns (string memory) {
        for (uint256 i = 0; i < participants.length; i++) {
            Participant storage object = participants[i];
            address payable buyer = payable(object.participantAddress);
            uint256 ticketsbought = object.participantTickets;
            uint256 withdrawAmount = (ticketsbought) * (getPrice());

            if (withdrawAmount > 0) {
                buyer.transfer(withdrawAmount);
                object.participantTickets = 0;
            }
        }

        reset();
        ticketsleft = totaltickets;
        delete participants;
        delete frequencies;
        winner = payable(address(0));
        return "Not all tickets were sold!";
    }

    function getRandom() internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, manager, receiver))
            );
    }

    function payWinner() public {
        uint256 range = frequencies.length;
        uint256 random = getRandom();
        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(random, block.number, msg.sender))
        ) % range;
        uint256 winnerIndex = randomIndex;
        winner = payable(frequencies[winnerIndex]);
        uint256 winningAmount = (address(this).balance) / 2;
        uint256 leftAmount = (address(this).balance) - winningAmount;
        winner.transfer(winningAmount);
        manager.transfer(leftAmount);
        reset();
        ticketsleft = totaltickets;
        delete participants;
        delete frequencies;
    }

    function getWinner() external view onlyManager returns (address) {
        return winner;
    }

    /////////////////////////////////////////Decision-Section////////////////////////////////////////////////////////

    function decide() external onlyManager {
        require(participants.length!=0,"No one has participated yet!");
        if (address(this).balance == getfundsneeded()) {
            payWinner();
        } else {
            withdrawFunds();
        }
    }
}

//1000000000000000000
