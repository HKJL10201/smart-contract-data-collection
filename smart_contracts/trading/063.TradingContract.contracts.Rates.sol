pragma solidity >=0.6.0 <0.7.0;

import "./openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./openzeppelin-contracts/contracts/math/SignedSafeMath.sol";
import "./CommonConstants.sol";

/**
 * Realization math conversion for Utility token that can exchange tokens
 * 
 * @title Math for tokens exchange
 * @author Artem Subbotin
 * 
 * @dev There are two tokens:
 * Token #1
 * Token #2 (it is often ETH - currency ethereum network)
 * 
 */
contract Rates is CommonConstants {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    
    uint256 private _numerator = 0;       // price increment *1e6
    uint256 private _denominator = 30;    // how much ether to next price
    uint256 private _priceFloor = 333;    // price floor *1e6
    uint256 private _discount = 99e4;     //  99% * 1e6

    /**
     * @dev initialize numerator, denominator, priceFloor and discount via constructor
     * 
     * @param numerator price increment *1e6
     * @param denominator how much ether to next price
     * @param priceFloor price floor *1e6
     * @param discount price 99% * 1e6
     * 
     */
    constructor (
        uint256 numerator,
        uint256 denominator,
        uint256 priceFloor,
        uint256 discount
    ) 
        public 
    {
        _numerator = numerator;
        _denominator = denominator;
        _priceFloor = priceFloor;
        _discount = discount;
    }
    
    /**
     * How much token#1 need to send to user by getting token#2
     * 
     * @param token2Amount  - amount token #2 sent by user to getting token#1
     * @param token1Balance - overall balance of token#1 before exchange
     * @param token2Balance - overall balance of token#2 before exchange
     * 
     */
    function buyExchangeAmount(
        uint256 token2Amount, 
        uint256 token1Balance, 
        uint256 token2Balance
    )  
        public 
        view 
        returns(uint256 amount2send) 
    {
        
        //amount2send = token2Amount.mul(DECIMALS).mul(1e6).div(buyExchangeRateAverage(token2Balance,token2Balance.add(token2Amount)));    
        
        // implement formula a+bY(t)+(b/2)*y
        amount2send = token2Amount.div(
            _priceFloor.mul(DECIMALS)
            .add(
                token2Balance.mul(_numerator).div(_denominator)
            ).add(
                token2Amount.mul(_numerator).div(_denominator).div(2)
            )
        );
    }
    
    /**
     * Calculate average rate beetween initial balance and balance after exchange
     * 
     * @param token2BalanceStart - overall balance of token#2 before exchange
     * @param token2BalanceEnd - overall balance of token#2 after exchange
     */
    function buyExchangeRateAverage(
        uint256 token2BalanceStart, 
        uint256 token2BalanceEnd
    ) 
        public 
        view 
        returns(uint256 rate) 
    {
        rate = _priceFloor.mul(DECIMALS).add(
            (token2BalanceStart.add(token2BalanceEnd).div(2)).mul(1e6).mul(_numerator).div(_denominator)
        );
    }
    
    /**
     * How much token#2 need to send to user by getting token#1
     * 
     * @param token1Amount  - amount token#1 sent by user to getting token#2
     * @param token1Balance - overall balance of token#1 before exchange
     * @param token2Balance - overall balance of token#2 before exchange
     * 
     */
    function sellExchangeAmount(
        uint256 token1Amount, 
        uint256 token1Balance, 
        uint256 token2Balance
    )  
        public 
        view 
        returns(uint256 amount2send) 
    {
        //amount2send = token1Amount.mul(sellExchangeRateAverage(token1Balance, token1Balance.add(token1Amount))).div(1e6).div(DECIMALS);
        
        // implement formula (2/b)*x-(2*a)/b-2*Y(t) ==> 2*x*denom/numerator - 2*a*denom/numerator-2*Y(t)
        
        // `ret` can be less than 0. mean that sub from overall amount. so use trick (x>=0) ? x : -x
        // int256 ret = int256(((token1Amount).mul(2).mul(_denominator).div(_numerator)))
        //             .sub(int256(
        //                 _priceFloor.mul(DECIMALS).mul(2).mul(_denominator).div(_numerator)
        //                 ))
        //             .sub(int256(
        //                 token2Balance.mul(2)
        //                 ));
        // implement formula (a+b/Y(t)) / (1/x-b/2)
        int256 ret =  int256(
            (
                _priceFloor.mul(DECIMALS).add(
                    (_numerator.div(_denominator)).div(token2Balance)
                )
            ).div(
                (uint256(1).div(token1Amount)).sub(_numerator.div(_denominator).div(2))
            )
        );  

                        
        amount2send = (ret >= 0) ? uint256(ret) : uint256(-ret);
        // discount apply
        amount2send = amount2send.mul(_discount).div(1e6);
         
    }
    
    /**
     * Calculate average rate beetween initial balance and balance after exchange
     * 
     * @param token1BalanceStart - overall balance of token#1 before exchange
     * @param token1BalanceEnd - overall balance of token#1 after exchange
     */
    function sellExchangeRateAverage(
        uint256 token1BalanceStart, 
        uint256 token1BalanceEnd
    ) 
        public 
        view 
        returns(uint256 rate) 
    {
        uint256 t = _priceFloor.mul(DECIMALS).add( (token1BalanceEnd.add(token1BalanceStart)).div(2) );
        rate = t.mul(1e6).mul(_numerator).div(_denominator).mul(_discount).div(1e6);

    }
    
}