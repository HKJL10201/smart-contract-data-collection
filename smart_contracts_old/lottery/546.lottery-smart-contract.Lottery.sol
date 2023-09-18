pragma solidity ^0.4.18;

contract Lottery {
    address private owner; 
    
    mapping(address => uint) balance; // stores balance of each address which attends to a lottery
    
    uint private moneyCollected; // total money collected with lottery
    enum TicketType {Full,Half,Quarter} // 3 types of ticket -> full, half, quarter
    uint[] private ticketPrices = [8 finney,4 finney,2 finney]; // corresponding prices for 3 types of tickets
   // Ticket[][] private revealedTickets; // stores tickets which are revealed by their buyers. rows of multidimensional array is for different lotteries
    //Ticket[][] private ticketList; // stores tickets which are just bought by some address. rows of multidimensional array is for different lotteries
    uint private nextTicketId; // every ticket in the contract has a unique id and the contract gets next ticket id of this variable
    Ticket winningTicket; // ticket struct which won the last lottery
    uint private initialBlockNumber; // initial block number when the contract is deployed to blockchain
    uint private constant purchaseUntilBlock = 19999; // purchase until 19999 blocks created from the beginning of current lottery 
    uint firstRandom; 
    uint secondRandom;
    uint thirdRandom;
    int revealRound=-1;
    mapping(int => Ticket[]) revealedTickets2;
    mapping(int => Ticket[]) ticketList2;
    
    struct Gambler{
        address purchaser; // address of purchaser
        uint[] ticketIds; // ids of their tickets
        uint wonPrize; // prize earned by this gambler
        bool isInitialized; // whether this gambler struct is initialized or not
    }
    struct Ticket{
        uint id; // unique id for ticket
        TicketType ticket_type; // type of ticket (full,half,quarter)
        uint num1; // first random number
        uint num2; // second random number
        uint num3; // third random number
        bytes32 hashValue; // hash value submitted by the purchaser of this ticket
        bool isRevealed; // stores whether this ticket is revealed by purchaser or not
        address owner; // address of purchaser
    }
    function Lottery() public{ // constructor for the contact
        owner = msg.sender; // owner of the contract is the sender of this contract
        moneyCollected = 0; 
        initialBlockNumber = block.number;
       
    }
    
    //debug
    function getFirstBoughtTicket(int submissionRound) public view returns(bytes32,address){
        return (ticketList2[submissionRound][0].hashValue,ticketList2[submissionRound][0].owner);
    }
    
    //debug
    function getFirstRevealedTicket(int revealRound) public view returns (uint,uint,uint,address,bool){
        Ticket memory revealedTicket = revealedTickets2[revealRound][0];
        return (revealedTicket.num1,revealedTicket.num2,revealedTicket.num3,revealedTicket.owner,revealedTicket.isRevealed);
    }
    
    //debug
    function getMoneyCollected() public view returns (uint){
        return moneyCollected;
    }
    function generateHash(uint random1,uint random2,uint random3) public view returns (bytes32){
        bytes32 hash = sha3(random1,random2,random3,msg.sender); // calculate the hash with given 3 random numbers and sender address
        return hash;
    }
    // buy a ticket by sending the sha3 hash string with inputs (random number 1, random number2, random number 3, sender address)
    function buyTicket(uint random1,uint random2,uint random3) public payable{
        bytes32 hashStr = sha3(random1,random2,random3,msg.sender);
        require(msg.value == 8 finney|| msg.value == 4 finney || msg.value == 2 finney); //ether sent with this function has to be equal to 8,4 or 2
        Ticket storage t;
        if(msg.value == 8 finney){ // if the ether sent is equal to 8 finneys, it means the purchaser wants to buy full ticket
             t.ticket_type=TicketType.Full;
             moneyCollected = moneyCollected + 8 finney;
     
        }
        else if(msg.value == 4 finney){ // if the ether sent is equal to 4 finneys, it means the purchaser wants to buy half ticket
            t.ticket_type=TicketType.Half;
            moneyCollected = moneyCollected + 4 finney;
            
        } 
        else if(msg.value == 2 finney){ // if the ether sent is equal to 2 finneys, it means the purchaser wants to buy quarter ticket
             t.ticket_type=TicketType.Quarter;
              moneyCollected = moneyCollected + 2 finney;
        
        }
        // fill the ticket struct with related info
        t.hashValue=hashStr;
        t.owner=msg.sender;
        t.isRevealed=false;
        int round = getSubmissionRound();
        ticketList2[round].push(t); // store the bought ticket to ticketList multidimensional array
       
    }
    // a ticket can be revealed by calling the function with 3 random numbers which were used in hash string sent in purchasing phase
    /*
    function revealLottery(uint random1,uint random2,uint random3) public payable{
        int round = getRevealRound(); // get the id of current reveal round
        require(round>=0);  // there is no reveal in first 20k block
        bool everReleaved;
        address sender = msg.sender;
        bytes32 revealHash = sha3(random1,random2,random3,sender); // calculate the hash with given 3 random numbers and sender address
        for(uint index = 0;index<ticketList[uint(round)].length;index++){
            if(ticketList[uint(round)][index].hashValue == revealHash && 
             ticketList[uint(round)][index].owner == sender &&
             ticketList[uint(round)][index].isRevealed==false) { // if a ticket is found with calculated hash, it means that the message sender can reveal its ticket
                 
                ticketList[uint(round)][index].isRevealed = true;
                ticketList[uint(round)][index].num1 = random1;
                ticketList[uint(round)][index].num2 = random2;
                ticketList[uint(round)][index].num3 = random3;
                everReleaved = true;
               
                firstRandom=firstRandom^random1; // xor the first random numbers
                secondRandom=secondRandom^random2; // xor the second random numbers
                thirdRandom=thirdRandom^random3; // xor the third random numbers
                revealedTickets[uint(round)].push(ticketList[uint(round)][index]); // add current revealed ticket to revealedTickets multidimensional array with id of current reveal round
                break;
            }
        }
       
    }
    */
    function getBoughtTicketForRound() public view returns(uint){
        return ticketList2[getSubmissionRound()].length;
    }
    function getRevealedTicketForRound() public view returns(uint){
        int round = getRevealRound();
        require(round>=0); 
        return revealedTickets2[round].length;
    }
    function revealLottery(uint random1,uint random2,uint random3) public{
        int round = getRevealRound();
        require(round>=0); 
         bool everReleaved;
        address sender = msg.sender;
        bytes32 revealHash = sha3(random1,random2,random3,sender); // calculate the hash with given 3 random numbers and sender address
       
        for(uint index = 0;index<ticketList2[round].length;index++){
            if(ticketList2[round][index].hashValue == revealHash && 
             ticketList2[round][index].owner == sender &&
             ticketList2[round][index].isRevealed==false) { // if a ticket is found with calculated hash, it means that the message sender can reveal its ticket
                 
                ticketList2[round][index].isRevealed = true;
                ticketList2[round][index].num1 = random1;
                ticketList2[round][index].num2 = random2;
                ticketList2[round][index].num3 = random3;
                everReleaved = true;
               
                firstRandom=firstRandom^random1; // xor the first random numbers
                secondRandom=secondRandom^random2; // xor the second random numbers
                thirdRandom=thirdRandom^random3; // xor the third random numbers
                revealedTickets2[round].push(ticketList2[round][index]); // add current revealed ticket to revealedTickets multidimensional array with id of current reveal round
                break;
            }
        }
        //revealedTickets[uint256(round)].push(t);
       }
    //choose winner by using xor'ed random numbers
    function chooseWinner() public returns(address) { 
        int round = getRevealRound();
        
        require(round>=0);  // there is no reveal in first 20k block
       
        uint count = 0;
        uint256 firstindex=uint(block.blockhash(block.number-firstRandom+count))%revealedTickets2[round].length; // calculate firstIndex
        uint256 secondindex=uint(block.blockhash(block.number-secondRandom+count))%revealedTickets2[round].length; // calculate secondIndex
       
        while (firstindex!=secondindex){ // if the first and second index are equal, then calculate second index again
            count++;
            secondindex=uint(block.blockhash(block.number-secondRandom+count))%revealedTickets2[round].length;
      
        }
        uint256 thirdindex=uint(block.blockhash(block.number-thirdRandom+count))%revealedTickets2[round].length;
        while (thirdindex!=secondindex && thirdindex != firstindex){
            count++;
            thirdindex=uint(block.blockhash(block.number-thirdRandom+count))%revealedTickets2[round].length; // if the third index is equal to first or second index, then calculate third index again
      
        }
        Ticket storage firstTicket = revealedTickets2[round][firstindex]; // get first winner ticket
        Ticket storage secondTicket = revealedTickets2[round][secondindex]; // get second winner ticket
        Ticket storage thirdTicket = revealedTickets2[round][thirdindex]; // get third winner ticket
        
        if(firstTicket.ticket_type==TicketType.Full){ // calculate prize for first winner ticket
            balance[firstTicket.owner]+=moneyCollected/2;
        }else if(firstTicket.ticket_type==TicketType.Half){
            balance[firstTicket.owner]+=moneyCollected/4;
        }else if(firstTicket.ticket_type==TicketType.Quarter){
            balance[firstTicket.owner]+=moneyCollected/8;
        }
        
        if(secondTicket.ticket_type==TicketType.Full){ // calculate prize for second winner ticket
            balance[secondTicket.owner]+=moneyCollected/4;
        }else if(secondTicket.ticket_type==TicketType.Half){
            balance[secondTicket.owner]+=moneyCollected/8;
        }else if(secondTicket.ticket_type==TicketType.Quarter){
            balance[secondTicket.owner]+=moneyCollected/16;
        }
        
        if(thirdTicket.ticket_type==TicketType.Full){ // calculate prize for third winner ticket
            balance[thirdTicket.owner]+=moneyCollected/8;
        }else if(thirdTicket.ticket_type==TicketType.Half){
            balance[thirdTicket.owner]+=moneyCollected/16;
        }else if(thirdTicket.ticket_type==TicketType.Quarter){
            balance[thirdTicket.owner]+=moneyCollected/32;
        }
        
        return winningTicket.owner;
    }
    // if any prize is won, then winner addresses can withdraw the prize
    function withdrawPrize() public{ 
        uint amount = balance[msg.sender];
        if(amount>0){
            balance[msg.sender]=0;
            moneyCollected-=amount;
            if  (!msg.sender.send(amount)){ 
                balance[msg.sender]=amount;
                moneyCollected+=amount;
            }
        }
    }
    
    function blockno() public view returns(uint){
       return block.number-initialBlockNumber;
    }
    // get current reveal round id according to created block numbers
    function getRevealRound() public view returns(int){
       int currentRound = int(((block.number-initialBlockNumber)/purchaseUntilBlock))-1;
    //   if(revealRound != currentRound){
    //       chooseWinner();
    //       revealRound=currentRound;
    //   }
       return currentRound;
    }
    // get current submission round id according to created block numbers
    function getSubmissionRound() public view returns(int){
       return int(((block.number-initialBlockNumber)/purchaseUntilBlock));
    }
    // helper function to generate hash by using three random numbers and address of message sender
     function getHash(uint u1,uint u2,uint u3) public view returns(bytes32){
       return sha3(u1,u2,u3,msg.sender);
    }
    function checkMyPrize() public view returns(uint){
        return balance[msg.sender];
    }
   
    
    
}