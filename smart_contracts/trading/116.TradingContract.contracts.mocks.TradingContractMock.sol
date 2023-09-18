pragma solidity >=0.6.0 <0.7.0;

import "../TradingContract.sol";

contract TradingContractMock is TradingContract {
    
    
    constructor (
        address _token1, 
        address _token2,
        uint256 _numerator,
        uint256 _denominator,
        uint256 _priceFloor,
        uint256 _discount,
        uint256 _token1Fee,
        uint256 _token2Fee
    ) 
        TradingContract(_token1, _token2, _numerator, _denominator, _priceFloor, _discount, _token1Fee, _token2Fee) 
        public 
    {
//        _discount = discount;
    }

    
}


