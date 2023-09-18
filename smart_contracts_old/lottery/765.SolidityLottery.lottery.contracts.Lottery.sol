pragma solidity ^0.4.23;
contract Lottery {
    
    address internal owner;
    address internal winner;
    uint256 internal winningAmount;

    bool internal isActive = true;
    bool internal isClaimed = false;

    uint256 ticketPriceWei;
    uint256 payoutPerTicketWei;
    
    struct Player {
        string name;
        bool isPresent;
    }

    mapping(address => Player) players;
    
    address[] public playersAddresses;
    
    constructor(uint256 inTicketPriceWei, uint256 inPayoutPerTicketWei) public { 
        ticketPriceWei = inTicketPriceWei;
        payoutPerTicketWei = inPayoutPerTicketWei;
        owner = msg.sender; 
    }
    

    function buyTicket(string inName) public payable {    
        require(isActive, "This lottery contract is closed");
        require(msg.value == ticketPriceWei, "Player must transfer exactly the ticketPrice in Wei to buy a ticket");
        require(msg.sender != owner, "The Owner of the lottery contract cannot play");
        require(bytes(inName).length <= 8, "Player name cannot be longer than 8 chars");

        require(!players[msg.sender].isPresent, "Players can buy maximum of 1 ticket");
        
        var player = players[msg.sender];
        player.name = inName;
        player.isPresent = true;
        playersAddresses.push(msg.sender);
    }

    function drawWinner(address inWinner) public returns (string, address, uint256) {
        require(msg.sender == owner, "Only the Owner of the lottery contract can draw the winner");
        require(isActive, "This lottery contract is closed");
        isActive = false;
        
        var winningPlayer = players[inWinner];
        assert(winningPlayer.isPresent);

        winningAmount = (uint256)(playersAddresses.length * payoutPerTicketWei);
        winner = inWinner;

        return (
            winningPlayer.name,
            winner,
            winningAmount
        );
    }

    function claimWinnings() public returns (string, uint256) {
        Player memory winningPlayer = players[msg.sender];
        assert(winningPlayer.isPresent);
        require(!isClaimed, "This lotter has already been claimed");
        
        if (msg.sender == winner) {
            var name = winningPlayer.name;
            winner.transfer(winningAmount);
            isClaimed = true;
            return (name, winningAmount);
        } else {
            return ("You haven't won this time, sorry!", 0);
        }

    }

    function getPlayers() public view returns(address[]) {
        return playersAddresses;
    }

    function getTicketPriceWei() public view returns(uint256) {
        return ticketPriceWei;
    }

    function getPayoutPerTicketWei() public view returns(uint256) {
        return payoutPerTicketWei;
    }

}