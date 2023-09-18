pragma solidity ^0.4.18;

import "./NewsToken.sol";
 
 
contract IToken {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function burn(uint256 _value) public;
}

contract TESTNewsCrowdsale {

    uint NowTime; 
 
    address public token;
 
    uint public timeDeploy; 

    address public ownerWallet;

    uint timeStartAuction; 
    uint timeFinalizeAuction;  

    uint numOf_SalesDays;
    uint numOf_AuctionDays;
    uint numOf_BreakDays; 
    uint indexCurDay;  

    uint amountSellPerDay;
    uint decimalVar;

    mapping (uint => uint) public timeStartDay;
    mapping (uint => uint) public timeEndsDay;
    mapping (uint => uint) public dailyTotals;

    mapping (uint => mapping (address => uint)) public userContribution;
    mapping (uint => mapping (address => bool)) public claimed;
    
    event Buy (uint day, address user, uint amount);
    event Claim (uint day, address user, uint amount); 
    
    modifier whenNotPause(uint today) {
        while (today >= timeStartDay[indexCurDay + 1] && indexCurDay < numOf_SalesDays) {
            indexCurDay++;
        }
        
        require(NowTime >= timeStartDay[indexCurDay] && NowTime <= timeEndsDay[indexCurDay]);
        _;
    }  

    // TEST
    function updateTime(uint _i) public {
        NowTime = timeDeploy + _i * 1 days;
    }

    function TESTNewsCrowdsale() public {  
        timeDeploy = now; 
        updateTime(0);

        numOf_SalesDays = 160; 
        numOf_BreakDays = 80;
        numOf_AuctionDays = 10;

        indexCurDay = 1; 
        decimalVar = 10 ether; 
          
        
        timeStartDay[1] = timeDeploy + numOf_BreakDays * 1 days; 
        timeEndsDay[1] = timeDeploy + (numOf_BreakDays + 1) * 1 days; 
    }  

    //TEST

    function setTokenAddress(address tokenAddress) public {
        require(token == address(0));
        token = tokenAddress;

        amountSellPerDay = IToken(token).balanceOf(this) / numOf_SalesDays * decimalVar;
    }
     
    
    function initStartAuctionDays() public {
        require(timeStartAuction == 0);

        uint i = 1;
        while (i < numOf_SalesDays) {  
            
            uint j = 1;
            for (;j < numOf_AuctionDays; j++) {
                timeStartDay[i + j] = timeStartDay[i + j - 1] + 1 days; 
            }
            i += j;
            
            timeStartDay[i] = timeStartDay[i - 1] + (numOf_BreakDays + 1) * 1 days;  
        } 

        timeStartAuction = timeStartDay[1];  
    }

    function initEndsAuctionDays() public {
        require(timeFinalizeAuction == 0);

        uint i = 1;
        while (i < numOf_SalesDays) {  
            
            uint j = 1;
            for (;j < numOf_AuctionDays; j++) {
                timeEndsDay[i + j] = timeEndsDay[i + j - 1] + 1 days; 
            }
            i += j;
            
            timeEndsDay[i] = timeEndsDay[i - 1] + (numOf_BreakDays + 1) * 1 days;  
        } 

        timeFinalizeAuction = timeEndsDay[numOf_SalesDays];  
    }
    
    function () payable external {
       buy();
    }  
    
    function buy() payable public whenNotPause(NowTime) {   
 
        userContribution[indexCurDay][msg.sender] += msg.value;
        dailyTotals[indexCurDay] += msg.value; 
        
       // ownerWallet.transfer(msg.value);
        
        Buy(indexCurDay, msg.sender, msg.value);
    }  

    function claim(uint day) public { 
        if (claimed[day][msg.sender] || dailyTotals[day] == 0) {
            return;
        }
        
        require(NowTime > timeEndsDay[day]);
        
        uint price        = amountSellPerDay / dailyTotals[day];
        uint userPersent  = price * userContribution[day][msg.sender];
        uint reward       = userPersent / decimalVar; 

        claimed[day][msg.sender] = true;
        IToken(token).transfer(msg.sender, reward);

        Claim(day, msg.sender, reward);
    } 

    function claimInterval(uint fromDay, uint toDay) external {  
        require(fromDay > 0 && toDay <= numOf_SalesDays);
        require(fromDay < toDay);

        for (uint i = fromDay; i <= toDay; i++) {
            claim(i);
        } 
    }  

    function getQuantitySoldEveryDay() public view returns(uint) {
        return amountSellPerDay / decimalVar;
    } 
    
    //this
    function getCurrentDay() public view returns(uint) {
        uint dayCounter = indexCurDay;
        
        while (NowTime >= timeStartDay[dayCounter + 1] && dayCounter < numOf_SalesDays) {
            dayCounter++;
        } 
        return NowTime >= timeStartAuction && NowTime <= timeFinalizeAuction
                ? dayCounter 
                : 0;
    }

    function getNumberOfSalesDays() public view returns(uint) {
        return numOf_SalesDays;
    }

    function getTimeAuctionStart() public view returns(uint) {
        return timeStartAuction;
    }

    function getTimeAuctionFinalize() public view returns(uint) {
        return timeFinalizeAuction;
    }

    //this
    function isAuctionActive() public view returns(bool) {
        uint dayCounter = indexCurDay; 
        while (NowTime >= timeStartDay[dayCounter + 1] && dayCounter < numOf_SalesDays) {
            dayCounter++;
        } 

        return NowTime >= timeStartDay[dayCounter] && NowTime <= timeEndsDay[dayCounter];
    }
	
	function getTimeNow() public view returns(uint) {
		return NowTime;
	} 

    //this
    function getDaysToNextAuction() public view returns(uint) {
        uint dayCounter = indexCurDay; 
        while (NowTime >= timeStartDay[dayCounter + 1] && dayCounter < numOf_SalesDays) {
            dayCounter++;
        }

        if(dayCounter == 160) {
            return 0;
        }

        if (now >= timeStartAuction && now <= timeFinalizeAuction) {
            return dayCounter % 10 == 0 && now >= timeEndsDay[dayCounter]
                   ? (timeStartDay[dayCounter + 1] - now) / 1 days
                   : 0;
        } else {
            return (timeStartAuction - now) / 1 days;
        }
    } 
    
    //---------------------------test-method-buy/claim-----------------------
    
    uint testLastDay;
     function testSetUserContribut(uint day) public payable {
        userContribution[day][msg.sender] += msg.value;
        dailyTotals[day] += msg.value; 
        
        Buy(day, msg.sender, msg.value);
        testLastDay = day; 
    }
     function testClaim(uint day) public { 
        if (claimed[day][msg.sender] || dailyTotals[day] == 0) {
            return;
        } 

        uint price        = amountSellPerDay / dailyTotals[day];
        uint userPersent  = price * userContribution[day][msg.sender];
        uint reward       = userPersent / decimalVar; 

        claimed[day][msg.sender] = true;
        IToken(token).transfer(msg.sender, reward);

        Claim(day, msg.sender, reward);
    } 
    
     function testClaimInterval(uint fromDay, uint toDay) external {  
        require(fromDay > 0 && toDay <= numOf_SalesDays);
        require(fromDay < toDay);

        for (uint i = fromDay; i <= toDay; i++) {
            testClaim(i);
        } 
    }  

    function getNowTime() public view returns(uint) {
        return NowTime;
    }
    function time() public view returns(uint) {
        return now;
    }

    function burnAllUnsoldTokens() public {
        require(NowTime > timeFinalizeAuction + 90 days);

        uint contractBalance = IToken(token).balanceOf(this);
        IToken(token).burn(contractBalance);
    }
}