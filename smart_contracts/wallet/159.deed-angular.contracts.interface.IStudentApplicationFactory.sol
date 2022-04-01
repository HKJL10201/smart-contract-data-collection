pragma solidity ^0.6.6;

interface IStudentApplicationFactory {

    function newStudentApplication(
        address,
        address,
        address,
        address,
        bytes32
    ) external returns (address);
    
}