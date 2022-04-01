// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IIntercoin.sol";

contract IntercoinMock is IIntercoin {

	function checkInstance(address addr) public override view returns(bool) {
        return true;
    }
    
    function registerInstance(address addr) external override returns(bool) {
        return true;
    }

}