pragma solidity ^0.8.0;
/*
dow theory calculator
required variables:
- top of candels at 1 month intervals
- calculate the average of the highs and lows
top/bottom of candles (1, 2, 3, 4) 1+2+3+4= x/4 = average
- input number with the last 4 numbers after the decimal
- since the prices are decimals the price must be inputed as: price * 10^4
- 
*/
import "./safemath.sol";

    contract formulas{
        
      using SafeMath for uint256;
      
       bool success = true;
       bool failed = false;


       struct priceHistory{
            uint highestPricethismonth;
            uint highestPrice2MonthsAgo;
            uint highestPrice3MonthsAgo;
            uint highestPrice4MonthsAgo;
            uint lowestPricethismonth;
            uint lowestPrice2MonthsAgo;
            uint lowestPrice3MonthsAgo;
            uint lowestPrice4MonthsAgo;
        }
       priceHistory[] stableCoins;
        
       function addNewCoinStats(
             uint _highestPricethismonth,
            uint _highestPrice2MonthsAgo,
            uint _highestPrice3MonthsAgo,
            uint _highestPrice4MonthsAgo,
            uint _lowestPricethismonth,
            uint _lowestPrice2MonthsAgo,
            uint _lowestPrice3MonthsAgo,
            uint _lowestPrice4MonthsAgo
           )public  payable{
               priceHistory memory newCoin = priceHistory(
                    _highestPricethismonth,
             _highestPrice2MonthsAgo,
             _highestPrice3MonthsAgo,
             _highestPrice4MonthsAgo,
             _lowestPricethismonth,
             _lowestPrice2MonthsAgo,
             _lowestPrice3MonthsAgo,
             _lowestPrice4MonthsAgo
            );
               stableCoins.push(newCoin);
           }

        
       
       function calculate(
       uint index
           )public view returns(string memory){
       uint avh1;
       uint avh2;
       uint avh3;
       uint avl1;
       uint avl2;
       uint avl3;
        uint one;
        one=1;
        uint fiveThousand;
        fiveThousand =5000;
       uint allowbuy;
       uint allowsell;
               //function add(uint256 a, uint256 b) internal pure returns (uint256) {
            //   return a + b;
               priceHistory memory coinToReturn = stableCoins[index];
               
              /* require(
                   coinToReturn.highestPricethismonth%coinToReturn.highestPrice2MonthsAgo <= 1%5000
                   );
               avh1 = coinToReturn.highestPricethismonth.add (coinToReturn.highestPrice2MonthsAgo);
               avh2 = coinToReturn.highestPrice3MonthsAgo.add (coinToReturn.highestPrice4MonthsAgo);
               avh3 = avh1.add (avh2);allowsell = avh3.div(4);
               avl1 = coinToReturn.lowestPricethismonth.add (coinToReturn.lowestPrice2MonthsAgo);
               avl2 = coinToReturn.lowestPrice3MonthsAgo.add (coinToReturn.lowestPrice4MonthsAgo);
               avl3 = avl1.add (avl2);allowbuy = avl3.div(4);*/
           
               allowbuy = 9990;
               allowsell = 10004;
              return ("Calculations complete; go check if it is the time to buy!");
            }
      
   /*   function safeAverage(uint _Index)public view returns(bool){
             priceHistory memory coinToReturn = stableCoins[_Index];
          //   coinToReturn.lowestPricethismonth - coinToReturn.lowestPrice2MonthsAgo =c;
             
            if (
    coinToReturn.lowestPrice2MonthsAgo  > (coinToReturn.lowestPricethismonth*0.20)-coinToReturn.lowestPricethismonth 
    ){
                  
            }
            if(coinToReturn.lowestPrice2MonthsAgo  > (coinToReturn.lowestPricethismonth*0.20)-coinToReturn.lowestPricethismonth){
                
            }
            
            /*if min1 is 17% lower than min2 min 1 = extravogant
            if min 2 is 17% lower than min1 = min 2 is extravogant
            if min 3 is lower than extravogant min 1 - 17% is target allowbuy
            //vice versa with max
            else  return string no extravogants, // use mod
        */}
       /* 
         function bart(){
            
        }
        */
       
