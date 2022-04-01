pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./openzeppelin-contracts/contracts/access/Ownable.sol";
import "./openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./openzeppelin-contracts/contracts/utils/Address.sol";
import "./Rates.sol";
import "./Fee.sol";

contract TradingContract is Ownable, Rates, Fee  {
    
    using SafeMath for uint256;
    using Address for address;
    
    
    uint256 public maxGasPrice = 1 * 10**18; // Adjustable value
    
    address public token1;
    address public token2; // can be address(0) = 0x0000000000000000000000000000000000000000
    
    
    modifier validGasPrice() {
        require(tx.gasprice <= maxGasPrice, "Transaction gas price cannot exceed maximum gas price.");
        _;
    }

    modifier isToken() {
        require(address(msg.sender).isContract());
        require(address(msg.sender) == address(token1) || address(msg.sender) == address(token2));
        _;
    }
    
    function setMaxGasPrice(uint256 gasPrice) public onlyOwner {
        maxGasPrice = gasPrice;
    }
    
    /**
     * @param _token1 address of token1
     * @param _token2 address of token2(or address(0) for ETH)
     * @param _numerator price increment *1e6
     * @param _denominator how much ether to next price
     * @param _priceFloor price floor *1e6
     * @param _discount price 99% * 1e6
     * @param _token1Fee // 1 means 0.000001% mul 1e6
     * @param _token2Fee // 1 means 0.000001% mul 1e6
     */
    constructor(
        address _token1, 
        address _token2,
        uint256 _numerator,
        uint256 _denominator,
        uint256 _priceFloor,
        uint256 _discount,
        uint256 _token1Fee,
        uint256 _token2Fee
    ) 
        Rates(_numerator,_denominator,_priceFloor,_discount)
        Fee(_token1, _token2, _token1Fee, _token2Fee) 
        public 
        payable 
    {
        token1 = _token1;
        token2 = _token2;
        
    }
    
    
    /**
     * @param durationTime Duration in seconds
     * if less than 0 - then it's Donation
     * if equal 0 - then it's immediately exchange to another token
     * if more than 0 - then it's Deposit for `durationTime` period 
     * @param directToAccount if true then funds from deposit will send to account directly else accumulated in contract
     */
    function depositToken1(int256 durationTime, bool directToAccount) validGasPrice public {
        
        uint256 _allowedAmount = IERC20(token1).allowance(msg.sender, address(this));
        require(_allowedAmount>0, 'Amount exceeds allowed balance');

        // try to get
        bool success = IERC20(token1).transferFrom(msg.sender, address(this), _allowedAmount);
        require(success == true, 'Transfer tokens were failed');
        
        if (durationTime < 0) {
            // Donation
        } else if (durationTime == 0) {
            _receivedToken1(msg.sender, _allowedAmount);
        } else if (durationTime > 0) {
            // Deposit
            
            setFunds(token1,_allowedAmount, uint256(durationTime), directToAccount);
            
        }
    }
    
    /**
     * @param durationTime Duration in blocks
     * if less than 0 - then it's Donation
     * if equal 0 - then it's immediately exchange to another token
     * if more than 0 - then it's Deposit for `durationTime` period 
     * @param directToAccount if true when funds from deposit 
     */
    function depositToken2(int256 durationTime, bool directToAccount) payable validGasPrice public {
        uint256 _allowedAmount;
        bool success;
        if (token2 == address(0)) {
            _allowedAmount = msg.value;
            require(_allowedAmount>0, 'Amount exceeds allowed balance');
        } else {
            _allowedAmount = IERC20(token2).allowance(msg.sender, address(this));
            require(_allowedAmount>0, 'Amount exceeds allowed balance');
            // try to get
            success = IERC20(token2).transferFrom(msg.sender, address(this), _allowedAmount);
            require(success == true, 'Transfer tokens were failed');     
        }
        
        if (durationTime < 0) {
            // Donation
        } else if (durationTime == 0) {
            _receivedToken2(msg.sender, _allowedAmount);
        } else if (durationTime > 0) {
            // Deposit
            
            setFunds(token2,_allowedAmount, uint256(durationTime), directToAccount);

        }
    }
    
    /**
     * @return depositIDs
     * @return amounts
     * @return untilTime
     * @return directToAccounts
     *  
     */
    function viewDepositsToken1 
    (
    ) 
        public 
        view 
    returns(
        uint256[] memory depositIDs, 
        uint256[] memory amounts, 
        uint256[] memory untilTime, 
        bool[] memory directToAccounts
    ){
        // Deposit[] memory
        return viewFunds(token1);
    }

    /**
     * @return depositIDs
     * @return amounts
     * @return untilTime
     * @return directToAccounts
     *  
     */
    function viewDepositsToken2
    (
    ) 
        public 
        view 
    returns(
        uint256[] memory depositIDs, 
        uint256[] memory amounts, 
        uint256[] memory untilTime, 
        bool[] memory directToAccounts
    ){
        return viewFunds(token2);
    }
    
    /**
     * Withdraw deposited tokens1
     */
    function withdrawToken1(bool withYield, uint256 depositID) validGasPrice public {
        
        uint256 balanceToken1;
        
        balanceToken1 = IERC20(token1).balanceOf(address(this));
        
        uint256 tokensLeft = withdrawFunds(depositID, withYield, token1, balanceToken1);
        
        if (tokensLeft > 0) {
            // balanceToken1 = IERC20(token1).balanceOf(address(this));
            uint256 balanceToken2;
            if (address(0) == address(token2)) {  // ETH
                balanceToken2 = address(this).balance;
            } else { // Token2
                balanceToken2 = IERC20(token2).balanceOf(address(this));    
            }
          
            //                                      (token1Amount, _balanceToken1, _balanceToken2);
            uint256 amount2send = sellExchangeAmount(tokensLeft, balanceToken1, balanceToken2);
            
            require ((amount2send <= balanceToken2 && balanceToken2 > 0), "Amount exceeds available balance.");
            withdrawLeftFunds(token2, withYield, balanceToken2, amount2send);
        }
        
    }
    
    /**
     * Withdraw deposited tokens2
     */
    function withdrawToken2(bool withYield, uint256 depositID) validGasPrice public {
        
        uint256 balanceToken2;
        if (address(0) == address(token2)) {  // ETH
            balanceToken2 = address(this).balance;
        } else { // Token2
            balanceToken2 = IERC20(token2).balanceOf(address(this));    
        }
        
        uint256 tokensLeft = withdrawFunds(depositID, withYield, token2, balanceToken2);
        
        if (tokensLeft > 0) {
            uint256 balanceToken1 = IERC20(token1).balanceOf(address(this));


            //                                      (token2Amount, balanceToken1, balanceToken2);
            uint256 amount2send = buyExchangeAmount(tokensLeft, balanceToken1, balanceToken2);
            
            require ((amount2send <= balanceToken1 && balanceToken1 > 0), "Amount exceeds available balance.");
            withdrawLeftFunds(token1, withYield, balanceToken1, amount2send);
        }
        
    }
    
    // recieve ether and transfer token1 to sender
    receive() external payable validGasPrice {
        require (token2 == address(0), "This method is not supported");
        _receivedToken2(msg.sender, msg.value);
    }
    
    /**
     * 
     */
    function _receive(uint256 msg_value) private {
        require (token2 == address(0), "This method is not supported"); 
        
        uint256 _balanceToken1 = IERC20(token1).balanceOf(address(this));
        uint256 _balanceToken2 = address(this).balance;
        // _balanceToken1, address(this).balance, msg.value

        uint256 _amount2send = buyExchangeAmount(msg_value,_balanceToken1, _balanceToken2);
        
        require (_amount2send <= _balanceToken1 && _balanceToken1>0 && _amount2send>0, "Amount exceeds available balance.");
        
        bool success = IERC20(token1).transfer(
            msg.sender,
            _amount2send
        );
        require(success == true, 'Transfer tokens were failed');
    }
    
    /**
     * 
     */
    function _receivedToken1(address _from, uint256 token1Amount) private {
        uint256 _balanceToken1 = IERC20(token1).balanceOf(address(this));
        uint256 _balanceToken2;
        if (address(0) == address(token2)) {  // ETH
            _balanceToken2 = address(this).balance;
        } else { // Token2
            _balanceToken2 = IERC20(token2).balanceOf(address(this));    
        }
      
        uint256 _amount2send = sellExchangeAmount(token1Amount, _balanceToken1, _balanceToken2);
        
        require ((_amount2send <= _balanceToken2 && _balanceToken2>0), "Amount exceeds available balance.");

        bool success;
        if (address(0) == address(token2)) {
            address payable addr1 = payable(_from); // correct since Solidity >= 0.6.0
            success = addr1.send(_amount2send);
            require(success == true, 'Transfer ether was failed'); 
        } else {
            success = IERC20(token2).transfer(_from,_amount2send);
            require(success == true, 'Transfer tokens were failed');     
        }
            
    }
    
    /**
     * 
     */
    function _receivedToken2(address _from, uint256 token2Amount) private {
        
        uint256 _balanceToken1 = IERC20(token1).balanceOf(address(this));
        uint256 _balanceToken2;
        if (address(0) == address(token2)) {  // ETH
            _balanceToken2 = address(this).balance;
        } else { // Token2
            _balanceToken2 = IERC20(token2).balanceOf(address(this));    
        }
        
        uint256 _amount2send = buyExchangeAmount(token2Amount, _balanceToken1, _balanceToken2);
        
        require (_amount2send <= _balanceToken1 && _balanceToken1>0, "Amount exceeds available balance.");
        
        bool success = IERC20(token1).transfer(_from,_amount2send);
        require(success == true, 'Transfer tokens were failed'); 
    }  
    
    
}

