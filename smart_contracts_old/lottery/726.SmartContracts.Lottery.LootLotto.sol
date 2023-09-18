pragma solidity 0.4.21;

/*  
    This smart contract is intended for educational purposes only.  
    This is not an actual lottery.
    Do not use or deploy this on any live blockchain networks where value could be transfered!
    Running an illegal lottery can result in fines and incarceration depending on your jurisdiction.
*/

contract LootLotto {

    address addr;
    uint jackpot;
    uint ticketPrice;
    uint maxTicketsAvailable;
    uint maxEtherAmountPerPlay;
    uint endEpoch; //when the lottery will be drawn
    uint startEpoch;
    uint endContract; //when to call selfdestruct
    string name;
    string symbol;
    string version;
    string desc;
            
    bool isLocked;
    uint founderCut;
    uint officerCut;
    uint developerCut;
    uint playerCut;
    uint winnerCut;
    
    uint winningNumber ;
    
    uint totalNumberOfTicketsSold;
    
    uint numberOfTicketsForPlay;
    bool isDrawn;
    bool hasStarted;
    
    address owner;
    
    //these arrays record each indiviual entry and allow index access.
    address[] founders;
    address[] officers;    
    address[] developers;    
    address[] players; 
    address[] entries;
    address[] winners;
   
   //these mapping record each individual entry with balance.
    mapping (address => uint) playerBalances;
    mapping (address => uint) jackpotClaims;
    mapping (address => uint) founderClaims;
    mapping (address => uint) officerClaims;
    mapping (address => uint) developerClaims;
    mapping (address => uint) playerClaims;
    
    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);

      
    function getVersion() public view returns (string) {
        return version;
    }
    
    function getDescription() public view returns (string) {
        return desc;
    }
    
    function getSymbol() public view returns (string) {
        return symbol;
    }
    
    function getName() public view returns (string) {
        return name;
    }
    
    function getNumberOfTicketsForPlay() internal constant returns (uint) {
        return numberOfTicketsForPlay;
    }
    
    function getOwner() public constant returns (address) {
        return owner;
    }
    
    function getWinner(uint idx) public constant returns (address) {
        return winners[idx];
    }
    
    function getWinnerCut() public constant returns (uint) {
     return winnerCut;
    }
    
    function getFounderCut() public constant returns (uint) {
        return founderCut;
    }
    
    function getOfficerCut() public constant returns (uint) {
        return officerCut;
    }
    
    function getDevelopersCut() public constant returns (uint) {
        return developerCut;
    }
    
    function getPlayersCut() public constant returns (uint) {
        return playerCut;
    }
    
    function getEntryCount() public constant returns (uint) {
        return entries.length;
    }
    
    function getWinningNumber() public constant returns (uint) {
        return winningNumber;
    }
    
    function getCurrentTime() public constant returns (uint) {
        return now;
    }
    
    function lotteryIsDrawn() public constant returns (bool) {
        return isDrawn;
    }
    
    function lotteryIsLocked() public constant returns (bool) {
        return isLocked;
    }
    
    function lotteryHasStarted() public constant returns (bool) {
        return hasStarted;
    }
    
    function getJackpot() public constant returns (uint) {
        return winnerCut;
    }
    
    function getContractBalance() public constant returns (uint) {
        return address(this).balance;
    }
    
    function isFounder(address verify_address) public constant returns (bool) {
        for(uint f=0; f<founders.length; f++){
          if(founders[f] == verify_address) {
              return true;
          }
        }
        return false;
    }
    
    
    function LootLotto() public {
        owner = msg.sender;
        founders.push(msg.sender);
        officers.push(msg.sender);
        developers.push(msg.sender);


        
        name = "Loot Lotto";
        symbol = "LOLO";
        version = "0.1";
        desc = "Etherum based blockchain lottery.";
        
        founderCut = 0;
        officerCut = 0;
        developerCut = 0;
        playerCut = 0;
        winnerCut = 0;
        
        winningNumber = 0;
        
        //operational
        totalNumberOfTicketsSold = 0;
        numberOfTicketsForPlay = 0;
        
        //4 finney, .04 ether
        ticketPrice = 4000000000000000 wei;
        
        //200 finney, .2 ether
        maxEtherAmountPerPlay = 200000000000000000 wei;
        
        isDrawn = false;
        maxTicketsAvailable = 1000000000;
        isLocked = false;

    }
    
    function () public payable {
        require(!isDrawn);
        require(!isLocked);
        require(hasStarted);
        BuyTicket();
    }
    
    function BuyTicket() public payable {
        require(!isDrawn);
        require(!isLocked);
        require(hasStarted);
        
        //keep track of how much each player has spent.
        playerBalances[msg.sender] += msg.value;
        
        numberOfTicketsForPlay =  (msg.value / ticketPrice);
        for(uint play=0;play <= numberOfTicketsForPlay -1; play++){
             entries.push(msg.sender);
        }
    }
    
    function Draw(uint randomNumber) public {
        require(isDrawn==false);
        require(isLocked==false);
        require(randomNumber <= entries.length);
        isLocked=true;
        
        uint contractBalance = getContractBalance();
        winnerCut = (contractBalance / 100) * 75;
        founderCut = (contractBalance /100) * 15;
        officerCut = (contractBalance / 100) * 6;
        developerCut = (contractBalance / 100) * 3;
        playerCut = (contractBalance / 100) * 1;
        
        //totalNumberOfTicketsSold = (contractBalance / ticketPrice);
        
        //this is not recommended approach to random numbers.  See oraclize.
        //winningNumber = uint(block.blockhash(block.number-1))%totalNumberOfTicketsSold + 1;
        winningNumber = randomNumber;
        
          //fix this
        winners.push(entries[winningNumber]);
        
        endEpoch = now;
        isDrawn = true;
    }
    
    function ClaimJackpot() public payable {
      require(isDrawn);
      require(jackpotClaims[msg.sender] == 0);
      jackpotClaims[msg.sender] = (winnerCut / winners.length);
      msg.sender.transfer(jackpotClaims[msg.sender]);
    }
    
    function ClaimPlayerShare() public payable {
      require(isDrawn);
      require(playerClaims[msg.sender] == 0);
      playerClaims[msg.sender] = (playerCut / players.length);
      msg.sender.transfer(playerClaims[msg.sender]);
    }
    
    function ClaimFounderShare() public payable {
      require(isDrawn);
      require(founderClaims[msg.sender] == 0);
      founderClaims[msg.sender] = (founderCut / founders.length);
      msg.sender.transfer(founderClaims[msg.sender]);
    }
    
    function ClaimOfficersShare() public payable {
      require(isDrawn);
      require(officerClaims[msg.sender] == 0);
      officerClaims[msg.sender] = (officerCut / officers.length);
      msg.sender.transfer(officerClaims[msg.sender]);    }
    
    function ClaimDevelopersShare() public payable {
      require(isDrawn);
      require(developerClaims[msg.sender] == 0);
      developerClaims[msg.sender] = (developerCut / developers.length);
      msg.sender.transfer(developerClaims[msg.sender]);
    }
   
    function StartLottery(uint _lotteryDurationEpoch, uint _lotteryLifetimeEpoch) public payable {
        require(!isDrawn);
        require(msg.sender == owner);
        hasStarted = true;
        
        startEpoch = now;
        endEpoch = startEpoch + _lotteryDurationEpoch;
        endContract = startEpoch + _lotteryLifetimeEpoch;
    } 
    
    function DestroyLottery() public payable {
      //after 30 day of a completed lottery, tranfer any unclaimed balances and destroy the contract.
      require(isDrawn);
      require(msg.sender == owner);
    
      if((endEpoch + 2629743) > now) {
        owner.transfer(address(this).balance);
        selfdestruct(address(this));
      }
    }
    
    function BuyLottery(address _newOwner) public payable {
        require(msg.value > 200 ether);
        owner.transfer(msg.value);
        owner = _newOwner;
    }
    
    function addFounder(address _address) public {
        require(msg.sender == owner);
        require(!hasStarted); //we cannot change stakeholders after the lottery has started.
        founders.push(_address);
    }

    function addOfficer(address _address) public {
        require(msg.sender == owner);
        require(!hasStarted) ;//we cannot change stakeholders after the lottery has started.
        officers.push(_address);
    }
    
    function addDeveloper(address _address) public {
        require(msg.sender == owner);
        require(!hasStarted); //we cannot change stakeholders after the lottery has started.
        developers.push(_address);
    }
}
