pragma solidity ^0.6.6;

interface IStudentFactory {

    function newStudent(bytes32, address payable) external returns (address);
    
}