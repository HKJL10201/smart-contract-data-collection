// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

// Chainlink price feed https://docs.chain.link/docs/bnb-chain-addresses/
interface PriceOracle {
    function latestAnswer() external view returns(uint256); // return latest price
}

contract Auction is Ownable {
    
    address public offeringToken; // token address for sale
    uint256 public startTime;   // auction start time
    uint256 public endTime;     // auction end time
    uint256 public softCap; // minimum amount of BNB should be collected
    uint256 public supplyToDistribute;  // tokens amount on sale
    bool public isClosed;   // auction is closed
    bool public isSuccess;  // softCap has been reached
    uint256 public totalBNB;    // total collected BNB
    uint256 public totalUSDT;   // total collected USDT
    uint256 public bnbPrice;    // BNB price in USD with 8 decimals on auction end. Will be used to split tokens among participants.
    
    address public constant USDT_TOKEN = address(0x55d398326f99059fF775485246999027B3197955);   // USDT address on Binance Smart Chain
    // Chainlink price feed https://docs.chain.link/docs/bnb-chain-addresses/
    // ORACLE_BNB_USD.latestAnswer() returns price of BNB in USD with 8 decimals. I.e. if BNB price is 275.63 USD, function returns 27563000000
    PriceOracle public constant ORACLE_BNB_USD = PriceOracle(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // BNB price in USD. 


    // Info of each user.
    struct UserInfo {
        uint256 tokenAmount;
        uint256 bnbAmount;
        uint256 usdtAmount;
    }

    mapping (address => UserInfo) public userInfo;     // info of user tokens
    address[] public addressList; // list of users 

    constructor(address _offeringToken, uint256 _startTime, uint256 _endTime) 
    {
        offeringToken = _offeringToken;
        startTime = _startTime;
        endTime = _endTime;
    }

    /**
     * @dev set supply to distribute and soft cap for the projects
     * @param _supplyToDistribute set total token supply to distribute
     * @param _softCap minimal amount of USD to raise
     */
    function setCaps(uint256 _supplyToDistribute, uint256 _softCap) external onlyOwner
    {
        require(block.timestamp < startTime, "auction started");
        IERC20(offeringToken).transferFrom(msg.sender, address(this), _supplyToDistribute);
        supplyToDistribute += _supplyToDistribute;
        softCap = _softCap;
    }

    // refund BNB to users if auction did not reach softCap
    function refundAll() external {
        require(isClosed, "Auction not closed");
        require(!isSuccess, "Should distribute tokens");

        for (uint256 i = 0; i < addressList.length; i++) {
            UserInfo storage user = userInfo[addressList[i]];
            if(user.bnbAmount != 0){
                payable(addressList[i]).transfer(user.bnbAmount);
                user.bnbAmount = 0;
            }
            if(user.usdtAmount != 0){
                IERC20(USDT_TOKEN).transfer(addressList[i], user.usdtAmount);
                user.usdtAmount = 0;
            }            
        }
    }

    function claimTokens() external {
        require(isClosed, "Auction not closed");
        require(isSuccess, "Should return Money");
        UserInfo storage user = userInfo[msg.sender];
        require(user.tokenAmount == 0, "Already claimed");
        uint256 totalRaisedUSD = totalUSDT + totalBNB * bnbPrice;
        uint256 userDepositedUSD = user.usdtAmount + user.bnbAmount * bnbPrice;
        require(userDepositedUSD != 0 , "no investment");
        uint256 amountOfTokens = supplyToDistribute * userDepositedUSD / totalRaisedUSD;
        IERC20(offeringToken).transfer(msg.sender, amountOfTokens);
        user.tokenAmount = amountOfTokens;
    }

    function auctionEnd() external {
        require(block.timestamp >= endTime, "Auction not end");
        require(!isClosed, "Auction already closed");
        isClosed = true;
        bnbPrice = ORACLE_BNB_USD.latestAnswer(); // BNB price in USD with 8 decimals
        uint256 totalRaisedUSD = totalUSDT + totalBNB * bnbPrice;
        isSuccess = totalRaisedUSD >= softCap;
    }

    function checkConditions(uint256 _amount) internal view {
        require(block.timestamp > startTime && block.timestamp < endTime,"not auction time");
        require(_amount > 0, "need _amount > 0");
        require(isClosed == false, "funding is reached");
    }

    /**
     * @dev deposit money to auction to buy tokens. Can be deposited BNB or USDT token
     * @param _amount amount of BNB or USDT to deposit
     * @param _isUSDT is `true` if deposit USDT, or `false` if deposit BNB
     */ 
    function depositAuction(uint256 _amount, bool _isUSDT) external payable {
        checkConditions(_amount);
        UserInfo storage user = userInfo[msg.sender];
        if (user.bnbAmount == 0 && user.usdtAmount == 0) { // add new user to the list
            addressList.push(msg.sender);
        }

        if (_isUSDT) {
            IERC20(USDT_TOKEN).transferFrom(msg.sender, address(this), _amount);
            totalUSDT += _amount;
            user.usdtAmount += _amount;
        } else {
            totalBNB += _amount;
            user.bnbAmount += _amount;
        }
    }
}