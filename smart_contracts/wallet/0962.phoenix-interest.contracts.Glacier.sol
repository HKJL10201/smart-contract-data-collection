pragma solidity >=0.4.0 <0.6.0;

import "./Formula.sol";
import "./SnowflakeResolver.sol";
import "./zeppelin/math/SafeMath.sol";
import "./interfaces/PhoenixInterface.sol";
import "./interfaces/SnowflakeInterface.sol";
import "./interfaces/IdentityRegistryInterface.sol";

/**
 * @title Snowflake Glacier
 * @notice Create interest-bearing escrow through Snowflake
 * @dev This contract is the base of the Phoenix-Glacier dApp
 */

contract Glacier is SnowflakeResolver, Formula 
{   
    using SafeMath for uint;

    /* Constants based on the following,
     * average blocktime = 15.634 secs;
     * source: etherscan.io/chart/blocktime
    */
    // [ (60/15.634)*60*24 ] * 1000
    uint32 constant blocksPerDay = 5526417; 
    // [ (60/15.634)*60*24*7 ] * 1000
    uint32 constant blocksPerWeek = 38684917; 
    // [ (60/15.634)*60*24*30.4375 ] * 1000
    uint32 constant blocksPerMonth = 168210311; 
    // [ (60/15.634)*60*24*(365.25) ] * 1000
    uint32 constant blocksPerYear = 2018523730; 

    enum Status { Created, Released, Owed, Repaid }

    enum Schedule { 
        Infinitely, //index 0
        Hourly, Daily, Weekly,
        Fortnightly, Monthly, 
        Quadannually, Triannually, 
        Biannually, Annually, 
        Biennially, Triennially, 
        Quadrennially //index 12
    } 
    
    uint public debtIndex;

    /* for each seller of debt (payee), easily look up
     * any of their debts through the id of the debt
    */ 
    mapping (uint => mapping(uint => Debt)) debts;

    /* for given debt id return the address of the payee
     * who owns the debt: in a loan this is the lender, 
     * in savings this is the depositor 
    */ 
    mapping (uint => uint256) debtToPayee;
    // for given debt id return the address of the Escrow
    mapping (uint => address) debtToEscrow;

    struct Debt {
        uint     id;
        Status   status; // for keeping track of debt lifecycle
        uint     created; // block number of when created
        uint32   end; // duration of the loan period, in blocks
        
        /* amount payable to payee each schedule iteration, from
         * the cost of debt expressed in absolute terms; ie the
         * total amount that payer must lock up in escrow before
         * payee may release their principal.
        */ 
        uint     payment; 
        
        // schedule for interest payments and principal repayment
        Schedule payments; 
        uint     nextPayment; // block number for next payment
        uint32   numPayments; // the number of payments to be made until endDate
        uint32   payInterval; // the number of blocks between payments

        Schedule accruals; // schedule for interest accrual
        uint32   accrualInterval; // the number of blocks between accruals

        /* amout of principal repaid by payer, decreases as
         * principal is repaid by payer
        */ 
        uint     principal;
        
        /* amount of interest escrowed by payer, decreases as 
         * interest payments proceed according to schdule
        */
        uint     interest; 

        /* the buyer of debt; 
         * in a loan this is the borrower,
         * in savings this is the lender
        */ 
        uint     payer; 

        /* the cost of debt expressed in annual percentage yield;
         * paid either to lender (when loaning) or depositor (when saving)
         * represented as percent (eg 42 %)
        */ 
        uint     apr;
        Schedule duration;
    }

    event InterestPaid( 
        uint indexed payee,
        uint indexed debtID
    );

    event InterestLocked(
        uint indexed payee, 
        uint indexed debtID, 
        uint payer,
        uint amount
    );

    event ReleasePrincipal(
        uint indexed payee,
        uint indexed debtID,
        uint amount
    );

    event LockPrincipal(
        uint indexed payee,
        uint indexed debtID,
        uint amount
    );

    event RepayPrincipal(
        uint indexed payee,
        uint indexed debtID,
        uint payer,
        uint amount
    );

    // the payer or the payee may impose changes to the terms
    event Rearrangement(
        uint indexed payee,
        uint indexed debtID,
        string parameter
    );

    event DebtCreated(
        uint indexed payee,
        uint indexed debtID
    );

    constructor (address snowflakeAddress) public 
    SnowflakeResolver("Glacier", "Interest-bearing Escrow on Snowflake", 
    snowflakeAddress, false, false) { debtIndex = 0; }

    /**
     * @dev Create ledger entry for debt 
     * @param apr the APR for the debt
     * ^ once set, cannot be edited or modified.
     * defaults for other debt parameters are: 
     * accrual daily, payment monthly, 1 year end date, 
     */
    function setInterest(uint apr) public {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

        uint256 ein = identityRegistry.getEIN(msg.sender);
        require(identityRegistry.isResolverFor(ein, address(this)), "ein has not set this resolver");

        debtIndex += 1;
        
        Debt memory debt = Debt(
            debtIndex, Status.Created, block.timestamp,
            0, 0, // loan duration in blocks, cost of debt
            Schedule.Monthly, 0, 0, 0, // payments parameters
            Schedule.Daily, 0, // accrual parameters
            0, 0, 0, // principal, interest, payer EIN
            apr, Schedule.Annually // annual percentage rate, loan duration
        );
        debtToPayee[debtIndex] = ein;
        debts[ein][debtIndex] = debt;

        emit DebtCreated(ein, debtIndex);
    }

    /**
     * @dev Lock principal into escrow
     * @param debtID id of the debt
     * @param amount in PHNX to lock
     */
    function lockPrincipal(uint debtID, uint amount) public {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

        uint256 ein = identityRegistry.getEIN(msg.sender);
        require(identityRegistry.isResolverFor(ein, address(this)), "ein has not set this resolver");
        require(ein == debtToPayee[debtID], "only the payee may lock principal");
        
        Debt memory debt = debts[ein][debtID];
        require(debt.status == Status.Created, "cannot lock more principal after it was released");
        require(debt.payInterval > 0 && debt.accrualInterval > 0, "set payment and accrual schedules first");

        debt.principal = debt.principal.add(amount);
        snowflake.withdrawSnowflakeBalanceFrom(ein, address(this), amount);

        uint accrualsPerAPR = blocksPerYear / debt.accrualInterval;
        uint aprPlusOne = debt.apr + 100 * accrualsPerAPR;
        
        debt.payment = calculateInterest( 
            aprPlusOne, 
            accrualsPerAPR, 
            debt.principal, 
            debt.payInterval, 
            debt.accrualInterval
        );
        debts[ein][debtID] = debt;

        emit LockPrincipal(ein, debtID, amount);
    }

    function getInterval(uint8 s) internal pure returns (uint32) {
        require(s < 13, "incomprehensible schedule");
        uint32 interval = 0;
        if      (Schedule(s) == Schedule.Hourly)        interval = blocksPerDay / 24;
        else if (Schedule(s) == Schedule.Daily)         interval = blocksPerDay;
        else if (Schedule(s) == Schedule.Weekly)        interval = blocksPerWeek;
        else if (Schedule(s) == Schedule.Fortnightly)   interval = blocksPerWeek * 2;
        else if (Schedule(s) == Schedule.Monthly)       interval = blocksPerMonth;
        else if (Schedule(s) == Schedule.Quadannually)  interval = blocksPerYear / 4;
        else if (Schedule(s) == Schedule.Triannually)   interval = blocksPerMonth * 4;
        else if (Schedule(s) == Schedule.Biannually)    interval = blocksPerYear / 2;
        else if (Schedule(s) == Schedule.Annually)      interval = blocksPerYear;
        else if (Schedule(s) == Schedule.Biennially)    interval = blocksPerYear * 2;
        else if (Schedule(s) == Schedule.Triennially)   interval = blocksPerYear * 3;
        else if (Schedule(s) == Schedule.Quadrennially) interval = blocksPerYear * 4;
        return  interval;
    }

    /**
     * @dev Set the Accrual Schedule
     * @param debtID the id of the debt
     * @param _accruals the Schedule enum
     */
    function setAccruals(uint debtID, uint8 _accruals) public {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

        uint256 ein = identityRegistry.getEIN(msg.sender);
        require(identityRegistry.isResolverFor(ein, address(this)), "ein has not set this resolver");
        require(ein == debtToPayee[debtID], "only payee can change accrual schedule");
        require(_accruals < 12, "cannot accrue inifitely");

        Debt memory debt = debts[ein][debtID];
        require(debt.status == Status.Created, "cannot change accrual schedule after principal released");
        
        debt.accrualInterval = getInterval(_accruals);
        require(debt.accrualInterval <= blocksPerYear, "accruals cannot be more frequent than annual");
        
        if (debt.payInterval > 0)
            require(debt.accrualInterval <= debt.payInterval, "accrual more frequent than payment schedule");

        debt.accruals = Schedule(_accruals);
        debts[ein][debtID] = debt;

        emit Rearrangement(ein, debtID, "setAccruals");
    }

    /**
     * @dev Set the Payment Schedule, to be signed via PhoenixAuthentication,
     * determining how often interest payments are made to payee
     * @param debtID the id of the debt
     * @param _payments the Schedule enum
     */
    function setPayments(uint debtID, uint8 _payments) public {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

        uint256 ein = identityRegistry.getEIN(msg.sender);
        require(identityRegistry.isResolverFor(ein, address(this)), "ein has not set this resolver");
        require(ein == debtToPayee[debtID], "only payee can change payment schedule");
        require(_payments < 12, "cannot have inifite payments");
        
        Debt memory debt = debts[ein][debtID]; 
        require(debt.status == Status.Created, "cannot change payment schedule after principal released");

        debt.payInterval = getInterval(_payments); 
        require(debt.payInterval >= debt.accrualInterval, "accrual more frequent than payment schedule");
        
        if (debt.end > 0) {
            require(debt.payInterval <= debt.end, "pay interval must be less than / equal to end date");
            debt.numPayments = debt.end / debt.payInterval;
        }
        debt.payments = Schedule(_payments);
        debts[ein][debtID] = debt;

        emit Rearrangement(ein, debtID, "setPayments");
    }

    /**
     * @dev Set the End date when principal should be sent back to payer
     * @param debtID the id of the debt
     * @param _duration the duration of the loan
     */
    function setDuration(uint debtID, uint8 _duration, uint8 escrowed) public {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

        uint256 ein = identityRegistry.getEIN(msg.sender);
        require(identityRegistry.isResolverFor(ein, address(this)), "ein has not set this resolver");

        uint256 payee = debtToPayee[debtID];
        Debt memory debt = debts[payee][debtID]; 
        require(debt.status == Status.Created, "cannot change payment schedule after principal released");
        
        require(ein == payee || ein == debt.payer, "sender is not payee or payer");
        debt.end = getInterval(_duration);

        if (debt.payInterval > 0) {
            require(debt.end >= debt.payInterval, "pay interval must be less than / equal to end date");
            if (debt.end > 0)
                debt.numPayments = debt.end / debt.payInterval;
            else { //Inifinite loan period (perpetual savings account) 
                require(escrowed > 0, "specify number of interest payments to be locked in escrow");
                debt.numPayments = escrowed; 
            }
        }
        debt.duration = Schedule(_duration);
        debts[payee][debtID] = debt;  

        emit Rearrangement(ein, debtID, "setDuration"); 
    }

    /** 
     * @dev Lock interest into escrow
     * @param debtID id of the debt
     * @param amount of PHNX to lock
     * Principal may be issued only when sufficient
     * interest is locked in escrow as collateral.
     */
    function lockInterest(uint debtID, uint amount) public {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

        uint256 ein = identityRegistry.getEIN(msg.sender);
        require(identityRegistry.isResolverFor(ein, address(this)), "ein has not set this resolver");
        
        uint256 payee = debtToPayee[debtID];
        Debt memory debt = debts[payee][debtID];
        require(debt.status == Status.Created || debt.status == Status.Released, "cannot lock more interest ");

        if (debt.payer == 0) {
            require(ein != payee, "payer cannot be the payee");
            debt.payer = ein;
        } else 
            require(ein == debt.payer, "sender is not the payer");
        
        uint totalCost = debt.payment * debt.numPayments;
        debt.interest = debt.interest.add(amount);
        
        require(debt.interest <= totalCost, "cannot lock more interest than due");
        snowflake.withdrawSnowflakeBalanceFrom(ein, address(this), amount);

        if (debt.interest == totalCost && debt.status == Status.Created) {
            debt.nextPayment = block.number + (debt.payInterval / 1000);
            withdrawPhoenixBalanceTo(msg.sender, debt.principal);
            debt.status = Status.Released;
        }    
        debts[payee][debtID] = debt;

        emit InterestLocked(payee, debtID, debt.payer, amount);
    }

    /** 
     * @dev Payer may withdraw interest from escrow
     * in the event of disagreement with lender before
     * principal is released
     * @param debtID id of the debt
    */    
    function withdrawInterest(uint debtID) public {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

        uint256 ein = identityRegistry.getEIN(msg.sender);
        require(identityRegistry.isResolverFor(ein, address(this)), "ein has not set this resolver");
        
        uint256 payee = debtToPayee[debtID];
        Debt memory debt = debts[payee][debtID];
        
        require(ein == debt.payer, "sender is not the payer");
        require(debt.status == Status.Created, "can't release interest after principal was released");
        require(debt.interest > 0, "no interest to release");

        withdrawPhoenixBalanceTo(msg.sender, debt.interest);

        debt.interest = 0;
        debts[payee][debtID] = debt;

        emit Rearrangement(ein, debtID, "dispute");
    }

    /** 
     * @dev Pay interest to payee according to payment schedule
     * @param debtID id of the debt
     */
    function payInterest(uint debtID) public {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

        uint256 ein = identityRegistry.getEIN(msg.sender);
        require(identityRegistry.isResolverFor(ein, address(this)), "ein has not set this resolver");
        
        require(ein == debtToPayee[debtID], "only payee may receive interest payments");
        
        Debt memory debt = debts[ein][debtID];
        require(debt.interest >= debt.payment, "no more interest payments for this debt");
        require(
            debt.status == Status.Released || debt.status == Status.Repaid, 
            "cannot pay interest already paid out, or before principal was released"
        );

        bool tooEarly = debt.nextPayment > block.number;
        bool tooLate = block.number > (debt.nextPayment + 42); // nearly 11 min grace period
        require(!tooEarly && !tooLate, "payment too early/late");

        withdrawPhoenixBalanceTo(msg.sender, debt.payment); // release from escrow to payee
        
        debt.nextPayment += debt.payInterval / 1000; // set next payment deadline
        
        debt.interest -= debt.payment;

        if (debt.interest == 0)
            if (debt.status != Status.Repaid)
                debt.status = Status.Owed;
        
        debts[ein][debtID] = debt;

        emit InterestPaid(ein, debtID);
    }

    /**
     * @dev Payer repays the principal owed on the debt
     * unlike interest payments, may flow around schedule
     * @param debtID the id of the debt
     * @param amount in PHNX of principal to repay
     */
    function repay(uint debtID, uint amount) public {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

        uint256 ein = identityRegistry.getEIN(msg.sender);
        require(identityRegistry.isResolverFor(ein, address(this)), "ein has not set this resolver");
        
        uint256 payee = debtToPayee[debtID];
        Debt memory debt = debts[payee][debtID];
        require(ein == debt.payer, "sender is not the payer");

        require(
            debt.status == Status.Released || debt.status == Status.Owed, 
            "can't repay principal already repaid, or before it was released"
        );

        debt.principal = debt.principal.sub(amount);

        snowflake.transferSnowflakeBalanceFrom(ein, payee, amount);

        if (debt.principal == 0) {
            debt.status = Status.Repaid;
            /* remaining interest payments after principal
             * is fully repaid are refunded to payer
             */
            if (debt.interest > 0) {
                // if less than halfway into current iteration of payment schedule
                if (debt.nextPayment > block.number  + debt.payInterval / 2000)
                    withdrawPhoenixBalanceTo(msg.sender, debt.interest);
                else if (debt.interest > debt.payment)
                    withdrawPhoenixBalanceTo(msg.sender, debt.interest - debt.payment);     
            }   
        }

        debts[payee][debtID] = debt;

        emit RepayPrincipal(payee, debtID, debt.payer, amount);
    }

    /**
     * @dev Reset the payer attributes, usually for debt repurchase
     * @param debtID the id of the debt
     * @param payee the new payer
     * @param v needed for isSiged
     * @param r needed for isSiged
     * @param s needed for isSiged
     * @param payer the new payee
     * @param _v needed for isSiged
     * @param _r needed for isSiged
     * @param _s needed for isSiged
     */
    function setMembers(
        uint256 debtID,
        address payee, uint8 v, bytes32 r, bytes32 s,
        address payer, uint8 _v, bytes32 _r, bytes32 _s
    ) public {
        require(payer != payee, "payee cannot also be the payer");
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

        uint256 payee_ein = identityRegistry.getEIN(payee);
        require(identityRegistry.isResolverFor(payee_ein, address(this)), "payee ein has not set this resolver");
        uint256 payer_ein = identityRegistry.getEIN(payer);
        require(identityRegistry.isResolverFor(payer_ein, address(this)), "payer ein has not set this resolver");

        require(
            isSigned(payee, keccak256(abi.encodePacked("Set Glacier Payee")), v, r, s),
            "not signed by payee"
        );
        require(
            isSigned(payer, keccak256(abi.encodePacked("Set Glacier Payer")), _v, _r, _s),
            "not signed by payer"
        );
        Debt memory debt = debts[payee_ein][debtID];
        
        debt.payer = payer_ein;

        debts[payee_ein][debtID] = debt;

        emit Rearrangement(payee_ein, debtID, "setMembers"); 
    }

    // Checks whether the provided (v, r, s) signature was created by the private key associated with _address
    function isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
        return (_isSigned(_address, messageHash, v, r, s) || _isSignedPrefixed(_address, messageHash, v, r, s));
    }

    // Checks unprefixed signatures
    function _isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        return ecrecover(messageHash, v, r, s) == _address;
    }

    // Checks prefixed signatures (e.g. those created with web3.eth.sign)
    function _isSignedPrefixed(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedMessageHash = keccak256(abi.encodePacked(prefix, messageHash));
        return ecrecover(prefixedMessageHash, v, r, s) == _address;
    }
}
