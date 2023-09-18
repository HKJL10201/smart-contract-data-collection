// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IFaucet {

    function addFunds() external payable;

    function withdraw(uint amount) external;    

}