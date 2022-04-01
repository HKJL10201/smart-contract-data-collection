pragma solidity ^0.4.11;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract Lottery is usingOraclize {
    
    
    address public owner;
    address private winner;
    
    bool public isFunding;
    bool private numberGen;
    bool private endDrawCall;
    
    uint private proofFailed;
    uint private maxProofFail = 1;
    uint public randomNumber;
    uint private startTime;
    uint private endTime;
    uint private timeInterval;
    uint private previousDraws;
    uint private biggestWinnings;
    uint private overallWinnings;
    uint private winnerBalance;
    uint private nonce = 0;
    uint private maxRange;
    uint private minRange;
    uint private offset;
    uint private ticketPrice;
   
    struct Entry {
        uint drawID; // unique ID
        address wallet; // Entry wallet address
        bool entered;  // if true, this person already entered
    }
    
    // if applied to a function it can only be called by contract owner
    modifier onlyOwner { 
        require(msg.sender == owner);
        _;
    }
    
    mapping (address => Entry) private entries;
    address[] private entryAddresses;
    uint numAddresses = 0;
    
    //EVENTS /////////////////////////////////////////////////////////////////////////
     event DrawStarted(string message);
     event TicketBought(address from, string message); //new entry
     event EthReleased(uint256 amount, string message, address winner); //draw end
     event NoEntries(string message);
     event EntryIDLog(uint id, uint rand, uint offset);
     event OraclizeMsg(string message);
     event DrawExtended(uint timeSinceExpiry, string message);
     event Refund(uint entries, string message);
    //CONSTRUCTOR (called on contract creation) //////////////////////////////////////
    function Lottery(uint drawLengthInSeconds) public {
        owner = msg.sender;
        timeInterval = drawLengthInSeconds / 1 seconds; // draw length 604800 secs for 1 week
        startTime = now; //set startTime , now is alias for block.timestamp (seconds since unix epoch)
        endTime = startTime + timeInterval; // set endTime
        ticketPrice = 10000000000000000;//wei
        startDraw();
    }
    
    function startDraw() internal onlyOwner {
        isFunding = true; 
        numberGen = false;
        randomNumber = 0;
        startTime = now; //now is alias for block.timestamp
        endTime = startTime + timeInterval; // set endTime
        DrawStarted("Draw Started");
    }
    
      //get balance of contract
    function contractBalance() public view returns(uint) {
        address contractAddress = this;
        return contractAddress.balance;
    }
    
    //returns current block.timestamp
    function getNowTime() public view returns (uint) {
        return now;
    }
    
    //returns end time(seconds since unix epoch)
    function getEndTime() public view returns (uint) {
        return endTime;
    }
    
     //returns draw length in seconds
    function getTimeInterval() public view returns(uint) {
        return timeInterval;
    }
    
    //returns amount of time passed in seconds
    function getTimePassed() public view returns (uint) {
        require(startTime != 0);
        return (now - startTime)/(1 seconds);
    }
    
    //returns the amount of time left in seconds
    function getTimeLeft() public view returns (uint) {
        require(endTime > now);
        return (endTime - now)/(1 seconds);
    }
    
    //refund all funds back to users (precautionary measure to be used only ever in the event of a locked/broken contract)
    function fixBrokenContract() public {
        require(msg.sender == owner || proofFailed > maxProofFail);
        require(contractBalance() > 0);
        isFunding = false;
        if(tx.gasprice > msg.gas || block.gaslimit < tx.gasprice) {
        //precautionary measure in the case that tx gas price exceeds remaining gas sent
        //if so, funds will be sent to contract owner on selfdestruct. manual distribution of refund can then take place
        Refund(1, "- contract owner must start manual distribution");   //emit event
        } else {
            uint refundAmount = (contractBalance() / numAddresses);
            uint endArray = entryAddresses.length;
            uint startArray = endArray - numAddresses;
            //could be problematic after many draws / high entry amount (loops through all entries hence gasprice check)
            for (uint i = startArray; i < endArray; i++) {
                if(contractBalance() < ticketPrice) {
                    refundAmount = contractBalance();
                }
                entries[entryAddresses[i]].wallet.transfer(refundAmount);
            }
            Refund(numAddresses, "- users refunded");   //emitevent
        }
        //destroy contract
        selfdestruct(owner);
    }
    
    //fallback function in the case funds are transferred directly to the contract address(draw participation still applicable)
    function() public payable {
        buyTicket();
    }
    
    //buy lottery ticket
    function buyTicket() public payable {
        require(isFunding);
        //check if user is sending the correct amount
        require(msg.value > 0 && msg.value == ticketPrice);
        //check if user has already entered
        require(entries[msg.sender].entered == false);
        //increment number of entry addresses
        numAddresses++;
        //map user address into Entry struct
        Entry storage _ent = entries[msg.sender];
        //input data to stuct
       _ent.drawID = (numAddresses - 1);//set user ID 
       _ent.wallet = msg.sender;//set user address
       _ent.entered = true;//set has entered (used to block multiple entries from same address)
       //add user address to entryAddress array
        entryAddresses.push(msg.sender);
        TicketBought(msg.sender,"Ticket Bought, New Entry!");
        // if draw time expired, stop funding & make call to oraclize for random number generation
        if(now > endTime) {
            //if first entry is after draw expiry, extend draw runtime
            if(getEntryCount() == 1){
                uint expiredTime = now - endTime;
                startTime = now; //set new startTime , now is alias for block.timestamp (seconds since unix epoch)
                endTime = startTime + timeInterval; // set new endTime
                DrawExtended(expiredTime, "- expired draw on first entry - Draw Extended");
                expiredTime = 0;
            } else {
                OraclizeMsg("Sending Oraclize Query.");
                this.callOraclizeEndDraw();
            }
        }
    }

    //returns Entry struct data (check if specific address has entered)
    function getAddressInfo(address u) view public returns (address, bool) {
        return (entries[u].wallet, entries[u].entered);
    }
    
    //returns Entry struct data (get address of a specific id)
    function getEntryAddressById(uint _id) public view returns(uint, address) {
        require(numAddresses > 0 && _id <= numAddresses);
        uint temp = (_id + (entryAddresses.length - numAddresses));
        return (entries[entryAddresses[temp]].drawID, entries[entryAddresses[temp]].wallet);
    }
    
    //number of active entries (current draw)
    function getEntryCount() view public returns (uint) {
        return numAddresses;
    }
    
    function getLastWinner() view public returns (address) {
        return winner;
    }
    
    function getLastWinnings() view public returns (uint) {
        return winnerBalance;
    }
    
    function getBiggestWinnings() view public returns (uint) {
        return biggestWinnings;
    }
    
    function getOverallWinnings() view public returns (uint) {
        return overallWinnings;
    }
    
    //number of previous finished lottery draws
    function getPreviousDraws() view public returns(uint) {
        return previousDraws;
    }


        //dissallow new entries into the draw - make query to Oraclize
    function callOraclizeEndDraw() payable external {
        require(isFunding && contractBalance() > 0 && now > endTime);
        isFunding = false;
        numberGen = false;
        uint N = 7; // number of random bytes we want the datasource to return
        uint delay = 0; // delay is number of seconds to wait before the execution takes place
        uint callbackGas = 450000; // amount of gas we want to send Oraclize for the callback function - 250000 is sufficent for only __callback, over 310000 for __callback and endDraw()
        oraclize_setProof(proofType_Ledger); // sets the Ledger authenticity proof
        oraclize_setCustomGasPrice(10000000000 wei); // 10 gwei
        if (oraclize_getPrice("random") > contractBalance()) {
            OraclizeMsg("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
            isFunding = true;
            // no action, on next entry, they will also be entered and will attempt the call to oraclize again - contract will have higher balance this time, repeat until condition met
        } else {
            oraclize_newRandomDSQuery(delay, N, callbackGas); //this function internally generates the correct oraclize_query and returns its queryId
            OraclizeMsg("Oraclize query was sent, standing by for the answer..."); 
            //this MAY take some time - further entries and recalling of this function will be disabled until __callback has been called
            //if oraclize never returns a response to our query, the contract owner will call fixBrokenContract() to start refund process
            }
    }
    
    // the __callback function is called by Oraclize when the result is ready
    // the oraclize_randomDS_proofVerify modifier prevents an invalid proof to execute this function code:
    function __callback(bytes32 myid, string result, bytes proof) public { 
        // If we already generated a random number, we can't generate a new one.
        require(!numberGen && !isFunding);
        require (msg.sender == oraclize_cbAddress());
       if (oraclize_randomDS_proofVerify__returnCode(myid, result, proof) != 0) {
           // the proof verification has failed
            isFunding = true;
            proofFailed++;
             OraclizeMsg("Oraclize failed proof verification, Try Again");
              //have we already re-attempted to make the call?
            if(proofFailed > maxProofFail){
               //don't attempt more than maxProofFail to prevent contract balance drain
               OraclizeMsg("Failed too many times, refunding entry addresses...");
               fixBrokenContract();
            } else {
                //attempt recall
                this.callOraclizeEndDraw();
            }
    
        } else {
            // the proof verification has passed
            proofFailed = 0;
            // random number was safely generated
            numberGen = true;
            // convert the random bytes to uint
            randomNumber = uint(keccak256(result));
            OraclizeMsg("Oraclize passed proof verification! Random Num Generated");
            endDrawCall = true;
            endDraw();
            }
    }

    //end lottery (any user is able to release funds, this is only possible once the random number has already been generated and draw funding has stopped)
    function endDraw() internal {
        require(numberGen && !isFunding && endDrawCall);
        previousDraws++;
        setWinnings();
    }
    
    //calulate winnings
    function setWinnings() internal {
        require(numberGen && !isFunding && endDrawCall);
        if (contractBalance() > 0) {
           uint winningNumber;
           setWinnerRange();
           if (maxRange == 0) {
               winningNumber = 0;
           } else {
               winningNumber = randomNumber % maxRange;
           }
           winner = pickWinner(winningNumber);
           uint winnings = contractBalance();
           uint devWinnings = winnings/100; //calculate dev funds 1%
           winnerBalance = winnings - devWinnings;//calculate winner funds
           overallWinnings += winnerBalance;
           if (winnerBalance > biggestWinnings) {
               biggestWinnings = winnerBalance;
           }
           releaseEth(devWinnings);
           refreshUsers();//clear contributors
           EthReleased(winnerBalance,"Draw Finished, Ether Released! Winner is - ", winner);//event
           restartDraw();
        } else {
           NoEntries("Draw Finished, No Entries");
           restartDraw();
        }
    }
    
    //set uint range 
    function setWinnerRange() internal {
        require(numberGen && !isFunding && endDrawCall);
        offset = (entryAddresses.length - numAddresses); //set offset
        maxRange = entryAddresses.length - (offset); //sets min/max range to make min 0 and max relative offset
        minRange = 0;
    }
    
    //pick winning address
    function pickWinner(uint winNum) internal returns (address) {
        require(numberGen && !isFunding && endDrawCall);
        uint winnerNum = winNum + offset;
        address selection = entryAddresses[winnerNum];
        EntryIDLog(entries[entryAddresses[winnerNum]].drawID, winnerNum, (offset));
        return (selection);
    }
   
    //release Eth to winner / winner&dev
    function releaseEth(uint devBalance) internal {
        require(numberGen && !isFunding && endDrawCall);
        owner.transfer(devBalance);
        winner.transfer(winnerBalance);
    }
    
    //clear users ready for next draw
    function refreshUsers() internal {
        require(numberGen && !isFunding && endDrawCall);
        uint endArray = entryAddresses.length;
        uint startArray = endArray - numAddresses;
        //could be problematic after many draws / high entry amount
        for (uint i = startArray; i < endArray; i++) {
           entries[entryAddresses[i]].entered = false;
           entries[entryAddresses[i]].drawID = 0;
        }
        numAddresses = 0;
        //possibly better option to delete entire array 
        /*for(uint i = startArray; i < endArray; i++){
            delete entryAddresses[i];
        }
        numAddresses = 0;*/
    }
    
    //restart lottery
    function restartDraw() internal {
        require(numberGen && !isFunding && endDrawCall);
        isFunding = true; 
        numberGen = false;
        endDrawCall = false;
        randomNumber = 0;
        startTime = now; //now is alias for block.timestamp
        endTime = startTime + timeInterval; // set new endTime
        DrawStarted("Draw Re-Started");
    }
}
