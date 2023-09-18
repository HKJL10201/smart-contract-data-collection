// contracts/Lottery.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./TLToken.sol";

/** @title Lottery
 *  @author Gerrit Gogel, gerrit.gogel@boun.edu.tr, gerrit@gogel.me
 *  @notice This contract implements a decentralized Lottery based on the ERC721 standard. Each lottery ticket is represented by a ERC721 token. Each lottery round consists of two phases: purchase and reveal. At any time accounts can deposit and withdraw TL tokens. The contract holds a balance of those. In the purchase phase the balance can be used to buy tickets. When buying a ticket a random number concatenated with the sending account address has to be hashed with keccak256 has to be provided. In the reveal phase, it can be decided to either refund the ticket for half of the original price or submit the random number. After the random number was submitted the ticket is eligible for winning. When submitting the random number, it is compared with the original hash. Only the original buyer can submit the random number and collect a refund or prize. When the reveal phase is over and the next lottery round has started, users can check if their tickets have won and collect their prize. When a user buys a ticket, a token representing the ticket is transferred to the user. When a refund or prize is collected, the user must transfer the ticket back to the lottery. In each lottery, the whole prize pool is distributed entirely.
 */
contract Lottery is ERC721Enumerable, IERC721Receiver {
    using Counters for Counters.Counter;

    Counters.Counter private _ticketNumber;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(uint => uint[])) internal ownedTickets;
    mapping(uint => uint) internal lotteryNumber;
    mapping(uint => bytes32) internal randomNumberHashes;
    mapping(uint => uint[]) internal randomNumbers;
    mapping(uint => uint[]) internal revealedTicketNumbers;
    mapping(uint => uint) internal xors;
    mapping(uint => uint) internal moneyCollectedInLottery;
    mapping(uint => bool) internal ticketNumberRevealed;


    uint initialLotteryTime;
    uint purchaseInterval;
    uint revealInterval;
    uint ticketPrice;
    TLToken t;

/**
 * @dev This function is called by IERC721.safeTransferFrom whenever an ERC721 is transferred to this contract. This should only happen within the collectTicketPrize and collectTicketRefund functions. If a user would transfer a ticket back to the lottery without calling this functions, the right for refund or winning is forfeit.
 */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        public
        pure
        override
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }



/**
 * @dev Constructor of Lottery.
 * @param _initialLotteryTime unix timestamp in seconds of the beginning of lottery no 0
 * @param _purchaseInterval unix timestamp in seconds, which represents the duration of the purchase phase
 * @param _revealInterval unix timestamp in seconds, which represents the duration of the reveal phase
 * @param _ticketPrice price of one ticket
 * @param _token address of the TLToken
 */
    constructor(uint _initialLotteryTime, uint _purchaseInterval, uint _revealInterval, uint _ticketPrice, address _token) ERC721("Lottery", "LT") {
        t = TLToken(_token);
        initialLotteryTime = _initialLotteryTime;
        purchaseInterval = _purchaseInterval;
        revealInterval = _revealInterval;
        ticketPrice = _ticketPrice;
    }

/**
 * @notice Deposit TL to your lottery balance. Allowance to the lottery contract address greater than or equal to the deposit amount has to be granted first.
 * @dev Adds amount of TL to the users balance by using a transferFrom call.
 * @param amnt TL deposit amount
 */
    function depositTL(uint amnt)
        public
    {
        if(t.transferFrom(msg.sender, address(this), amnt)){
            balances[msg.sender] += amnt;
        }

    }

/**
 * @notice Withdraw TL to your wallet.
 * @dev Withdraws amount of TL from the users balance. First it is checked if the amount is lower than or equal than the current balance or the transaction is reverted. Then the transfer function is used to the transfer the TL tokens and the amount is deducted from the balance.
 * @param amnt TL withraw amount
 */
    function withdrawTL(uint amnt)
        public
    {
        require(amnt <= balances[msg.sender], string(abi.encodePacked("Insufficient account balance. Your account balance is: ", Strings.toString(balances[msg.sender]))));
        if(t.transfer(msg.sender, amnt)){
            balances[msg.sender] -= amnt;
        }
    }

/**
 * @dev Returns the balance of msg.sender.
 * @notice Get your current account balance.
 * @return amnt current balance of the calling account
 */
    function getBalance()
        public
        view
        returns(uint amnt)
    {
        return balances[msg.sender];
    }

/**
 * @notice Buy a lottery ticket using your balance. Sufficient balance has to be in the account. The purchase phase has to be active. The hash value submitted, has to be a random number concatenated with the sender's address and hashed with keccak256. This can be done with soliditySha3(rnd_number,address) in JS or keccak256(rnd_number,address)) in Solidity. The bought ticket will be transferred to your wallet.
 * @dev The sender has to submit a hash value, which is a random number concatenated with the sender's address and hashed with keccak256. This can be done with soliditySha3(rnd_number,address) in JS or keccak256(rnd_number,address)) in Solidity. It requires the purchase phase to be active and the a balance larger than or equal than the ticket price. The tokenId equals the ticket number and is counted with the _ticketNumber counter. The token is minted to the sender. Then the balance is deducted by ticketPrice. The ticket number is added to ownedTickets. The submitted hash is saved in randomNumberHashes mapped with the ticket number. The moneyCollectedInLottery value of the current lottery is increased by ticket price. The lottery number of ticket is saved in the lotteryNumber mapping. The _ticketNumber counter is incremented.
 * @param hash_rnd_number hash of random number and sender address
 */
    function buyTicket(bytes32 hash_rnd_number)
        public
    {
        require(isPurchaseActive(), "Purchase phase is currently not active.");
        require(balances[msg.sender] >= ticketPrice, string(abi.encodePacked("Insufficient account balance. Your account balance is: ", Strings.toString(balances[msg.sender]))));

        uint newTicketNumber = _ticketNumber.current();

        _safeMint(msg.sender, newTicketNumber);

        balances[msg.sender] = balances[msg.sender] - ticketPrice;
        ownedTickets[msg.sender][getLotteryNo(block.timestamp)].push(newTicketNumber);
        randomNumberHashes[newTicketNumber] = hash_rnd_number;
        moneyCollectedInLottery[getLotteryNo(block.timestamp)] += ticketPrice;
        lotteryNumber[newTicketNumber] = getLotteryNo(block.timestamp);
        _ticketNumber.increment();
    }


/**
 * @notice Collect a refund for a ticket. The reveal phase of the lottery, where the ticket has been bought, has to be active and the random number of ticket must not have been submitted. Half of the original ticket price will be refunded. You must be the owner of the ticket and the ticket will be transferred back to the lottery.
 * @dev It is required that the reveal phase of the lottery, where the ticket has been bought is active. It is further required that the random number for the ticket was not revealed yet, which is checked with the ticketNumberRevealed mapping. The ticket is transferred to the lottery contract using safeTransferFrom. If the sender is not the owner of the ticket, the transaction will be reverted. The balance of the sender is increased by half of ticketPrice. The randomNumberHash for the ticket is deleted. moneyCollectedInLottery is deducted by half of the ticketPrice. The ticket is looked up in ownedTickets and deleted.
 * @param ticket_no ticket number to be refunded
 */
    function collectTicketRefund(uint ticket_no)
        public
    {
        require(isRevealActive(), "Reveal phase is not active.");
        require(lotteryNumber[ticket_no] == getLotteryNo(block.timestamp), "Ticket is not from active lottery and can therefore not be refunded anymore.");
        require(ticketNumberRevealed[ticket_no] == false, "The random number for this ticket was already revealed.");

        safeTransferFrom(msg.sender, address(this), ticket_no);

        balances[msg.sender] = balances[msg.sender] + (ticketPrice / 2);
        delete randomNumberHashes[ticket_no];
        moneyCollectedInLottery[getLotteryNo(block.timestamp)] -= (ticketPrice / 2);
        for (uint i=0; i < ownedTickets[msg.sender][getLotteryNo(block.timestamp)].length; i++) {
            if(ownedTickets[msg.sender][getLotteryNo(block.timestamp)][i] == ticket_no){
                delete ownedTickets[msg.sender][getLotteryNo(block.timestamp)][i];
                break;
            }
        }
    }

/**
 * @notice Reveal the random number for the ticket, making the ticket eligible for winning. The reveal phase of the lottery, where ticket was bought, has to be active.
 * @dev It is required that the reveal phase of the lottery, where the ticket has been bought is active. It is further required that the random number for the ticket was not revealed yet, which is checked with the ticketNumberRevealed mapping. The hash of the submitted random number and the sender address is generated and compared with original value at purchase. The ticketno is added to the revealedTicketNumbers mapping for the current lottery. The xors mapping is used to store the value of XOR over all revealed random numbers. The current valued is XORed with the submitted random number. In the ticketNumberRevealed mapping the value of the ticket number is set to true.
 * @param ticketno ticket number to be revealed
 * @param rnd_number random number to be revealed (must match random number submitted at purchase)
 */
    function revealRndNumber(uint ticketno, uint rnd_number)
        public
    {
        require(isRevealActive(), "Reveal phase is currently not active.");
        require(lotteryNumber[ticketno] == getLotteryNo(block.timestamp), "Reveal phase for this ticket has already ended.");
        require(ticketNumberRevealed[ticketno] == false, "The random number for this ticket was already revealed.");

        bytes32 hash_rnd_number = keccak256(abi.encodePacked(rnd_number, msg.sender));
        require(hash_rnd_number == randomNumberHashes[ticketno], "Random number or sender does not match value submitted at purchase.");

        revealedTicketNumbers[getLotteryNo(block.timestamp)].push(ticketno);
        xors[getLotteryNo(block.timestamp)] = xors[getLotteryNo(block.timestamp)] ^ rnd_number;
        ticketNumberRevealed[ticketno] = true;
    }

/**
 * @notice Get the last owned ticket in given lottery number.
 * @dev It is required that the sender owns any ticket in the given lottery number. Then the last element of ownedTickets for the sender in the given lottery is returned. Status 1 is returned when a ticket was found.
 * @param lottery_no lottery number
 * @return last owned ticket number
 * @return status 1 if ticket exists, 0 if not
 */
    function getLastOwnedTicketNo(uint lottery_no)
        public
        view
        returns(uint,uint8 status)
    {
        require(ownedTickets[msg.sender][lottery_no].length > 0, string(abi.encodePacked("You do not own any tickets in lottery number ", Strings.toString(lottery_no))));

        return(ownedTickets[msg.sender][lottery_no][ownedTickets[msg.sender][lottery_no].length - 1], 1);
    }

/**
 * @notice Get the ticket with index i for the given lottery number.
 * @dev It is required that the sender owns any ticket in the given lottery number. It is required that the number of tickets owned by the sender in the lottery is larger than the index. Then the index i of ownedTickets for the sender in the given lottery is returned. Status 1 is returned when a ticket with index i was found.
 * @param i index (starting from 0)
 * @param lottery_no lottery number
 * @return ticket number with index i
 * @return status 1 if ticket exists, 0 if not
 */
    function getIthOwnedTicketNo(uint i,uint lottery_no)
        public
        view
        returns(uint,uint8 status)
    {
        require(ownedTickets[msg.sender][lottery_no].length > 0, string(abi.encodePacked("You do not own any tickets in lottery number ", Strings.toString(lottery_no))));
        require(ownedTickets[msg.sender][lottery_no].length > i,  string(abi.encodePacked("You do not own a ticket with index ", Strings.toString(i), " in lottery number", Strings.toString(lottery_no))));

        return(ownedTickets[msg.sender][lottery_no][i], 1);
    }

/**
 * @notice Check the prize amount a ticket number has won. The lottery round, where the ticket was purchased, has to be finished.
 * @dev It is required that the requested ticket number exists. It is required that the lottery round, where the ticket was purchased, is finished. The function does allow to check ticket numbers, that have been refunded. The total number of winning tickets (iMax) is calculated from the total money collected in the lottery round. getIthWinningTicket is called iMax times and if it matches the requested ticket number, the prize amount is accumulated.
 * @param ticket_no ticket number
 * @return amount prize amount
 */
    function checkIfTicketWon(uint ticket_no)
        public
        view
        returns (uint amount)
    {
        require(ticket_no < _ticketNumber.current(), "A ticket with the submitted number does not exist yet.");
        require(lotteryNumber[ticket_no] < getLotteryNo(block.timestamp), "Lottery round of this ticket has not finished yet.");

        uint M =  getTotalLotteryMoneyCollected(lotteryNumber[ticket_no]);
        uint iMax = log2(M) + 1;

        for(uint i = 1; i <= iMax; i++) {
            (uint w, uint a) = getIthWinningTicket(i, lotteryNumber[ticket_no]);
            if(w == ticket_no){
                amount += a;
            }
        }
    }



/**
 * @notice Collect the ticket prize for given ticket number. You must be the owner of the ticket and the ticket will be transferred back to the lottery.
 * @dev It is required that the requested ticket number exists. It is required that the lottery round, where the ticket was purchased, is finished. safeTransferFrom is used to transfer the ticket back to the lottery. If the sender is not the owner of the ticket, the transaction will be reverted. checkIfTicketWon is used to add the prize amount to the sender's balance. The ticket is looked up in ownedTickets and deleted.
 * @param ticket_no ticket number
 */
    function collectTicketPrize(uint ticket_no)
        public
    {
        require(ticket_no < _ticketNumber.current(), "A ticket with the submitted number does not exist yet.");
        require(lotteryNumber[ticket_no] < getLotteryNo(block.timestamp), "Lottery round of this ticket has not finished yet.");


        safeTransferFrom(msg.sender, address(this), ticket_no);
        balances[msg.sender] += checkIfTicketWon(ticket_no);
        for (uint i=0; i < ownedTickets[msg.sender][lotteryNumber[ticket_no]].length; i++) {
            if(ownedTickets[msg.sender][lotteryNumber[ticket_no]][i] == ticket_no){
                ownedTickets[msg.sender][lotteryNumber[ticket_no]][i] = ownedTickets[msg.sender][lotteryNumber[ticket_no]][ownedTickets[msg.sender][lotteryNumber[ticket_no]].length - 1];
                ownedTickets[msg.sender][lotteryNumber[ticket_no]].pop();
                break;
            }
        }

    }

/**
 * @notice Get the i-th winning ticket for a given lottery number.
 * @dev It is required that the lottery round, where the ticket was purchased, is finished. The total number of winning tickets (iMax) is calculated from the total money collected in the lottery round. It is required that i is lower than or equal than iMax. The prize amount for i-th winning ticket is calculated. The XOR value of all submitted random numbers is hashed i times using keccak256 and saved in the variable magic. The winning ticket number is determined by taking magic modulo the amount of revealed random numbers.
 * @param i winning ticket index (starting with 1)
 * @param lottery_no lottery number
 * @return ticket_no ticket number of i-th ticker number
 * @return amount prize amount
 */
    function getIthWinningTicket(uint i, uint lottery_no)
        public
        view
        returns (uint ticket_no,uint amount)
    {
        require(lottery_no < getLotteryNo(block.timestamp), "Lottery round has not finished yet.");

        uint M =  getTotalLotteryMoneyCollected(lottery_no);
        uint iMax = log2(M) + 1;

        require(i <= iMax, string(abi.encodePacked("Winning ticket with index ", Strings.toString(i), " does not exist.")));
        require(i >= 1, "i should be larger than or equal 1");

        amount = (M / 2**i) + ((M / 2**(i-1)) % 2);

        uint magic = xors[lottery_no];

        for(uint j = 0; j < i; j++){
            magic = uint(keccak256(abi.encodePacked(magic)));
        }

        ticket_no = revealedTicketNumbers[lottery_no][magic % revealedTicketNumbers[lottery_no].length];
    }

/**
 * @notice Get the lottery number for a given unix timestamp.
 * @dev The lottery number is determined with the initialLotteryTime, pruchaseInterval and revealInterval.
 * @param unixtimeinweek unix time stamp in seconds
 */
    function getLotteryNo(uint unixtimeinweek)
        public
        view
        returns (uint lottery_no)
    {
        return (unixtimeinweek - initialLotteryTime) / (purchaseInterval + revealInterval);
    }

/**
 * @notice Returns the total money collected in a given lottery.
 * @dev Requires the lottery to have started. Then returns the total money collected, which is saved in the mapping moneyCollectedInLottery.
 * @param lottery_no lottery number
 * @return amount total money collected
 */
    function getTotalLotteryMoneyCollected(uint lottery_no)
        public
        view
        returns (uint amount)
    {
        require(lottery_no <= getLotteryNo(block.timestamp), "Lottery round has not started yet.");
        return moneyCollectedInLottery[lottery_no];
    }

/**
 * @notice Check if the purchase phase is currently active.
 * @dev Calculates if the purchase phase is currently active using initialLotteryTime, pruchaseInterval and revealInterval.
 * @return active true if purchase phase is active
 */
    function isPurchaseActive()
        public
        view
        returns (bool active)
    {
        active = block.timestamp - getLotteryNo(block.timestamp) * (purchaseInterval + revealInterval) - initialLotteryTime <= purchaseInterval;
    }

/**
 * @notice Check if the reveal phase is currently active.
 * @dev Calculates if the reveal phase is currently active using initialLotteryTime, pruchaseInterval and revealInterval.
 * @return active true if reveal phase is active
 */
    function isRevealActive()
        public
        view
        returns (bool active)
    {
        active = block.timestamp - getLotteryNo(block.timestamp) * (purchaseInterval + revealInterval) - initialLotteryTime > purchaseInterval;
    }

/**
 * @dev Internal function that returns the ceiling of log2 for an unsigned integer. Uses the De Bruijn method and is very efficient. gas < 700 From: https://ethereum.stackexchange.com/a/30168
 * @param x log2(x)
 * @return y y=log(2x)
 */
    function log2(uint x)
        internal
        pure
        returns (uint y)
    {
        assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }
    }

}
