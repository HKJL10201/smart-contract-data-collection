// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @title Try
 * @dev A lottory of NFT
 */

// A representation of a ticket in lottery
struct Ticket{
    uint[6] numbers;
    uint matches;
    bool powerballMatch;
    bool isWinning;
}

// Representation of user that bought tickets
struct User{
    Ticket[] tickets;
    uint nTicket;
    uint nTicketRound;
}

// Interface for communicate with KittyNFT contract
interface IKittyNFT {
    function mint(uint class) external returns (uint256);
    function getTokenFromClass(uint class) external view returns(uint);
    function awardItem(address player, uint256 tokenId) external;
    function setLotteryAddress(address _lottery) external;
    function getNFTsFromAddress(address addr) external view returns(string[] memory);
}

contract Try {

    // Round duration
    uint public M;
    // Ticket price
    uint public ticketPrice;
    // K parameter chosen by operator
    uint public K;
    // End of a round
    uint public roundDuration;
    // The drawn numbers 
    uint[6] public winningNumbers;

    // Tells if the contract is active
    bool public isContractActive;
    // Tells if a round is active
    bool public isRoundActive;
    // Tells if prizes are already given
    bool public isPrizeGiven;

    // Owner of the contract
    address public owner;
    // Mantains the buyers for a round
    address[] public buyers;
    // Store the address of KittyNFT contract
    address public kittyNFTAddress;

    IKittyNFT nft;
    
    // Associate each address to an "account"
    mapping (address => User) public players;

    event TicketBought(string result, address _addr, uint[6] _numbers);
    event NFTWin(string str, address _addr, uint _class);
    event ToLog(string str);
    event NewWinningNumber(uint number);
    event NewRound(string str, uint _start, uint _end);
    event ChangeBack(string str, uint _change);
    event Refund(address _addr, uint _change);
    event NFTMint(string str, uint _class);
    event LotteryClosed();
    event ExtractedNumbers(uint[6] _numbers);

    constructor(uint _M, uint _K, uint price ,address KittyNFTaddr, address _owner) {
        M = _M;
        K = _K;
        ticketPrice = price * (1 gwei);
        isRoundActive = false;
        isContractActive = true;
        isPrizeGiven = true;
        owner = _owner;
        uint i=0;
        nft = IKittyNFT(KittyNFTaddr);
        // Generation of first eight NFT
        for (i=0; i<8; i++)
            nft.mint(i+1);
    }

    /**
     * @dev Start a new round of the lottery
     */
    function startNewRound() public {
        require(isContractActive,"Lottery is closed.");
        require(msg.sender==owner, "Only the owner can start a new round.");
        require(!isRoundActive, "A new round can start after the previous expires.");
        require(isPrizeGiven, "Wait for prizes before start a new round.");
        isRoundActive = true;
        isPrizeGiven = false;
        roundDuration = block.number + M;
        // Clean the tickets of this round
        delete buyers;
        emit NewRound("A new round has started.", block.number, roundDuration);
    }

    /**
     * @dev Let users buy a ticket
     * @param numbers: the numbers picked by the user
     * @return bool: True in case of successful purchase, False o.w
     */
    function buy(uint[6] memory numbers) public payable returns(bool) {
        require(isContractActive,"Lottery is closed."); 
        require(isRoundActive, "Round is closed. Try later.");
        require(block.number <= roundDuration, "You can buy a ticket when a new round starts.");
        require(msg.value >= ticketPrice, "Not enough wei to buy a ticket.");
        uint numebrsLen = numbers.length;
        require(numebrsLen == 6, "You have to pick 5 numbers and a powerball number");
        uint i;
        bool[69] memory picked;
        for (i=0; i<69; i++)
            picked[i] = false; 

        for(i=0; i< numebrsLen; i++){
            if(i != 5){
                require(numbers[i] >= 1 && numbers[i] <= 69);
                require(!picked[numbers[i]-1], "Ticket numbers cannot be duplicated");
                picked[numbers[i]-1] = true;
            }
            else
                require(numbers[i] >= 1 && numbers[i] <= 26, "Powerball number must be in range [1,26]");
        }
        // Ticket can be bought, All checks passed
        players[msg.sender].nTicket += 1;
        if (players[msg.sender].nTicketRound==0)
            buyers.push(msg.sender);

        players[msg.sender].nTicketRound += 1;
        players[msg.sender].tickets.push(Ticket(numbers, 0, false,false));

        uint change = msg.value - ticketPrice; 
        if( change > 0){
            payable(msg.sender).transfer(change);
            emit ChangeBack("Change issued", change);
        }
        emit TicketBought("Ticket successfully purchased ", msg.sender, numbers);
        return true;
    }

    /**
     * @dev Pick random numbers as winning numbers for this round.
            Then it assign the rewards to winning users, if any.
     * @return bool: True in case of successful purchase, False o.w
     */
    function drawNumbers() public returns(bool){
        require(isContractActive,"Lottery is closed.");
        require(msg.sender==owner, "Only the owner can draw numbers.");
        require(block.number >= roundDuration + K, "Too early to draw numbers");
        require(!isPrizeGiven, "Already drawn winning numbers.");
        isRoundActive = false;
        bool[69] memory picked;
        for (uint i=0; i<69; i++)
            picked[i] = false;

        //uint extractedNumber;
        uint nounce = 0;
        uint[6] memory randomNumbers;
        bytes32 bhash = keccak256(abi.encodePacked(nounce,block.difficulty,block.timestamp, roundDuration + K));
        bytes memory bytesArray = abi.encodePacked(bhash);
        bytes32 rand;
        for (uint j=0; j<5; j++){
            // generate random
            rand = keccak256(bytesArray);
            randomNumbers[j] = (uint(rand) % 69) + 1;
            bytesArray = abi.encodePacked(bhash ^ rand, nounce);
            nounce++;
        }
        for(uint j=0; j<5; j++){
            require(!picked[randomNumbers[j]-1], "Extracted numbers are duplicated. Retry.");
            picked[randomNumbers[j]-1] = true;
        }

        winningNumbers = randomNumbers;
        // Gold number
        winningNumbers[5] = 6;//(uint(rand) % 26) + 1;
        emit ToLog("Winning numbers extracted");
        emit ExtractedNumbers(winningNumbers);
        // Give the awards to users
        givePrizes();
        return true;
    }   

    /**
     * @dev Assign prizes to users.
     */
    function givePrizes() public {
        require(isContractActive,"Lottery is closed.");
        require(msg.sender==owner, "Only the owner can draw numbers.");
        require(!isRoundActive, "Round still in progress.");
        require(!isPrizeGiven, "Already given prizes.");
        isPrizeGiven = true;
        // select winners
        uint winNFTClass;
        uint matches;
        uint[6] memory userNumbers;
        uint powerball = winningNumbers[5];
        uint i;
        // iterate over buyers
        for(i=0; i< buyers.length; i++){
            uint nTicket = players[buyers[i]].nTicket;
            uint indexFirstPurchase = nTicket - players[buyers[i]].nTicketRound;
            players[buyers[i]].nTicketRound = 0;
            // iterate over purchased tickets
            for (uint j=indexFirstPurchase; j < nTicket; j++){
                matches = 0;
                userNumbers = players[buyers[i]].tickets[j].numbers;
                // iterate over numbers
                for(uint k=0; k<5; k++){
                    for(uint z=0; z < 5; z++){
                        if(userNumbers[k] == winningNumbers[z]){
                            matches += 1;
                            break;
                        }
                    }
                }
                if((matches > 0) || (userNumbers[5] == powerball)){ // checking also powerball number
                    players[buyers[i]].tickets[j].matches = matches;
                    // assign prizes based on matches
                    players[buyers[i]].tickets[j].isWinning = true;
                    winNFTClass = 9;
                    if(matches == 1){
                        winNFTClass = 7;
                    } else if (matches == 2){
                        winNFTClass = 6;
                    } else if (matches == 3){
                        winNFTClass = 5;
                    } else if (matches == 4){
                        winNFTClass = 4;
                    } else if (matches == 5){
                        winNFTClass = 2;
                    }
                    if (userNumbers[5] == powerball){
                        players[buyers[i]].tickets[j].powerballMatch = true;
                        winNFTClass-=1;
                    }
                    // here we have to assign NFT to the address
                    emit NFTWin("NFT Win!",buyers[i], winNFTClass);
                    uint tokenId = nft.getTokenFromClass(winNFTClass);
                    nft.awardItem(buyers[i], tokenId);
                    mint(winNFTClass);
                }
            }
        }
        // Pay lottery operator with the contract's balance
        uint balance = address(this).balance;
        payable(owner).transfer(address(this).balance);
        emit ChangeBack("Operator refunded",balance);
    } 

    /**
     * @dev Used to mint a new NFT of a specific class
     * @param _class: NFT's class to be mined
     */
    function mint(uint _class) public {
        require(isContractActive,"Lottery is closed.");
        require(msg.sender==owner, "Only the owner can mint NFT.");
        nft.mint(_class);
        emit NFTMint("New NFT minted", _class);
    }
    
    /**
     * @dev Close the lottery, deactivating the contract.
            If a round is active, it refund users.
     */
    function closeLottery() public payable {
        require(isContractActive,"Lottery is already closed.");
        require(msg.sender==owner, "Only the owner can close the lottery.");
        isContractActive = false;

        address payable userAddress;
        if(isRoundActive && !isPrizeGiven){
            // Need to refund players
            for(uint i=0; i < buyers.length; i++){
                uint nTicketRound = players[buyers[i]].nTicketRound;
                players[buyers[i]].nTicketRound = 0;
                userAddress = payable(buyers[i]);
                userAddress.transfer(ticketPrice*nTicketRound);
                emit Refund(userAddress, ticketPrice*nTicketRound);
            }
        }

        emit LotteryClosed();
    }

    /**
     * Utility functions
     */
    function getWinningNumbers() public view returns (uint[6] memory){
        return winningNumbers;
    }

    function getBuyersLength() public view returns(uint){
        return buyers.length;
    }

    function getTicketsFromAddress(address addr) public view returns(Ticket[] memory){
        return players[addr].tickets;
    }

    function getWonNFTsFromAddress(address addr) public view returns(string[] memory){
        return nft.getNFTsFromAddress(addr);
    }
}