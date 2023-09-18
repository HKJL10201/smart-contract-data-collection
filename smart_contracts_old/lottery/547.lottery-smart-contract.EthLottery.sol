pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title EthLottery
 */
contract EthLottery is Ownable {
    using SafeMath for uint;
    
    struct Ticket {
        address holder;
        uint ref;
        uint winAmt;
        bool paid;
    }
    
    uint[] private lotterySteps = [1000, 10000, 100000, 500000, 1000000, 5000000, 10000000];
    uint private latestBlockNumber;
    bytes32 private cumulativeHash;
     
    uint public threshold;
    uint public currentTicket;
    uint public currentStepStart;
    uint public ticketPrice;
    bool public isLotteryRunning;
    uint public houseEdge;
    uint public referralShare;
    uint public soldTickets;
    uint public lastWinTicket;
    
    mapping (uint => Ticket) tickets;
    mapping (address => uint) wallets;
    
    event BuyTicket(uint ticketNum, address holder, uint count);
    event Withdraw(uint ticketNum, address holder, address withdraw, uint amount);
    event WithdrawAll(address holder, address withdraw, uint amount);
    event DrawnWinner(uint ticketNum);
    event AdminPauseLottery();
    event AdminResumeLottery();
    event AdminSetHouseEdge(uint amount);
    event AdminSetRefShare(uint amount);
    event AdminSetTktPrice(uint price);
    
    // authorize if lottery is running
    modifier isRunning() {
        require(isLotteryRunning == true);
        _;
    }
    
    // authorize if lottery is paused
    modifier isPaused() {
        require(isLotteryRunning == false);
        _;
    }
    
    // authorize when referral ticket number is valid; 0: no ref 
    modifier isValidRef(uint ref) {
        require(ref == 0 || tickets[ref].holder != address(0x0));
        _;
    }
    
    constructor () public {
        isLotteryRunning = true;
        ticketPrice = 1 finney;
        latestBlockNumber = block.number;
        cumulativeHash = bytes32(0);
        threshold = 1000;
        currentTicket = 0;
        currentStepStart = 1;
        houseEdge = 30;
        referralShare = 10;
    }
    
    /**
     * @dev function to buy ticket
     * @notice {_refTicket} is referral ticket number, if its 0, it implies non-referral
     */ 
    function buyTicket(uint _refTicket) public payable isRunning isValidRef(_refTicket) {
        require(msg.value == ticketPrice);
        require(soldTickets < threshold);
        
        currentTicket ++;
        soldTickets ++;
        
        tickets[currentTicket] = Ticket({
            holder: msg.sender,
            ref: _refTicket,
            winAmt: 0,
            paid: false
        });
        
        // if soldTickets reached to threshold, draw winner of current step
        if (soldTickets == threshold) {
            drawWinner();
        }
        
        cumulativeHash = keccak256(blockhash(latestBlockNumber), cumulativeHash);
        latestBlockNumber = block.number;
        
        emit BuyTicket(currentTicket, msg.sender, 0);
    }     
    
    /**
     * @dev function to buy bulk tickets at once
     * @param _count count of tickets to buy
     * @param _refTicket ticket number of referral
     */ 
    function buyBulkTickets(uint _count, uint _refTicket) public payable isRunning isValidRef(_refTicket) {
        require(msg.value == ticketPrice * _count);
        require(soldTickets < threshold);
        
        uint i = 0;
        for (i = 0; i < _count; i++) {
            currentTicket ++;
            soldTickets ++;
            
            tickets[currentTicket] = Ticket({
                holder: msg.sender,
                ref: _refTicket,
                winAmt: 0,
                paid: false
            });
            
            if (soldTickets == threshold) {
                break;
            }
            
            cumulativeHash = keccak256(blockhash(latestBlockNumber), cumulativeHash);
            latestBlockNumber = block.number;
        }
        
        if (soldTickets == threshold) {
            isLotteryRunning = false;
            drawWinner();
        }
        
        emit BuyTicket(currentTicket, msg.sender, i + 1);
    }
    
    /**
     * @dev function to withdraw win amount for specific ticket belongs to msg.sender
     * @param _withdraw withdraw address
     * @param _tktNum ticket number that will be withdraw from
     */ 
    function withdraw(address _withdraw, uint _tktNum) public {
        // check withdraw address is valid
        require(_withdraw != address(0x0));
        // check ticket holder is msg.sender
        require(tickets[_tktNum].holder == msg.sender);
        // check ticket winning amount was already paid
        require(tickets[_tktNum].paid == false);
        // check the ticket was won and wallet balance amount is enough
        require(tickets[_tktNum].winAmt > 0 && wallets[msg.sender] >= tickets[_tktNum].winAmt);
        
        uint amount = tickets[_tktNum].winAmt;
        
        // update balances, paid status before sending to withdraw
        tickets[_tktNum].paid = true;
        wallets[msg.sender] = wallets[msg.sender].sub(amount);
        
        // transfer to withdraw address
        if (!_withdraw.send(amount)) revert();
        
        emit Withdraw(_tktNum, msg.sender, _withdraw, amount);
    }
    
    /**
     * @dev function to withdraw balances
     * @param _withdraw withdraw address
     */
    function withdrawAll(address _withdraw) public {
        // check withdraw address is valid
        require(_withdraw != address(0x0));
        // check wallet is exist for msg.sender
        require(wallets[msg.sender] > 0);
        
        uint amount = wallets[msg.sender];
        // empty wallet
        wallets[msg.sender] = 0;
        
        // update all relevant tickets as paid
        for (uint i = 0; i < currentTicket; i++) {
            if (tickets[i].holder == msg.sender && tickets[i].winAmt > 0) {
                tickets[i].paid = true;
            }
        }
        
        // transfer to withdraw address 
        if (!_withdraw.send(amount)) revert();
        
        emit WithdrawAll(msg.sender, _withdraw, amount);
    }
    
    function getTicketInfo(uint _tktNum) public constant returns (uint, uint, bool) {
        // authorize for only msg.sender is ticket holder
        require(tickets[_tktNum].holder == msg.sender);
        return (tickets[_tktNum].ref, tickets[_tktNum].winAmt, tickets[_tktNum].paid);
    }
    
    function getBalance() public constant returns (uint) {
        return wallets[msg.sender];
    }
    
    // internal functions (private)
    /**
     * @dev function to pich random winner 
     */ 
    function drawWinner() internal {
        require(soldTickets <= threshold && soldTickets > 0);
        latestBlockNumber = block.number;
        bytes32 _finalHash = keccak256(blockhash(latestBlockNumber - 1), cumulativeHash);
        
        // pick random integer between ( currentStepStart, currentStepStart + soldTickets )
        uint256 _randomInt = uint256(_finalHash) % soldTickets + currentStepStart;
        lastWinTicket = _randomInt;
        Ticket memory winTicket = tickets[_randomInt];
        
        uint totalAmount = soldTickets * ticketPrice;
        uint winAmount = 0;
        uint refAmount = 0;
        uint feeAmount = (uint)(totalAmount * houseEdge / 100);
        
        if (winTicket.ref != 0) {
            winAmount = (uint)(totalAmount * (100 - houseEdge) * (100 - referralShare) / 10000);
            refAmount = (uint)(totalAmount * (100 - houseEdge) * referralShare / 10000);
        } else {
            winAmount = (uint)(totalAmount * (100 - houseEdge) / 100);
        }
        
        // allocate winning amount
        tickets[_randomInt].winAmt = winAmount;
        wallets[winTicket.holder] = wallets[winTicket.holder].add(winAmount);
        
        // allocate referral share
        if (refAmount > 0) {
            Ticket memory refTicket = tickets[winTicket.ref]; 
            wallets[refTicket.holder] = wallets[refTicket.holder].add(refAmount);
        }
        
        // commission fee
        if (!owner.send(feeAmount)) revert();
        
        emit DrawnWinner(_randomInt);
        // upgrade lottery to next turn
        initLottery();
    }
    
    /**
     * @dev function to reset and move lottery to next step
     */ 
    function initLottery() internal {
        isLotteryRunning = true;
        latestBlockNumber = block.number;
        cumulativeHash = bytes32(0);
        soldTickets = 0;
        setNextThreshold();
    }
    
    /**
     * @dev function to set next threshold and start number
     */ 
    function setNextThreshold() internal {
        if (threshold < 1000 || threshold > 10000000) {
            currentStepStart = 1;
            threshold = 1000;
        } else {
            for (uint i = 0; i < lotterySteps.length; i++) {
                if (threshold == lotterySteps[i]) {
                    if (i == lotterySteps.length - 1) {
                        currentStepStart = 1;
                        threshold = lotterySteps[0];
                    } else {
                        currentStepStart = threshold + 1;
                        threshold = lotterySteps[i + 1];
                    }
                    break;
                }
            }    
        }
    }
    
    /// administrative functions
    function drawManually() public onlyOwner {
        isLotteryRunning = false;
        drawWinner();
    }
    
    function pauseLotteryEmergency() public onlyOwner isRunning {
        isLotteryRunning = false;
        emit AdminPauseLottery();
    }
    
    function resumeLotteryFromEmergency() public onlyOwner isPaused {
        isLotteryRunning = true;
        emit AdminResumeLottery();
    }
    
    function setHouseEdge(uint _amount) public onlyOwner isPaused {
        houseEdge = _amount;
        emit AdminSetHouseEdge(_amount);
    }
    
    function setReferralShare(uint _amount) public onlyOwner isPaused {
        referralShare = _amount;
        emit AdminSetRefShare(_amount);
    }
    
    function setTicketPrice(uint _price) public onlyOwner isPaused {
        ticketPrice = _price;
        emit AdminSetTktPrice(_price);
    }
    
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
 }