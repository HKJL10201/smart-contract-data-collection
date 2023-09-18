// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./nftKitty.sol";

struct PlayerAccountTickets{
    mapping (uint => uint []) ticketList; //for each key, it contains the 5 numbers + special number
    uint nTicket; //tot ticket
    uint [] nMatches; //for each ticket, store the number of matches
    uint [] nMatchesPB; //for each ticket, store if the special number has been found
}

// Interface to communicate with nftKitty contract
interface IKitty {
    function mint(uint class) external;
    function getTokenOfClass(uint class) external view returns(uint);
    function awardItem(address player, uint256 tokenId) external;
    function setLotteryAddress(address _lottery) external;
    function getNFTsFromAddress(address addr) external view returns(string[] memory);
}

contract Lottery {
    address public lotteryOperator;
    //lottery players
    address payable[] public players; 
    // addr. of kinnyNFT contract
    address public kittyAddress; 
    mapping (address => PlayerAccountTickets) public playersTickets; 
    //to know if the round is active or not
    bool public isActive; 
    //to know if the lottery is active or not
    bool public isLotteryActive; 
    //duration of each round
    uint public duration; 
    //it contains the number of the last block of the round
    uint public roundClosing; 
    //number of the first block related to a specific round
    uint public blockNumber; 
    //numbers drawn each round
    uint [6] public numbersDrawn; 
    //parameter
    uint public valueK; 
    //to know if the prize has been given to the players or not
    bool public prizeGiven;
    //price of the ticket
    uint public ticketPrice;
    
    //nft
    IKitty nft;

    constructor(uint _K, uint _duration,uint price, address kittyAddr, address _lotteryOperator) {
        lotteryOperator = _lotteryOperator;
        isActive = false;
        isLotteryActive = true;
        valueK = _K;
        duration = _duration;
        prizeGiven = true;
        nft = IKitty(kittyAddr);
        ticketPrice = price * (1 gwei);

        for(uint i=0; i<8;i++){
          nft.mint(i+1);
        }

    }

    //event log
    event newRound(string result, uint start, uint end);
    event newTicketBought(address buyer,string result,uint[6] _numbers);
    event newDrawn(string result);
    event givePrizeToPlayers(address winningPlayer, string result, uint _prizeToGive);
    event mintNewNft(string result, uint nftClass);
    event closeLotteryEvent(string result);
    event closeLotteryAndRefund(string result, address buyer, uint _refund);
    event winningNumbers(uint[6] _numbers);
    event refundLotteryOperator(string result, uint value);

    //this function uses the function mint from the contract nft_kitty.sol
    function mint(uint _classNFT) public {
        require(isLotteryActive == true, "Lottery is not active at the moment");
        require(msg.sender == lotteryOperator, "This function is only for the Lottery Operator");
        nft.mint(_classNFT);
        emit mintNewNft("Lottery Operator has minted a new NFT Token", _classNFT);
    }

    //start a new round
    function startNewRound() public  {
        require(msg.sender == lotteryOperator, "This function is only for the Lottery Operator");
        require(isLotteryActive == true, "Lottery is not active at the moment");
        require(isActive == false, "Wait the end of previous round before starting a new one");
        require(prizeGiven == true, "You must give prize to players before starting a new round");

        prizeGiven = false;
        isActive = true;
        blockNumber = block.number; //get the block number
        roundClosing = blockNumber + duration; //round lasts from the first block up to the n' block

        //remove all tickets bought by players in the previous round
        for(uint i = 0; i < players.length; i++){
            uint tickNumb = playersTickets[players[i]].nTicket;
            for(uint j = 1; j <= tickNumb; j++){
                delete playersTickets[players[i]].ticketList[j];
            }
            playersTickets[players[i]].nTicket = 0;
            delete playersTickets[players[i]].nMatches;
            delete playersTickets[players[i]].nMatchesPB;
        }

        players = new address payable[](0); //remove all previous players

        emit newRound("New round is on!", block.number, roundClosing);

    }

    //Allows users to buy a ticket. The numbers picked by a user in 
    //that ticket are passed as input of the function. The function checks 
    //if there is a round active, otherwise the function returns an error code.
    function buy(uint [6] memory _numbers) public payable returns (bool){
        require(isLotteryActive == true, "Lottery is not active at the moment"); 
        require(isActive == true, "Round is not active, wait for new one!");       
        require(msg.value == ticketPrice, "Need more gwei to buy a ticket!");
        require(block.number <= roundClosing, "Round is over, try later");

        //check if the numbers are 6
        uint nlen = _numbers.length;
        require( nlen == 6, "You must choice six numbers to play!");

        //array of boolean to check numbers repetition
        bool[69] memory pickedNumbers;
        for( uint i = 0; i < 69;i++)
            pickedNumbers[i] = false;

        for( uint i = 0; i < nlen; i++){
            if(i != 5){
                require( _numbers[i] >= 1 && _numbers[i] <= 69, "Number out of range: 1-69");
                require( !pickedNumbers[_numbers[i]-1], "Duplicated number are not allowed" );

                pickedNumbers[_numbers[i]-1] = true;
            }
            else {
                require( _numbers[i] >= 1 && _numbers[i] <= 26, "Number out of range: 1-26");

                pickedNumbers[_numbers[i]-1] = true;
            }
        }
        
        playersTickets[msg.sender].nTicket += 1; //add new ticket to the list
        uint num = playersTickets[msg.sender].nTicket; //get the total numbers of tickets for that player

        if ( num == 1 )
            players.push(payable(msg.sender)); //add the player to the array if not already present
        
        for(uint i = 0; i < 6; i++)
            playersTickets[msg.sender].ticketList[num].push(_numbers[i]); //add the ticket
        
        emit newTicketBought(msg.sender,"New Ticket bought by the user!",_numbers);

        return true;
    }

    //used by the lottery operator to draw numbers of the current lottery round
    function drawNumbers() public { 
        require(msg.sender == lotteryOperator, "This function is only for the Lottery Operator");
        require(isLotteryActive == true, "Lottery is not active at the moment");
        require(block.number >= roundClosing + valueK, "Too early to draw numbers");
        require(!prizeGiven, "You have already drawn numbers!");

        isActive = false; //stop the current round and start to drawn the numbers

        bool[69] memory pickedNumbers;
        for( uint i = 0; i < 69;i++)
            pickedNumbers[i] = false;

        //blockhash removed due to some problems with remix
        //bytes32 bhash = blockhash(duration + valueK);

        //take the block.difficulty, block.timestamp and duration+K as source of entropy to draw numbers
        bytes32 bhash = keccak256(abi.encodePacked(block.difficulty, block.timestamp, duration + valueK));
        bytes memory bytesArray = new bytes(32);
        
        for (uint i=0; i<6; i++){ 

            for (uint j = 0; j <32; j++)
                bytesArray[j] = bhash[j];

            bytes32 rand = keccak256(bytesArray);
            

            uint x = (uint(rand) % 69) + 1;
            numbersDrawn[i] = x;
            //check if the number is repeated or not
            if( pickedNumbers[x-1] )
                i -= 1;
            else {
                pickedNumbers[x-1] = true;
            }

            if( i == 5)
                numbersDrawn[5] = (uint(rand) % 26) + 1; //powerball number

            bhash = bhash ^ rand; //xor for each position in bhash

        }

        emit newDrawn("Lottery Operator has drawn the winning numbers! Let's see the winners");
        emit winningNumbers(numbersDrawn);

        //To test using lottery_test.js, this function call must be commented
        //this due to some problems with the IDE REMIX which crash due to lack of memory
        givePrizes();

    }

    //check the winners of the lottery by inspecting all the tickets
    //This function is used by lottery operator to distribute the prizes of the current lottery round
    //inspect all the result in playersTickets and gives the prize to the player
    //if one prize has been already assigned to a player, will be generated a new one of the same rank
    function givePrizes() public {
        require(msg.sender == lotteryOperator, "This function is only for the Lottery Operator");
        require(isLotteryActive == true, "Lottery is not active at the moment");
        
        //for each player in the lottery round
        for (uint i = 0; i < players.length; i++){ 
            //for each ticket
            for ( uint j = 1; j <= playersTickets[players[i]].nTicket; j++){ 
                uint totMatch = 0;
                for ( uint k = 0; k < 6; k++ ){

                    if ( k == 5 ){ //powerball match
                        if ( numbersDrawn[k] == playersTickets[players[i]].ticketList[j][k] )
                            playersTickets[players[i]].nMatchesPB.push(1);
                        else
                            playersTickets[players[i]].nMatchesPB.push(0);
                         //update the total amount of matches for "normal" numbers
                        playersTickets[players[i]].nMatches.push(totMatch);
                        break;
                    }
                    
                    for (uint z = 0; z < 5; z++){//normal numbers matches
                        if ( numbersDrawn[k] == playersTickets[players[i]].ticketList[j][z] ){
                                totMatch += 1;
                                break;
                        }
                    }
                }
            }
        }

        //assign the prizes
        for (uint i = 0; i < players.length; i++){ //for each player in the lottery round
            for ( uint j = 0; j < playersTickets[players[i]].nTicket; j++){ //for each ticket
                uint match1 = playersTickets[players[i]].nMatches[j];
                uint match2 = playersTickets[players[i]].nMatchesPB[j];
                uint prizeToAssign;

                if(match1 == 0 && match2 == 0) //no matches -> skip 
                    continue;

                if (match1 == 5 && match2 == 1)
                    prizeToAssign = 1;
                else if ( match1 == 5 && match2 == 0)
                    prizeToAssign = 2;
                else if (match1 == 4 && match2 == 1)
                    prizeToAssign = 3;
                else if (match1 == 4 && match2 == 0)
                    prizeToAssign = 4;
                else if (match1 == 3 && match2 == 1)
                    prizeToAssign = 4;
                else if (match1 == 3 && match2 == 0)
                    prizeToAssign = 5;
                else if (match1 == 2 && match2 == 1)
                    prizeToAssign = 5;
                else if (match1 == 2 && match2 == 0)
                    prizeToAssign = 6;
                else if (match1 == 1 && match2 == 1)
                    prizeToAssign = 6;
                else if (match1 == 1 && match2 == 0)
                    prizeToAssign = 7;
                else if (match1 == 0 && match2 == 1)
                    prizeToAssign = 8;

                emit givePrizeToPlayers(players[i],"Player has received his prize", prizeToAssign );

                //assign the prize and mint a new one of same class/rank
                uint tokendIdWin = nft.getTokenOfClass(prizeToAssign);
                nft.awardItem(players[i],tokendIdWin);
                mint(prizeToAssign);

            }
        }        

        prizeGiven = true;
        uint balance = address(this).balance;
        payable(lotteryOperator).transfer(address(this).balance);//refund lottery operator
        emit refundLotteryOperator("Refund Lottery Operator", balance);

    }

    //close the lottery
    function closeLottery() public {
        require(msg.sender == lotteryOperator, "This function is only for the Lottery Operator");
        require(isLotteryActive == true, "Lottery is not active at the moment");

        isLotteryActive = false; //deactivate the lottery
        //refund players if the lottery is closed before the drawn of the numbers
        if(isActive && !prizeGiven){
            for(uint i = 0; i < players.length; i++){
                players[i].transfer(ticketPrice*playersTickets[players[i]].nTicket);
                emit closeLotteryAndRefund("Lottery closed before drawing: Player refunded!", players[i], ticketPrice*playersTickets[players[i]].nTicket);
            }
            isActive = false;
        }

        emit closeLotteryEvent("Lottery Operator has closed the Lottery! ");
    }

    /*Some useful function to manage the lottery in front end*/

    //function use by front-end to retrieve the winning numbers
    function getWinningNumbers() public view returns (uint[6] memory){
        return numbersDrawn;
    }

    //return the numbers of players in the current round
    function getPlayers() public view returns(uint){
        return players.length;
    }

    //Return all the tickets related to addr to update fron-end interface
    function getTicketList(address addr, uint index) public view returns(uint[] memory){
       return playersTickets[addr].ticketList[index];
    }

    function getTotTickets(address addr) public view returns(uint){
        return playersTickets[addr].nTicket;
    }

    //use to retrieve all the nft associated to an user
    function getWonNFTsFromAddress(address addr) public view returns(string[] memory){
        return nft.getNFTsFromAddress(addr);
    }

    //usefull function for debugging

    function getMatch(address addr) public view returns(uint[] memory){
       return playersTickets[addr].nMatches;
    }

    function getMatchPB(address addr) public view returns(uint[] memory){
       return playersTickets[addr].nMatchesPB;
    }

    function getRank(uint _class) public view returns(uint){
        return nft.getTokenOfClass(_class);
    }

}
