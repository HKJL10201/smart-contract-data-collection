 pragma solidity ^0.4.4;

contract Lottery {
    
    //represents one participation.That is, it contains info for one ticket
    struct Player{
        //hash of random numbers that is supplied by the purchasers
        bytes32 firstHashValue;
        bytes32 secondHashValue;
        bytes32 thirdHashValue;
        //ticket form such as 1 represents full ticket
        uint ticketInfo;
        //block number when ticket is bought
        uint256 blockNumber;
        //shows lottery half round index (index period of 20000)
        uint256 submissionHalfRoundIndex;
    }
    
    //represents participants that their random numbers matches hash of the these numbers
    struct PlayerRevealedInfo{
        //address of entitled to Draw
        address entitledToDrawAddres;
        //ticket form such as 1 represents full ticket
        uint ticketInfo;
        //shows lottery half round index (index period of 20000)
        uint256 revealedHalfRoundIndex;
    }
    
    //list of participants that are entitled to participate in the draw
    PlayerRevealedInfo[] public revealedList;
    
    //allows us look up all players with the Ethereum address 
    mapping(address => Player[]) players;
    
    //allows the winners with Ethereum address withdraw their reward money.it is like an account
    mapping(address => uint) prizeMap;
    
    //decides how many blocks each round will last*
    uint constant public blocksHalfRound=20000;
    
    //XOR operation result numbers of the random numbers
    uint256 public XORFirstNumber;
    uint256 public XORSecondNumber;
    uint256 public XORThirdNumber;
    
    //ticket form such as 2 represents half ticket
    uint constant fullTicket = 1;
    uint constant halfTicket = 2;
    uint constant quarterTicket = 4;
    
    //represents circulating money in the lottery
    uint256 public balance;
    
    //represents firstBlockNumber when initializing lottery
    uint256 public firstBlockNumber;
    
    //Constructor-balance sets to 0 at the creation time
    constructor() public {
      balance=0;
      firstBlockNumber=block.number;
    }
    
    //In this function, participant send hash of three random numbers (numbers appends to participant's address for each number) to the contract.
    //According to money that participant sends, ticket form is determined and submission is fired.
    function buyTicket(bytes32 firstHashValue,bytes32 secondHashValue,bytes32 thirdHashValue) public payable {
        if(msg.value>=8 finney){
            submission(firstHashValue,secondHashValue,thirdHashValue,fullTicket);
        }
        if(msg.value<8 finney && msg.value>=4 finney){
            submission(firstHashValue,secondHashValue,thirdHashValue,halfTicket);
        }
        if(msg.value<4 finney && msg.value>=2 finney){
            submission(firstHashValue,secondHashValue,thirdHashValue,quarterTicket);
        }
        if(isDrawPossible()){
            draw();
        }
    }
    
    //In this function, participant info is pushed into the mapping players in terms of participant address.
    //money that participant sends added to the lottery balance
    function submission(bytes32 firstHashValue,bytes32 secondHashValue,bytes32 thirdHashValue,uint ticketInfo) public{
        players[msg.sender].push(Player(firstHashValue,secondHashValue,thirdHashValue,ticketInfo,block.number,getLotteryHalfRoundIndex()));
        balance += msg.value;
    }
    
    //During the reveal stage phase, the participants must send in their secret integers, which are hashed 
    //and compared to their original submission.If the user does not submit a valid Numbers in time, his deposit is forfeit.
    function revealStage(uint256 firstNumber,uint256 secondNumber,uint256 thirdNumber) public {

        if(block.number-firstBlockNumber>=20000){ 
        
            bool isAllNumbersReveal=false;
            for (uint index=0; index<players[msg.sender].length; index++) {
                
                //look at whether the random numbers are completely revealed or not.
                //true reveal numbers and true submitted hashes (difference round between reveal and submitted must be 1)
                if(getLotteryHalfRoundIndex()-players[msg.sender][index].submissionHalfRoundIndex==1){
                    
                    isAllNumbersReveal=revealSecretNumberHash(firstNumber,secondNumber,thirdNumber,index);
                    //if reveal operation is successful
                    if(isAllNumbersReveal){
                        
                        //participant address that is entitled to participate in the draw is added to revealed list 
                        addRevealedInfoToList(players[msg.sender][index].ticketInfo);
                        
                        //It is OK
                        performXOROperations(firstNumber,secondNumber,thirdNumber);
                        
                        //This operation prevents that same ticket wins the lottery more than one.
                        deletePlayerFromPlayers(index);
                        break;
                    }
                    
                }
                
            }
            if(isDrawPossible()){
                draw();
            }
        }
    }
    
    //Winner is determined in this function, after all secret numbers have been successfully collected. 
    //There is no any reveal process first 20000 blocks. 
    //Ticket purchase and random number submission stage runs for a period of 20000 blocks like in the reveal stage
    //One lottery runs for a period of 40000 blocks.
    //the contract XOR's the submits numbers together and uses that as a random number to pick a winner.
    function draw() public{
            
        //at the time of drawing the lottery, submissionHalfRoundIndex is i, revealedHalfRoundIndex is i+1, currentIndex is i+2*
        // First prize,second prize and third prize are determined ,respectively XORFirstNumber, XORSecondNumber and XORThirdNumber.
        //These XORs is divided by revealedList.length to determine the index of winner in the list.
        balance = balance-firstPrizeForTicketInfo(revealedList[XORFirstNumber%revealedList.length].ticketInfo);
        //prize of the unique address added to prizeMap(like an account)
        prizeMap[revealedList[XORFirstNumber%revealedList.length].entitledToDrawAddres] +=firstPrizeForTicketInfo(revealedList[XORFirstNumber%revealedList.length].ticketInfo);
        //prevent that same ticket win the lottery more than one.
        removeWinnerFromRevealedList(XORFirstNumber%revealedList.length);
        
        if(revealedList.length>0){
            balance = balance-secondPrizeForTicketInfo(revealedList[XORSecondNumber%revealedList.length].ticketInfo);
            //prize of the unique address added to prizeMap(like an account)
            prizeMap[revealedList[XORSecondNumber%revealedList.length].entitledToDrawAddres] += secondPrizeForTicketInfo(revealedList[XORSecondNumber%revealedList.length].ticketInfo);
            //prevent that same ticket win the lottery more than one.
            removeWinnerFromRevealedList(XORSecondNumber%revealedList.length);
            
            if(revealedList.length>0){
                //the amount  that  was carried over to  the current round   from   the previous  round.
                balance = balance-thirdPrizeForTicketInfo(revealedList[XORThirdNumber%revealedList.length].ticketInfo);
                //prize of the unique address added to prizeMap(like an account)
                prizeMap[revealedList[XORThirdNumber%revealedList.length].entitledToDrawAddres] += thirdPrizeForTicketInfo(revealedList[XORThirdNumber%revealedList.length].ticketInfo);
            }
        }
        
        //In the end of the function, we delete the revealedList for the next lottery.
        delete revealedList;
            
    } 
    
    function isDrawPossible() public view returns(bool){
        return (block.number-firstBlockNumber)>=40000 && (block.number-firstBlockNumber)%20000==0 && revealedList.length>0;
    }
    
    //reveals whether hash of appending number and address matches hash that was submitted in the first stage.
    function revealSecretNumberHash(uint256 firstNumber,uint256 secondNumber,uint256 thirdNumber,uint256 index) public constant returns(bool){
        
         return getKeccakHash(firstNumber) == players[msg.sender][index].firstHashValue &&
                    getKeccakHash(secondNumber) == players[msg.sender][index].secondHashValue &&
                        getKeccakHash(thirdNumber) == players[msg.sender][index].thirdHashValue;
    
    }
    
    function getKeccakHash(uint256 num) public view returns (bytes32) {
        return keccak256(num,msg.sender);
    }
    
    //This function is used to add verified user into the revealedList
    function addRevealedInfoToList(uint ticketInfo) public {
        revealedList.length++;
        revealedList[revealedList.length-1] = PlayerRevealedInfo(msg.sender,ticketInfo,getLotteryHalfRoundIndex());
    }
    
    
    //The lottery half round index  tells us which half round we are on*
    function getLotteryHalfRoundIndex() constant public returns (uint256){
        return (block.number-firstBlockNumber)/blocksHalfRound;
    }
    
    function performXOROperations(uint256 firstNumber,uint256 secondNumber,uint256 thirdNumber) public{
        //three numbers are expose to XOR operation
        XORFirstNumber=XORFirstNumber^firstNumber^uint256(msg.sender);
        XORSecondNumber=XORSecondNumber^secondNumber^uint256(msg.sender);
        XORThirdNumber=XORThirdNumber^thirdNumber^uint256(msg.sender);
    }
    
    //It prevents that same ticket wins the lottery more than one.
    function deletePlayerFromPlayers(uint index) public{
        if (index >= players[msg.sender].length) return;
        for (uint i = index; i<players[msg.sender].length-1; i++){
            players[msg.sender][i] = players[msg.sender][i+1];
        }
        players[msg.sender].length--;
    }
    
    function removeWinnerFromRevealedList(uint index) public{
        if (index >= revealedList.length) return;
        for (uint i = index; i<revealedList.length-1; i++){
            revealedList[i] = revealedList[i+1];
        }
        revealedList.length--;
    }
    
    // determines first prize in terms of ticket info
    function firstPrizeForTicketInfo(uint ticketInfo) public view returns(uint){
        if(ticketInfo==1){
            return balance/2;
        }else if (ticketInfo==2){
            return balance/4;
        }else{
            return balance/8;
        }
    }
    
    //determines second prize in terms of ticket info
    function secondPrizeForTicketInfo(uint ticketInfo) public view returns(uint){
        if(ticketInfo==1){
            return balance/4;
        }else if (ticketInfo==2){
            return balance/8;
        }else{
            return balance/16;
        }
    }
    
    //determines third prize in terms of ticket info
    function thirdPrizeForTicketInfo(uint ticketInfo) public view returns(uint){
        if(ticketInfo==1){
            return balance/8;
        }else if (ticketInfo==2){
            return balance/16;
        }else{
            return balance/32;
        }
    }
    
    //The participant that wins the lottery withdraw the money from prizeMap whenever he/she wants via this function
    function withdraw() public {
        if(prizeMap[msg.sender]<=0 finney){
            revert();
        }else{
            uint256 prize=prizeMap[msg.sender];
            prizeMap[msg.sender]=0;
            msg.sender.transfer(prize-tx.gasprice);
        }
    }
    
    ///////////////////  TESTING PURPOSE   ///////////////////
    function getFirstBlockNumber() public view returns (uint) {
        return firstBlockNumber;
    }
    
    function getBlockNumber() public view returns (uint) {
        return block.number;
    }
    function getAccountBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getLotteryBalance() public view returns (uint) {
        return balance;
    }
    
    function isHashTrue(uint256 number,bytes32 hashNumber) public view returns(bool){
        return getKeccakHash(number)==hashNumber;
    }
    
    function getAddress() public view returns (address) {
        return this;
    }
    
 
    function getPlayer() public view returns (bytes32,uint,uint256,uint256){
         return (players[msg.sender][1].thirdHashValue,players[msg.sender][1].ticketInfo,players[msg.sender][1].blockNumber,players[msg.sender][1].submissionHalfRoundIndex); // return multiple values like this
    }
    
    function getPlayerAfterDelete() public  returns (bytes32,uint,uint256,uint256){
         deletePlayerFromPlayers(0);
         if(players[msg.sender].length >=1){
             return (players[msg.sender][0].thirdHashValue,players[msg.sender][0].ticketInfo,players[msg.sender][0].blockNumber,players[msg.sender][0].submissionHalfRoundIndex); // return multiple values like this
         }else{
             return (1,2,3,4);
         }
    }

    function getPlayerLength(address adressOfPlayer) public view returns (uint) {
        return players[adressOfPlayer].length;
    }
    
    function XORdivideFirst() public view returns (uint256) {
        return XORFirstNumber%getRevealListLength();
    }
    function XORdivideSecond() public view returns (uint256) {
        return XORSecondNumber%getRevealListLength();
    }
    
    function XORdivideThird() public view returns (uint256) {
        return XORThirdNumber%getRevealListLength();
    }
    
    
    function XORStatic() public pure returns (uint256) {
        return 3^123;
    }
    
    
    function getRevealListLength() public view returns (uint) {
        return revealedList.length;
    }
    
    function getRevealListTicketInfo() public view returns (uint) {
        return revealedList[XORThirdNumber%revealedList.length].ticketInfo;
    }
    
    function getRevealListAddress() public view returns (address) {
        return revealedList[1].entitledToDrawAddres;
    }
    
    function getPrizeMapForAddress(address prizeAddress) public view returns (uint) {
        return prizeMap[prizeAddress];
    }

    function getAddressSenderForTest() public view returns (address) {
        return msg.sender;
    }


    function getTotalBalanceForTest() public view returns (uint256) {
        return address(this).balance;
    }
    
    
}