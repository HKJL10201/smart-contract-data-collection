pragma solidity ^0.6.6;

interface IClassroom {

    function entryPrice() external view returns (uint256);

    function transferOwnershipClassroom(address) external;
    
    function studentApply() external;

    function viewMyApplication() external view returns (address);

    function ownerClassroom() external view returns (address);
}