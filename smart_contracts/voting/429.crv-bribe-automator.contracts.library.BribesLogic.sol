// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../interfaces/curve/IBribeV2.sol";
import "../../interfaces/token/IERC20.sol";

library BribesLogic {
    /// @dev sends the token incentives to curve gauge votes for the next vote cycle/period
    /// @param _token Address of the reward/incentive token
    /// @param _gauge address of the curve gauge
    /// @param _tokensPerVote number of tokens to add as incentives per vote
    /// @param _lastPeriod the last voting cycle that the bribe was sent. (this is to prevent double bribing for the same cycle)
    /// @param _curveBribe The contract address of the curve BribeV2 contract
    function sendBribe(address _token, address _gauge, uint _tokensPerVote, uint _lastPeriod, address _curveBribe) public returns (uint) {
        uint balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "No tokens");

        if (_tokensPerVote > balance) {
            _tokensPerVote = balance;
        }

        // this makes sure that the token incentives can be sent only once per vote 
        require (block.timestamp > _lastPeriod + 604800, "Bribe already sent"); // 604800 seconds in 1 week

        IBribeV2(_curveBribe).add_reward_amount(_gauge, _token, _tokensPerVote);
        return IBribeV2(_curveBribe).active_period(_gauge, _token);
    }
}