pragma solidity ^0.6.6;

import "./interface/IStudentFactory.sol";
import "./Student.sol";

contract StudentFactory is IStudentFactory {

    function newStudent(bytes32 name, address payable university) public override returns (address studentAddress) {
        Student student = new Student(name, university);
        student.transferOwnership(msg.sender);
        studentAddress = address(student);
    }
    
}