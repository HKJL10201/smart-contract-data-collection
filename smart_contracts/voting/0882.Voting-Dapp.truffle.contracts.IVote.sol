// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IVote{
    function Vote(address candidate, uint NID) external;
    function Winner() external returns(address winner);
}
