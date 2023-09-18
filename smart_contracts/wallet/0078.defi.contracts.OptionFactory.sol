pragma solidity ^0.4.23;

import "./DexBrokerage.sol";
import "./OptionToken.sol";
import "./lib/Ownable.sol";
import "./lib/ERC20.sol";
import "./lib/SafeMath.sol";

/**
 * OptionFactory should be used to deploy new OptionTokens.
 *
 * Basic flow should looks that:
 * 
 * optionTokenAddress = optionFactory.getOptionAddress(args)
 * if(optionTokenAddress doesn't exists)
 *     optionFactory.createOption(args)
 *     optionTokenAddress = optionFactory.getOptionAddress(args)
 * ...
 * issue, cancel, execute, refund 
 * ...
 *
 * For arguments description see OptionToken.sol.
 * More examples can be found in dapp.js and OptionFactoryTest.js.
 *
 */
contract OptionFactory is Ownable {

    using SafeMath for uint256;

	/** 
     *  expiry date 
     *  => first token address 
     *  => second token address 
     *  => strike price
     *  => is call
     *  => decimals
     *  => option token address
     */
    mapping (address => bool) public admins;
    mapping(uint 
        => mapping(address 
            => mapping(address 
                => mapping(uint
                    => mapping(bool
                        => mapping(uint8 
                            => OptionToken)))))) register;

    DexBrokerage public exchangeContract;
    ERC20        public dexb;
    uint         public dexbTreshold;
    address      public dexbAddress;

    // Fees for all.
    uint public issueFee;
    uint public executeFee;
    uint public cancelFee;

    // Fees for DEXB holders.
    uint public dexbIssueFee;
    uint public dexbExecuteFee;
    uint public dexbCancelFee;

    // Value represents 100%
    uint public HUNDERED_PERCENT = 100000;

    // Max fee is 1%
    uint public MAX_FEE = HUNDERED_PERCENT.div(100);

    constructor(address _dexbAddress, uint _dexbTreshold, address _dexBrokerageAddress) public {
        dexbAddress      = _dexbAddress;
        dexb             = ERC20(_dexbAddress);
        dexbTreshold     = _dexbTreshold;
        exchangeContract = DexBrokerage(_dexBrokerageAddress);

        // Set fee for everyone to 0.3%
        setIssueFee(300);
        setExecuteFee(300);
        setCancelFee(300);

        // Set fee for DEXB holders to 0.2%
        setDexbIssueFee(200);
        setDexbExecuteFee(200);
        setDexbCancelFee(200);
    }


    function getOptionAddress(
        uint expiryDate, 
        address firstToken, 
        address secondToken, 
        uint strikePrice,
        bool isCall,
        uint8 decimals) public view returns (address) {
        
        return address(register[expiryDate][firstToken][secondToken][strikePrice][isCall][decimals]);
    }

    function createOption(
        uint expiryDate, 
        address firstToken, 
        address secondToken, 
        uint minIssueAmount,
        uint strikePrice,
        bool isCall,
        uint8 decimals,
        string name) public {

        require(address(0) == getOptionAddress(
            expiryDate, firstToken, secondToken, strikePrice, isCall, decimals    
        ));

        OptionToken newOption = new OptionToken(
            this,
            firstToken,
            secondToken,
            minIssueAmount,
            expiryDate,
            strikePrice,
            isCall,
            name,
            decimals
        );

        register[expiryDate][firstToken][secondToken]
            [strikePrice][isCall][decimals] = newOption;
    }

    modifier validFeeOnly(uint fee) { 
        require (fee <= MAX_FEE); 
        _;
    }
    
    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    function setAdmin(address admin, bool isAdmin) onlyOwner public {
        admins[admin] = isAdmin;
    }

    function setIssueFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        issueFee = fee;
    }

    function setExecuteFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        executeFee = fee;
    }

    function setCancelFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        cancelFee = fee;
    }

    function setDexbIssueFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        dexbIssueFee = fee;
    }

    function setDexbExecuteFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        dexbExecuteFee = fee;
    }

    function setDexbCancelFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        dexbCancelFee = fee;
    }

    function setDexbTreshold(uint treshold) public onlyAdmin {
        dexbTreshold = treshold;
    }

    function calcIssueFeeAmount(address user, uint value) public view returns (uint) {
        uint feeLevel = getFeeLevel(user, dexbIssueFee, issueFee);
        return calcFee(feeLevel, value);
    }

    function calcExecuteFeeAmount(address user, uint value) public view returns (uint) {
        uint feeLevel = getFeeLevel(user, dexbExecuteFee, executeFee);
        return calcFee(feeLevel, value);
    }

    function calcCancelFeeAmount(address user, uint value) public view returns (uint) {
        uint feeLevel = getFeeLevel(user, dexbCancelFee, cancelFee);
        return calcFee(feeLevel, value);
    }

    function getFeeLevel(address user, uint aboveTresholdFee, uint belowTresholdFee) internal view returns (uint) {
        if(dexb.balanceOf(user) + exchangeContract.balanceOf(dexbAddress, user) >= dexbTreshold){
            return aboveTresholdFee;
        } else {
            return belowTresholdFee;
        }
    }

    function calcFee(uint feeLevel, uint value) internal view returns (uint) {
        return value.mul(feeLevel).div(HUNDERED_PERCENT);
    }
}
