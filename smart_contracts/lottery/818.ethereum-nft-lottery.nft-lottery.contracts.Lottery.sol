// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./CryptoPepes.sol";

/// @author Matteo Pinna
/// @title An NFT Lottery inspired by PowerBall
contract Lottery is CryptoPepes {

    bool _prizesAssigned = false;

    uint public _ticketPrice = 10000000000000000 wei;
    uint private _currentRound;
    uint private _startBlock;
    uint private _duration = 4; // number of blocks
    uint[6] public _winningNumbers;

    address private _owner;
    address private _withdrawal;
    address[] private _players;

    // Mapping from address to total amount sent
    mapping(address => uint) private _addressToAmount;

    // Mapping from round id to list of tickets
    mapping(uint => Ticket[]) private _tickets;

    // Mapping from lottery number to bool (true: picked as winning number)
    mapping(uint => bool) private _winningNumbersMapping;

    // Struct representing a ticket
    struct Ticket {
        address player;
        uint[6] numbers;
    }

    event LogDeployment(address owner);
    event LogNewRound(uint blockNumber, uint roundNumber);
    event LogTicketPurchase(address from, uint amount, uint[6][] numbers);
    event LogTicketDuplicates(address from, uint[6] invalidNumbers);
    event LogNumbersDrawing(uint[6] winningNumbers);
    event LogMint(address to, uint prizeRank, uint tokenId);
    event LogWinner(address to, uint prizeRank, uint tokenId);
    event LogTicketRefund(address to, uint amount);
    event LogWithdrawal(address to, uint amount);
    event LogDeactivation(address to);

    modifier ownerOnly() {
        require(_owner == msg.sender, "owner only");
        _;
    }

    modifier activeRoundOnly() {
        require(_currentRound != 0 && block.number < _startBlock + _duration, "active round only");
        _;
    }

    modifier inactiveRoundOnly() {
        require(_currentRound != 0 && block.number >= _startBlock + _duration && !_prizesAssigned, "inactive round only");
        _;
    }    

    modifier endedRoundOnly() {
        require(_currentRound == 0 || _prizesAssigned, "first round or ended round only");
        _;
    }


    /**
    * @dev Initializes the contract.
    */
    constructor() {
        _owner = msg.sender;
        _withdrawal = _owner;
    
        emit LogDeployment(msg.sender);
    }

    // receive

    // fallback (must be defined as external for definition)

    /**
     * @dev Retrieve balance of the contract,
     * 
     * @return uint balance
     */
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getTicket(uint index) public view returns(Ticket memory) {
        return _tickets[_currentRound][index];
    }

    /**
     * @dev Retrieve winning numbers of current round.
     * 
     * @return uint[6] array
     */
    function getWinningNumbers() public view returns(uint[6] memory) {
        return _winningNumbers;
    }

    /**
     * @dev Update the <_ticketPrice> of the lottery.
     * 
     * Requirements:
     *
     * - msg.sender must be the lottery operator
     * - the previous round must have ended
     */
    function setTicketprice(uint price) public ownerOnly endedRoundOnly {
        _ticketPrice = price;
    }

    /**
     * @dev Update the <_duration> of the lottery.
     * 
     * Requirements:
     *
     * - msg.sender must be the lottery operator
     * - the previous round must have ended
     */
    function setDuration(uint duration) public ownerOnly endedRoundOnly {
        //require(duration >= 2, "invalid duration"); // to allow at least one buy()
        _duration = duration;
    }

    /**
     * @dev Update the <_withdrawal> address of the lottery.
     * 
     * Requirements:
     *
     * - msg.sender must be the lottery operator
     */
    function setWithdrawal(address withdrawal) public ownerOnly {
        require(withdrawal != address(0), "invalid empty address");
        _withdrawal = withdrawal;
    }

    /**
     * @dev Starts a new round of the lottery, resets various mapping needed for the lottery
     * using auxiliary arrays that store the related keys.
     * 
     * Requirements:
     *
     * - msg.sender must be the lottery operator
     * - the previous round must have ended
     */
    function startNewRound() public ownerOnly endedRoundOnly returns(bool) {
        _startBlock = block.number;
        _prizesAssigned = false;
        delete _tickets[_currentRound];
        _currentRound++;

        if(_currentRound != 1) {
            // Reset players
            for(uint i = 0; i < _players.length;) {
                delete _addressToAmount[_players[i]];

                unchecked { i++; }
            }
            delete _players;

            // Reset winning numbers
            for(uint i = 0; i < 5;) {
                delete _winningNumbersMapping[_winningNumbers[i]];

                unchecked { i++; }
            }
            delete _winningNumbers;
        }

        emit LogNewRound(block.number, _currentRound);

        return true;
    }

    /**
     * @dev Allows to buy multiple tickets for the lottery, if a ticket has duplicate standard numbers
     * it's discarded and the prize is not refunded.
     * 
     * Requirements:
     *
     * - msg.value must be equal to the total price of the tickets
     * - standard numbers must be between 1-69
     * - powerBall number must be between 1-26
     * - there must be an active round
     */
    function buy(uint[6][] memory _numbers) public payable activeRoundOnly returns(bool) {
        uint n = _numbers.length;
        uint totalPrice = _ticketPrice*n;

        require(msg.value >= totalPrice, "msg.value not enough");

        for(uint i = 0; i < n;) {
            // Implicit loop saves some gas
            require(_numbers[i][0] > 0 && _numbers[i][0] < 70, "invalid standard number");
            require(_numbers[i][1] > 0 && _numbers[i][1] < 70, "invalid standard number");
            require(_numbers[i][2] > 0 && _numbers[i][2] < 70, "invalid standard number");
            require(_numbers[i][3] > 0 && _numbers[i][3] < 70, "invalid standard number");
            require(_numbers[i][4] > 0 && _numbers[i][4] < 70, "invalid standard number");
            require(_numbers[i][5] > 0 && _numbers[i][5] < 27, "invalid powerBall number");

            // If no duplicates
            if(_isTicketValid(_numbers[i])) {
                _players.push(msg.sender);
                _addressToAmount[msg.sender] = totalPrice;
                _tickets[_currentRound].push(Ticket(msg.sender, _numbers[i]));
            }
            else {
                emit LogTicketDuplicates(msg.sender, _numbers[i]);
            }

            unchecked { i++; }
        }

        // Send back change, if needed
        // invalid tickets are not refunded
        if(msg.value > totalPrice) {
            uint change = msg.value - totalPrice;
            payable(msg.sender).transfer(change);
        }

        emit LogTicketPurchase(msg.sender, msg.value, _numbers);

        return true;
    }

    /**
     * @dev Randomly draws the winning numbers of the current round, then shuffle the array with
     * all possible standard numbers to avoid duplicates.
     * 
     * Requirements:
     *
     * - msg.sender must be the lottery operator
     * - no active round and not ended round
     */
    function drawNumbers() public ownerOnly inactiveRoundOnly returns(uint[6] memory) {
        require(_winningNumbers[0] == 0, "numbers already drawn");

        uint[6] memory aux;

        for(uint i = 0; i < 5;) {
            uint rand = (_random(i) % 69) + 1;

            // Check if duplicate
            while(_winningNumbersMapping[rand]) {
                rand = (_random(rand*7) % 69) + 1;
            }

            aux[i] = rand;
            _winningNumbersMapping[aux[i]] = true;

            unchecked { i++; }
        }
        aux[5] = (_random(5) % 26) + 1;

        _winningNumbers = aux;

        emit LogNumbersDrawing(_winningNumbers);

        return aux;
    }

    /**
     * @dev Assigns the prizes to the winners of the lottery by computing the
     * match w.r.t. the winning numbers drawn.
     * 
     * Requirements:
     *
     * - msg.sender must be the lottery operator
     * - no active round and not ended round
     * - winning numbers drawn
     */
    function givePrizes() public ownerOnly inactiveRoundOnly returns(bool) {
        require(_winningNumbers[0] != 0, "winning numbers not drawn yet");

        for(uint i = 0; i < _tickets[_currentRound].length;) {
            address winner = _tickets[_currentRound][i].player;
            // Get prize rank
            uint rank = _prizeRank(_tickets[_currentRound][i]);

            if(rank != 0) {
                // Available -> transfer 
                if(isAvailable(rank)) {
                    transferNFT(winner, rank);
                }
                else { // mint it -> transfer
                    emit LogMint(winner, rank, _tokenCount);
                    mintNFT(winner, rank);
                }
                
                emit LogWinner(winner, rank, _tokenCount-1);
            }

            unchecked { i++; }
        }
        _prizesAssigned = true;

        _withdraw();

        return true;
    }

    /**
     * @dev Mints a new NFT with a specific rank and assigns it to the lottery operator as 
     * default, used by the lottery operator to mint new collectbiles.
     *
     * Requirements:
     *
     * - msg.sender must be the lottery operator
     * - to address must be the lottery operator (default owner)
    */
    function mint(uint rank) public ownerOnly returns(bool) {
        require(rank > 0 && rank <= 8, "non existent rank (1-8 only)");

        emit LogMint(_owner, rank, _tokenCount);
        mintNFT(_owner, rank);

        return true;
    }

    /**
     * @dev Deactivates the contract.
     * 
     * Requirements:
     *
     * - msg.sender must be the lottery operator
    */
    function closeLottery() public ownerOnly {

        // If round not ended, refund tickets
        if(!_prizesAssigned) {
            for(uint i = 0; i < _players.length;) {
                emit LogTicketRefund(_players[i], _addressToAmount[_players[i]]);
                payable(_players[i]).transfer(_addressToAmount[_players[i]]);
                unchecked { i++; }
            }
        }

        emit LogDeactivation(_withdrawal);

        /* Docs says this is not the best way to deactivate, it's better to
        revert all function called when it becomes inactive
        - https://ethereum.stackexchange.com/questions/82203/how-to-disable-a-contract-by-changing-some-internal-state-which-causes-all-funct
        */
        selfdestruct(payable(_withdrawal));
    }

    /**
     * @dev Checks if a ticket is valid (i.e. no duplicate in standard numbers).
    */
    function _isTicketValid(uint[6] memory ticket) private pure returns(bool) {
        for(uint i = 0; i < 5;) {
            for(uint j = i+1; j < 5;) {
                if(ticket[i] == ticket[j]) {
                    return false;
                }
                unchecked { j++; }
            }
            unchecked { i++; }
        }


        return true;
    }

    /**
     * @dev Computes the rank of the prize to be assigned w.r.t. the match between a ticket and winning numbers.
     *
     * @param <_playerTicket> uint[6] represents the ticket of the player
     *
     * @return uint rank
    */
    function _prizeRank(Ticket memory _playerTicket) private view returns(uint) {
        uint result = 0;
        uint count = 0;
        bool hasPowerBall = false;

        for(uint i = 0; i < 5;) {
            if(_winningNumbersMapping[_playerTicket.numbers[i]]) {
                count++;
            }
            unchecked { i++; }
        }

        if(_playerTicket.numbers[5] == _winningNumbers[5]) {
            hasPowerBall = true;
        }

        if(count == 6) {
            result = 1;
        }
        else if(count == 5 && !hasPowerBall) {
            result = 2;
        }
        else if(count == 5 && hasPowerBall) {
            result = 3;
        }
        else if(count == 4) {
            result = 4;
        }
        else if(count == 3) {
            result = 5;
        }
        else if(count == 2) {
            result = 6;
        }
        else if(count == 1 && !hasPowerBall) {
            result = 7;
        }
        else if(count == 1 && hasPowerBall) {
            result = 8;
        }

        return result;
    }

    /**
     * @dev Transfer the contract balance to the <_withdrawal> address.
     */
    function _withdraw() private {
        emit LogWithdrawal(_withdrawal, address(this).balance);
        payable(_withdrawal).transfer(address(this).balance);
    }
}
