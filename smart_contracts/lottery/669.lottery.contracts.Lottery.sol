pragma solidity 0.5.8;

contract Lottery {
    
    address payable public manager;
    address[] public players;
    uint public totalPlayers;
    uint public pot;
    address public winner;
    bool public lotteryHasFinished;
    uint public fee;
    
    uint public lotteryStartTime;
    uint public backUpTime;
    
   
    constructor() public{
        manager = msg.sender;
        lotteryHasFinished = false;
        //Manager's fee
        fee = 1 ether;
        backUpTime = 1 hours;
    }
    
    function enter() public payable {
        require(lotteryHasFinished == false, 'Lottery has finished');
        require(msg.value == 1 ether, 'You need to sent exactly 1 ether');
        totalPlayers = players.push(msg.sender);
        
        //Lottery starts when it receives the first payment
        if(totalPlayers == 1) lotteryStartTime = now;
        
        //Add value sent to pot
        pot += msg.value;
    }
    
    function pickWinner() public{
        //If manager calls the function or has passed 1 day since start of lottery
        require(msg.sender == manager || lotteryHasFinished == true, 'Cannot pick winner yet');
        require(totalPlayers > 3, 'Not enough Players have played');
        require(winner == address(0), 'Already picked a winner');
        
        //Pick a random number between 0 and total players
        uint randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % totalPlayers;

        //Retrieve winner
        winner = players[randomNum];

        lotteryHasFinished = true;
    }
    
    function claimWinnings() public {
        require(lotteryHasFinished == true, 'Lottery has not Finished yet');
        require(msg.sender == winner, 'You are not the winner of the Lottery');
    
        //send funds to winner minus fee
        msg.sender.transfer(pot - fee);
        
        //send remaining balance of contract to manager
        manager.transfer(address(this).balance);
        
        //reset variables when winnings are claimed
        winner = address(0);
        delete players;
        totalPlayers = 0;
        pot = 0;
        lotteryHasFinished = false;
        lotteryStartTime = 0;
    }
    
    //Back up function for players to call if manager does not end lottery
    function forceLotteryEnd() public {
        require(now > lotteryStartTime + backUpTime, 'Has not reached backup time');
        lotteryHasFinished = true;
        pickWinner();
    }
    
    function getPlayers() public view returns(address[] memory){
        return players;
    }
    
    function getLotteyFinishTime() public view returns(uint){
        return (lotteryStartTime + backUpTime);
    }
    
}