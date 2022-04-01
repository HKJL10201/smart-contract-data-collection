//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract SendEther {
    function investEthToThisContract() external payable{
        //you dont need specify anything here, on remix panel, 
        // you just need to insert value in value area and click on function button
    }

    function balanceOf() external view returns(uint) {
        return address(this).balance;
    }
}