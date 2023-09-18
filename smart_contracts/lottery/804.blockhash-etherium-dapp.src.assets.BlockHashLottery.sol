pragma solidity ^0.5.2;

contract HashBlockLottery {
    
    struct Ticket {
        uint8 gambleNumber;
        address payable owner;
    }
    
    uint public ticketPrice = 0.015 ether;
    Ticket[] public tickets;
    uint public jackpot;
    address public chairman;
    lotteryState public state;
    uint blockNumberOnClose;
    uint8 public winningNumber;
    address payable[] public winners;
    
    enum lotteryState {Open, Closed, Finished}
    
    modifier OnlyChairman() {
        require(msg.sender == chairman, "Only the chairman can perform this");
        _;
    }
    
    constructor() public {
        chairman = msg.sender;
        state = lotteryState.Open;
    }
    
    function buyTicket(uint8 _gambledNumber) public payable {
        require(state == lotteryState.Open, "The lottery is closed");
        require(msg.value >= ticketPrice, "Paying less than the ticket price is not acceptable");
        require(_gambledNumber <= 100, "The gambled number should be 100 or lower");
        require(_gambledNumber >= 1, "The gambled number should be 1 or higher");
        
        jackpot += msg.value;
        tickets.push(Ticket(_gambledNumber, msg.sender));
    }
    
    function getTicketCount() public view returns(uint) {
        return tickets.length;
    }
    
    function closeLottery() OnlyChairman public {
        require(state == lotteryState.Open, "The lottery is already closed");
        
        blockNumberOnClose = block.number;
        state = lotteryState.Closed;
    }
    
    function revealWinners() public {
        require(state == lotteryState.Closed, "The lottery is not closed.");
        require(block.number > blockNumberOnClose, "It is too soon to reveal a winner. Please wait for the next block.");
        
        winningNumber = uint8(uint(blockhash(blockNumberOnClose))%100 + 1);
        determineWinners();
        payoutWinners();
        state = lotteryState.Finished;
    }
    
    function getWinners() view public returns(address payable[] memory) {
        require(state == lotteryState.Finished, "The winners are not revealed yet.");
        return winners;
    }
    
    function determineWinners() private {
        uint closestGamble = 1000;
        
        for(uint i = 0; i < tickets.length; i++) {
            uint distanceFromGambledNumber = abs(winningNumber-int(tickets[i].gambleNumber));
            uint distanceFromClosestNumber = abs(winningNumber-int(closestGamble));
            if(distanceFromGambledNumber < distanceFromClosestNumber) {
                closestGamble = tickets[i].gambleNumber;
                delete winners;
                winners.push(tickets[i].owner);
            } else if (distanceFromGambledNumber == distanceFromClosestNumber) {
                winners.push(tickets[i].owner);
            }
        }
    }
    
    function abs(int _number) private pure returns (uint) {
        if(_number > 0) return uint(_number);
        if(_number < 0) return uint(_number*-1);
        return uint(0);
    }
    
    function payoutWinners() private {
        if(winners.length <= 0) return;
        uint AmountForEveryWinner = jackpot / winners.length;
        for(uint i = 0; i < winners.length; i++) {
            winners[i].transfer(AmountForEveryWinner);
        }
        delete jackpot;
    }
    
    function restartLottery() public {
        require(state == lotteryState.Finished, "The lottery should be closed and the winners should be revealed first.");
        chairman = msg.sender;
        state = lotteryState.Open;
        delete winningNumber;
        delete tickets;
        delete winners;
    }
}