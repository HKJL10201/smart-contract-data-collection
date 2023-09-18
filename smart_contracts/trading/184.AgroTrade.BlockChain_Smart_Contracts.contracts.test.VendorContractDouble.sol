pragma solidity >=0.5.0;

import '../vendor/VendorContract.sol';

contract VendorContractDouble is VendorContract {
    function getTrust(address _vendor) public view returns (uint256 trust) {
        trust = vendors[_vendor].trust;
    }
}
