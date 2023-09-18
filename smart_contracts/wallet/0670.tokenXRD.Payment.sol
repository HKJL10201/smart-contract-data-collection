//SPDX-License-Identifier: GPL 3.0
pragma solidity >=0.7.0 <0.9.0;

import './Ownable.sol';

contract Payment is Ownable {

    function pay() public payable returns (uint256) {
        return 1;
    }

    function getBalance() public view returns (uint256) {
        address contractAddress = (address(this));
        return contractAddress.balance;
    }

    function withdraw(address _recipient) public isOwner returns (bool) {
        uint256 myBalance = getBalance();
        payable(_recipient).transfer(myBalance);
        return true;
    }

}



