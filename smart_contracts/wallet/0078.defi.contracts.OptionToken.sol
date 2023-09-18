pragma solidity ^0.4.23;

import './lib/StandardToken.sol';
import './lib/ERC20.sol';
import './OptionFactory.sol';

/**
 *
 * @author Maciek Zielinski & Radek Ostrowski - https://startonchain.com
 * @author Alex George - https://dexbrokerage.com
 *
 * OptionToken contract allows to create options in 6 different modes.
 *
 *
 * Mode
 * ============================================================================
 * Used mode depends on constructor's arguments.
 * Using 0x0 address means using Ether:
 * - address(0) == 0x0000000000000000000000000000000000000000
 *
 *
 * Example:
 * ----------------------------------------------------------------------------
 * ETH -> ERC20, Call
 *  |       |      +---- isCall = True
 *  |       +----------- secondToken = 0x112123 - some ERC20 token address.
 *  +------------------- firstToken = 0x0000000000000000000000000000000000000000
 *
 * In each mode certain functions for issuing and executing needs to be used:
 *
 * - ETH -> ERC20, Call:
 *     - issueWithWei
 *     - executeWithToken
 *
 * - ETH -> ERC20, Put:
 *     - issueWithToken
 *     - executeWithWei
 *
 * - ERC20 -> ETH, Call:
 *     - issueWithToken
 *     - executeWithWei
 *
 * - ERC20 -> ETH, Put:
 *     - issueWithWei
 *     - executeWithToken
 *
 * - ERC20 -> ERC20, Call
 *     - issueWithToken
 *     - executeWithToken
 *
 * - ERC20 -> ERC20, Put
 *     - issueWithToken
 *     - executeWithToken
 *
 * It is not possible to use wrong issue and execute function.
 *
 *
 * Strike Price
 * ============================================================================
 * Strike price is represented using secondToken's decimals.
 *
 *
 * Example.
 * ----------------------------------------------------------------------------
 * Given:
 * - firstToken has 18 decimals
 * - secondToken has 4 decimals,
 * - desired strike price 1 firstToken = 20 secondTokens
 *
 * strikePrice argument should be `20 * 10^4`.
 *
 *
 * Issuing
 * ============================================================================
 * OptionTokens decimals are always the same as decimals of firstToken.
 * Constructor takes argument `decimals` and it needs to be firstToken's
 * decimals. ERC20 specification says that `ERC20.decimals()` is optional and
 * that why it needs to be provided explicitly.
 *
 *
 * Call Example.
 * ----------------------------------------------------------------------------
 * Given:
 * - firstToken has 6 decimals;
 * - secondToken has 20 decimals;
 * - strikePrice = 40 * 10^20 (1 firstToken = 40 secondTokens);
 * - isCall = true.
 *
 * Invoking method `issueWithToken(3 * 10^6)` should:
 * - transfer 3 * 10^6 firstTokens from msg.sender into contract;
 * - issue 3 * 10^6 options to msg.sender.
 *
 *
 * Put Example.
 * ----------------------------------------------------------------------------
 * Given:
 * - firstToken has 6 decimals;
 * - secondToken has 20 decimals;
 * - strikePrice = 40 * 10^20 (1 firstToken = 40 secondTokens);
 * - isCall = false.
 *
 *
 * Invoking method `issueWithToken(3 * 10^6)` should:
 * - transfer 3 * 40 * 10^20 from msg.sender into contract;
 * - issue 3 * 10^6 options to msg.sender.
 *
 *
 * Put Example with ETH:
 * ----------------------------------------------------------------------------
 * Given
 * - secondToken has 5 decimals;
 * - firtsToken is Ether so has 18 decimals;
 * - strikePrice = 3 * 10^18 (1 secondTokens = 3 Ether);
 * - isCall = false.
 *
 * Invoking method issueWithWei() and sending 6 * 10^18 Wei should:
 * - issue 2 * 10 ^ 5 options to msg.sender.
 *
 *
 * Executing
 * ============================================================================
 * Executing works similar to issuing.
 *
 *
 * Fee
 * ============================================================================
 * Fee is calculated using OptionFactory contract.
 * Fee is send to `factory.owner().`
 *
 *
 * More examples
 * ----------------------------------------------------------------------------
 * For more detail examples please see OptionTokenTest.js
 */
contract OptionToken is StandardToken {

    using SafeMath for uint256;

    OptionFactory public factory;
    ERC20  public firstToken;
    ERC20  public secondToken;
    uint   public minIssueAmount;
    uint   public expiry;
    uint   public strikePrice;
    bool   public isCall;
    string public symbol;
    uint  public decimals;

    struct Issuer {
        address addr;
        uint amount;
    }

    Issuer[] internal issuers;

    constructor(
        address _factory,
        address _firstToken,
        address _secondToken,
        uint    _minIssueAmount,
        uint    _expiry,
        uint    _strikePrice,
        bool    _isCall,
        string  _symbol,
        uint8   _decimals) public {

        require (_firstToken != _secondToken, 'Tokens should be different.');

        factory        = OptionFactory(_factory);
        firstToken     = ERC20(_firstToken);
        secondToken    = ERC20(_secondToken);
        minIssueAmount = _minIssueAmount;
        expiry         = _expiry;
        strikePrice    = _strikePrice;
        isCall         = _isCall;
        symbol         = _symbol;
        decimals       = uint(_decimals);
    }

    modifier onlyAdmin {
        require(factory.admins(msg.sender));
        _;
    }

    /** Public API */

    function setMinIssueAmount(uint minAmount) onlyAdmin public  {
        minIssueAmount = minAmount;
    }

    function issueWithToken(uint amount) public beforeExpiry canIssueWithToken returns (bool) {
        require(amount >= minIssueAmount);
        uint fee = factory.calcIssueFeeAmount(msg.sender, amount);
        uint amountWithoutFee = amount - fee;
        transferTokensInOnIssue(amountWithoutFee, fee);
        issue(amountWithoutFee);
        return true;
    }

    function issueWithWei() public payable beforeExpiry canIssueWithWei returns (bool) {
        require(msg.value >= minIssueAmount);
        uint fee = factory.calcIssueFeeAmount(msg.sender, msg.value);
        uint amountWithoutFee = msg.value - fee;
        factory.owner().transfer(fee);
        if(isCall){
            issue(amountWithoutFee);
        } else {
            uint amount = amountWithoutFee.mul(uint(10).pow(decimals)).div(strikePrice);
            issue(amount);
        }
        return true;
    }

    function executeWithToken(uint amount) public beforeExpiry canExecuteWithToken returns (bool) {
        transferTokensInOnExecute(amount);
        execute(amount);
        return true;
    }

    function executeWithWei() public payable beforeExpiry canExecuteWithWei {
        if(isCall){
            uint amount = msg.value.mul(uint(10).pow(decimals)).div(strikePrice);
            execute(amount);
        } else {
            execute(msg.value);
        }
    }

    function cancel(uint amount) public beforeExpiry {
        burn(msg.sender, amount);
        bool found = false;
        for (uint i = 0; i < issuers.length; i++) {
            if(issuers[i].addr == msg.sender) {
                found = true;
                issuers[i].amount = issuers[i].amount.sub(amount);
                transferTokensOrWeiOutToIssuerOnCancel(amount);
                break;
            }
        }
        require(found);
    }

    function refund() public afterExpiry {
        // Distribute tokens or wei to issuers.
        for(uint i = 0; i < issuers.length; i++) {
            if(issuers[i].amount > 0){
                transferTokensOrWeiOutToIssuerOnRefund(issuers[i].addr, issuers[i].amount);
            }
        }
    }

    /** Internal API */
    function transferTokensInOnIssue(uint amountForContract, uint feeAmount) internal returns (bool) {
        ERC20 token;
        uint toTransferIntoContract;
        uint toTransferFee;
        if(isCall){
            token = firstToken;
            toTransferIntoContract = amountForContract;
            toTransferFee = feeAmount;
        } else {
            token = secondToken;
            toTransferIntoContract = strikePrice.mul(amountForContract).div(uint(10).pow(decimals));
            toTransferFee = strikePrice.mul(feeAmount).div(uint(10).pow(decimals));
        }
        require(token != address(0));
        require(transferTokensIn(token, toTransferIntoContract + toTransferFee));
        require(transferTokensToOwner(token, toTransferFee));
        return true;
    }

    function transferTokensInOnExecute(uint amount) internal returns (bool) {
        ERC20 token;
        uint toTransfer;
        if(isCall){
            token = secondToken;
            toTransfer = strikePrice.mul(amount).div(uint(10).pow(decimals));
        } else {
            token = firstToken;
            toTransfer = amount;
        }
        require(token != address(0));
        require(transferTokensIn(token, toTransfer));
        return true;
    }

    function transferTokensIn(ERC20 token, uint amount) internal returns (bool) {
        require(token.transferFrom(msg.sender, this, amount));
        return true;
    }

    function transferTokensToOwner(ERC20 token, uint amount) internal returns (bool) {
        require(token.transfer(factory.owner(), amount));
        return true;
    }

    function transfer(ERC20 token, uint amount) internal returns (bool) {
        require(token.transferFrom(msg.sender, factory.owner(), amount));
        return true;
    }
    function issue(uint amount) internal returns (bool){
        mint(msg.sender, amount);
        bool found = false;
        for (uint i = 0; i < issuers.length; i++) {
            if(issuers[i].addr == msg.sender) {
                issuers[i].amount = issuers[i].amount.add(amount);
                found = true;
                break;
            }
        }

        if(!found) {
            issuers.push(Issuer(msg.sender, amount));
        }
    }

    function mint(address to, uint amount) internal returns (bool) {
        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function execute(uint amount) internal returns (bool) {
        burn(msg.sender, amount);
        transferTokensOrWeiOutToSenderOnExecute(amount);
        // Distribute tokens to issuers.
        uint amountToDistribute = amount;
        uint i = issuers.length - 1;
        while(amountToDistribute > 0){
            if(issuers[i].amount > 0){
                if(issuers[i].amount >= amountToDistribute){
                    transferTokensOrWeiOutToIssuerOnExecute(issuers[i].addr, amountToDistribute);
                    issuers[i].amount = issuers[i].amount.sub(amountToDistribute);
                    amountToDistribute = 0;
                } else {
                    transferTokensOrWeiOutToIssuerOnExecute(issuers[i].addr, issuers[i].amount);
                    amountToDistribute = amountToDistribute.sub(issuers[i].amount);
                    issuers[i].amount = 0;
                }
            }
            i = i - 1;
        }
        return true;
    }

    function transferTokensOrWeiOutToSenderOnExecute(uint amount) internal returns (bool) {
        ERC20 token;
        uint toTransfer = 0;
        if(isCall){
            token = firstToken;
            toTransfer = amount;
        } else {
            token = secondToken;
            toTransfer = strikePrice.mul(amount).div(uint(10).pow(decimals));
        }
        uint fee = factory.calcExecuteFeeAmount(msg.sender, toTransfer);
        toTransfer = toTransfer - fee;
        if(token == address(0)){
            require(msg.sender.send(toTransfer));
            if(fee > 0){
                require(factory.owner().send(fee));
            }
        } else {
            require(token.transfer(msg.sender, toTransfer));
            if(fee > 0){
                require(token.transfer(factory.owner(), fee));
            }
        }
        return true;
    }

    function transferTokensOrWeiOutToIssuerOnExecute(address issuer, uint amount) internal returns (bool) {
        ERC20 token;
        uint toTransfer;
        if(isCall){
            token = secondToken;
            toTransfer = strikePrice.mul(amount).div(uint(10).pow(decimals));
        } else {
            token = firstToken;
            toTransfer = amount;
        }
        if(token == address(0)){
            require(issuer.send(toTransfer));
        } else {
            require(token.transfer(issuer, toTransfer));
        }
        return true;
    }

    function burn(address from, uint256 amount) internal returns (bool) {
        require(amount <= balances[from]);
        balances[from] = balances[from].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        emit Transfer(from, address(0), amount);
        return true;
    }

    function transferTokensOrWeiOutToIssuerOnCancel(uint amount) internal returns (bool){
        ERC20 token;
        uint toTransfer = 0;
        if(isCall){
            token = firstToken;
            toTransfer = amount;
        } else {
            token = secondToken;
            toTransfer = strikePrice.mul(amount).div(uint(10).pow(decimals));
        }
        uint fee = factory.calcCancelFeeAmount(msg.sender, toTransfer);
        toTransfer = toTransfer - fee;
        if(token == address(0)){
            require(msg.sender.send(toTransfer));
            if(fee > 0){
                require(factory.owner().send(fee));
            }
        } else {
            require(token.transfer(msg.sender, toTransfer));
            if(fee > 0){
                require(token.transfer(factory.owner(), fee));
            }
        }
        return true;
    }


    function transferTokensOrWeiOutToIssuerOnRefund(address issuer, uint amount) internal returns (bool){
        ERC20 token;
        uint toTransfer = 0;
        if(isCall){
            token = firstToken;
            toTransfer = amount;
        } else {
            token = secondToken;
            toTransfer = strikePrice.mul(amount).div(uint(10).pow(decimals));
        }
        if(token == address(0)){
            issuer.transfer(toTransfer);
        } else {
            require(token.transfer(issuer, toTransfer));
        }
        return true;
    }

    /** Modifiers */
    modifier canIssueWithWei() {
        require(
            (isCall  && firstToken == address(0)) ||
            (!isCall && secondToken == address(0))
        );
        _;
    }

    modifier canIssueWithToken() {
        require(
            (isCall  && firstToken != address(0)) ||
            (!isCall && secondToken != address(0))
        );
        _;
    }

    modifier canExecuteWithWei() {
        require(
            (isCall  && secondToken == address(0)) ||
            (!isCall && firstToken == address(0))
        );
        _;
    }

    modifier canExecuteWithToken() {
        require(
            (isCall  && secondToken != address(0)) ||
            (!isCall && firstToken != address(0))
        );
        _;
    }

    modifier beforeExpiry() {
        require (now <= expiry);
        _;
    }

    modifier afterExpiry() {
        require (now > expiry);
        _;
    }
}
