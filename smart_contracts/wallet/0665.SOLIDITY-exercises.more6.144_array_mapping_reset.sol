//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.1;

contract Stackoverflow {
    mapping(address => uint) public donors;
    address[] public donorsArray;

    function addDonors(uint amount) external payable {
        donors[msg.sender] = amount;
        donorsArray.push(msg.sender);
    }

    //it resets everything
    function withdrawAll() external {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "failed to sent all money");

        for(uint i = 0; i<donorsArray.length; i++) {
            donors[donorsArray[i]] = 0;
        }

        delete donorsArray;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getArrayLength() external view returns(uint) {
        return donorsArray.length;
    }

}