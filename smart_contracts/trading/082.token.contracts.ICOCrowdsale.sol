pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol';

import './BitfexToken.sol';
import './RefundableBeforeSoftCapCrowdsale.sol';
import './PostDeliveryCrowdsale.sol';

contract ICOCrowdsale is TimedCrowdsale, PostDeliveryCrowdsale, RefundableBeforeSoftCapCrowdsale {
    constructor
        (
            uint256 _openingTime,
            uint256 _closingTime,
            uint256 _rate,
            uint256 _goal,
            uint256 _hardCap,
            address _wallet,
            BitfexToken _token
        )
        public
        Crowdsale(_rate, _wallet, _token)
        TimedCrowdsale(_openingTime, _closingTime)
        RefundableBeforeSoftCapCrowdsale(_goal)
        PostDeliveryCrowdsale(_hardCap)
        {
        }

    /**
     * @dev Convert wei to tokens
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
      return _weiAmount.mul(10**2).div(rate);
    }
}
