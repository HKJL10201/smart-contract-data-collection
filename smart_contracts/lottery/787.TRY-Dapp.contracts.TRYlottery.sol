// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./TRYNFT.sol";

contract TRYlottery {
    // Struct representing a ticket (6 numbers)
    struct ticket {
        uint8 first;
        uint8 second;
        uint8 third;
        uint8 fourth;
        uint8 fifth;
        uint8 powerball;
    }

    // List of tickets bought for each user
    mapping(address => ticket[]) private _playingTickets;

    // List of players
    address payable[] private _players;

    // M parameter used to represent round's duration in blocks
    uint256 private _roundDuration;

    // Previous random generation hash used for the following random generation
    bytes32 private _prevRand;

    // Operator's address
    address private _operator;

    // Address where to send the accumulated value after each round
    address payable private immutable _transferAddress;

    // True if the prizes have been assigned for the current round
    bool private _prizesAssigned;

    // True if the numbers have been drawn for the current round
    bool private _areNumbersDrawn;

    // Mapping from class (1..8) to array of token ids (1..)
    mapping(uint256 => uint256[]) private _collectibleClasses;

    // Ticket's price in gwei (10**9 wei)
    uint256 public immutable ticketPrice;

    // Last block of the round (after this the round will be considered closed)
    uint256 public currentRoundClosing;

    // Ticket representing the randomly drawn numbers for the current round
    ticket public winningTicket;

    // NFT's contract instance
    TRYNFT public lotteryNFT;

    event LotteryOpened(address atAddress, uint256 atBlock);
    event NewRoundStarted(uint256 roundClosesAtBlock);
    event TicketBought(address buyer, ticket userTicket);
    event NumbersDrawn(ticket winningNumbers);
    event WinningTicket(
        uint256 ticketClass,
        string NFTName,
        string NFTSymbol,
        string tokenURI,
        address winner
    );
    event TokenMinted(uint256 tokenId, uint256 classNum);
    event LotteryClosed(address contractAddress);

    modifier onlyOperator() {
        require(_operator == msg.sender, "Caller is not the operator");
        _;
    }

    constructor(
        uint256 blocksNum_,
        uint256 _ticketPrice,
        address payable transferAddress_,
        address _NFTAddress
    ) {
        require(_ticketPrice > 0, "Ticket's price has to be greater than 0");
        require(blocksNum_ > 0, "The length of the round has to be >= 1");

        _roundDuration = blocksNum_;
        ticketPrice = _ticketPrice * 1 gwei;
        _operator = msg.sender;
        _transferAddress = transferAddress_;
        _prizesAssigned = true;
        _areNumbersDrawn = true;
        lotteryNFT = TRYNFT(_NFTAddress);

        emit LotteryOpened(address(this), block.number);
    }

    function startNewRound() public onlyOperator {
        /* Check if round is finished */
        require(
            _areNumbersDrawn,
            "Numbers still have to be drawn for current round"
        );
        require(
            _prizesAssigned,
            "You have to assign the prizes of the previous round first"
        );

        delete _players; // Resetting the 'players' array
        delete winningTicket; // Resetting the winning ticket
        _prizesAssigned = false;
        _areNumbersDrawn = false;
        currentRoundClosing = block.number + _roundDuration;

        emit NewRoundStarted(currentRoundClosing);
    }

    function buy(
        uint8 num1,
        uint8 num2,
        uint8 num3,
        uint8 num4,
        uint8 num5,
        uint8 num6
    ) external payable {
        require(
            _areTicketsCompliant(num1, num2, num3, num4, num5, num6),
            "Tickets are not compliant to the rules"
        );
        require(
            msg.value == ticketPrice,
            "The sent value has to be equal to the ticket price"
        );
        require(
            _isRoundActive(),
            "Cannot buy tickets while there is no active round"
        );

        ticket memory new_ticket = ticket(num1, num2, num3, num4, num5, num6);
        _playingTickets[msg.sender].push(new_ticket);
        // Add to the players array only if it's the first ticket bought by this player
        if (_playingTickets[msg.sender].length == 1)
            _players.push(payable(msg.sender));

        emit TicketBought(msg.sender, new_ticket);
    }

    function drawNumbers() external onlyOperator {
        require(
            !_isRoundActive(),
            "The round has to be finished before drawing the numbers"
        );
        require(!_areNumbersDrawn, "Numbers have already been drawn");

        /* Random generation using the block hash of the previous block combined 
        with the previously generated value, if any, in order to differentiate the result between
        consecutive uses */
        _prevRand = keccak256(
            abi.encodePacked(blockhash(block.number - 1), _prevRand)
        );

        // Acquire winning numbers from portions of the randomly generated value
        winningTicket.first = (uint8(_prevRand[0]) % 69) + 1;
        winningTicket.second = (uint8(_prevRand[1]) % 69) + 1;
        winningTicket.third = (uint8(_prevRand[2]) % 69) + 1;
        winningTicket.fourth = (uint8(_prevRand[3]) % 69) + 1;
        winningTicket.fifth = (uint8(_prevRand[4]) % 69) + 1;
        winningTicket.powerball = (uint8(_prevRand[5]) % 26) + 1;

        _areNumbersDrawn = true;

        emit NumbersDrawn(winningTicket);
    }

    function givePrizes() external onlyOperator {
        require(
            !_prizesAssigned,
            "Prizes have already been assigned for this round"
        );
        require(_areNumbersDrawn, "You have to draw the winning numbers first");

        for (uint256 i; i < _players.length; ++i) {
            for (
                uint256 tktNum;
                tktNum < _playingTickets[_players[i]].length;
                ++tktNum
            ) {
                uint8 gottenNumbers = 0;
                bool gotPowerball = false;
                ticket memory playerTkt = _playingTickets[_players[i]][tktNum];
                gottenNumbers += _checkIfNumberWinning(playerTkt.first) ? 1 : 0;
                gottenNumbers += _checkIfNumberWinning(playerTkt.second)
                    ? 1
                    : 0;
                gottenNumbers += _checkIfNumberWinning(playerTkt.third) ? 1 : 0;
                gottenNumbers += _checkIfNumberWinning(playerTkt.fourth)
                    ? 1
                    : 0;
                gottenNumbers += _checkIfNumberWinning(playerTkt.fifth) ? 1 : 0;
                gotPowerball = _checkIfNumberWinning(playerTkt.powerball);
                uint256 classNumber = _determineClassNumber(
                    gottenNumbers,
                    gotPowerball
                );
                if (classNumber == 0)
                    // if 0 guesses skip
                    continue;

                uint256 currClassLen = _collectibleClasses[classNumber].length;
                /* Assuming that initially it is not mandatory to have at least one token per class, 
                thus, if the class is empty, nothing can be assigned */
                if (currClassLen == 0) continue;

                string memory currClassURI = lotteryNFT.tokenURI(
                    _collectibleClasses[classNumber][0]
                );

                // If there is only one collectible inside a class, then another one will be created
                bool singleInClass;
                if (currClassLen == 1) singleInClass = true;

                // Assigning class tokens from the tail in order to be able to use 'pop()' on the array
                uint256 tokenId = _collectibleClasses[classNumber][
                    currClassLen - 1
                ];

                lotteryNFT.transferFrom(address(this), _players[i], tokenId);

                emit WinningTicket(
                    classNumber,
                    lotteryNFT.name(),
                    lotteryNFT.symbol(),
                    lotteryNFT.tokenURI(tokenId),
                    _players[i]
                );

                // Popping avoids array shifts and array holes
                _collectibleClasses[classNumber].pop();
                // Creation of another token to avoid having an empty class
                if (singleInClass) _mintForClass(currClassURI, classNumber);
            }
            delete _playingTickets[_players[i]];
        }

        _prizesAssigned = true;
        delete winningTicket;
        // The operator's provided address receives the whole value when users receive their winnings
        _transferAddress.transfer(address(this).balance);
    }

    /* Check if a token with the same URI has already been assigned to a class and, 
    in that case, mint a new token and assign it to the same class, otherwise assign 
    the token to a new class */
    function mint(string memory tokenURI) external onlyOperator {
        for (uint256 cnum = 1; cnum < 9; ++cnum) {
            if (
                _collectibleClasses[cnum].length > 0 &&
                _compareStrings(
                    lotteryNFT.tokenURI(_collectibleClasses[cnum][0]),
                    tokenURI
                )
            ) {
                _mintForClass(tokenURI, cnum);
                return;
            }
        }

        // The initial token ownership belongs to the contract
        uint256 tokenId = lotteryNFT.mintNFT(address(this), tokenURI);
        // It is possible for a token to be assigned to an already populated class
        uint256 classNum = _assignClassToToken(tokenId);

        emit TokenMinted(tokenId, classNum);
    }

    function closeLottery() external onlyOperator {
        if (!_prizesAssigned) {
            // Last step of the game
            for (uint256 i; i < _players.length; ++i) {
                for (
                    uint256 ticketNum;
                    ticketNum < _playingTickets[_players[i]].length;
                    ++ticketNum
                ) _players[i].transfer(ticketPrice);
            }
        }

        /* 'selfdestruct' requires a parameter to send the remaining value to;
        thus the address provided by the operator has been chosen even if, at this point,
        the value stored inside this contract should be zero */
        selfdestruct(payable(_transferAddress));

        emit LotteryClosed(_operator);
    }

    function getOperator() public view returns (address) {
        return _operator;
    }

    function _mintForClass(string memory tokenURI, uint256 classNum)
        private
        onlyOperator
    {
        // The initial token ownership belongs to the contract
        uint256 tokenId = lotteryNFT.mintNFT(address(this), tokenURI);
        _collectibleClasses[classNum].push(tokenId);

        emit TokenMinted(tokenId, classNum);
    }

    // It is assumed that not all tokens have to be initially assigned to a class
    function _assignClassToToken(uint256 tokenId) private returns (uint256) {
        // Random choice
        _prevRand = keccak256(
            abi.encodePacked(blockhash(block.number - 1), _prevRand)
        );

        uint256 classNum = (uint256(_prevRand) % 8) + 1; // random number modulo number of classes
        _collectibleClasses[classNum].push(tokenId);

        return classNum;
    }

    function _checkIfNumberWinning(uint8 number) private view returns (bool) {
        return
            number == winningTicket.first ||
            number == winningTicket.second ||
            number == winningTicket.third ||
            number == winningTicket.fourth ||
            number == winningTicket.fifth ||
            number == winningTicket.powerball;
    }

    function _determineClassNumber(uint8 gottenNumbers, bool gotPowerball)
        private
        pure
        returns (uint256)
    {
        if (gottenNumbers == 5) {
            if (gotPowerball) return 1;
            else return 2;
        } else if (gottenNumbers == 4) {
            if (gotPowerball) return 3;
            else return 4;
        } else if (gottenNumbers == 3) {
            if (gotPowerball) return 4;
            else return 5;
        } else if (gottenNumbers == 2) {
            if (gotPowerball) return 5;
            else return 6;
        } else if (gottenNumbers == 1) {
            if (gotPowerball) return 6;
            else return 7;
        } else if (gotPowerball) return 8;
        return 0;
    }

    function _areTicketsCompliant(
        uint8 num1,
        uint8 num2,
        uint8 num3,
        uint8 num4,
        uint8 num5,
        uint8 num6
    ) private pure returns (bool) {
        return
            (num1 >= 1 && num1 <= 69) &&
            (num2 >= 1 && num2 <= 69) &&
            (num3 >= 1 && num3 <= 69) &&
            (num4 >= 1 && num4 <= 69) &&
            (num5 >= 1 && num5 <= 69) &&
            (num6 >= 1 && num6 <= 26);
    }

    function _isRoundActive() private view returns (bool) {
        return block.number <= currentRoundClosing;
    }

    function _compareStrings(string memory s1, string memory s2)
        private
        pure
        returns (bool)
    {
        return keccak256(bytes(s1)) == keccak256(bytes(s2));
    }

    /************************** Functions used for unit testing ******************************/
    /*
    function getTokensAtClass(uint256 class) public view returns (uint256[] memory) {
        return _collectibleClasses[class];
    }

    function setWinningTicket(
        uint8 num1, 
        uint8 num2, 
        uint8 num3, 
        uint8 num4, 
        uint8 num5, 
        uint8 powerball
    ) public {
        winningTicket = ticket(num1, num2, num3, num4, num5, powerball);
        _areNumbersDrawn = true;
    }

    function mintForClass(string memory tokenURI, uint256 classNum) public {
        _mintForClass(tokenURI, classNum);
    }
    */
}
