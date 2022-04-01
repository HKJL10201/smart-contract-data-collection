pragma solidity ^0.6.6;

interface IStudent {

    function transferOwnershipStudent(address) external;

    function ownerStudent() external view returns (address);

    function addScore(int32) external;

    function subScore(int32) external;

    function score() external view returns (int32);
    
}