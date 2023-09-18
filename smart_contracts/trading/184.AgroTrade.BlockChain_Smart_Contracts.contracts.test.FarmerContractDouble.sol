pragma solidity >=0.5.0;

import '../farmer/FarmerContract.sol';

contract FarmerContractDouble is FarmerContract {
    function getTrust(address _farmer) public view returns (uint256 trust) {
        trust = farmers[_farmer].trust;
    }
}
