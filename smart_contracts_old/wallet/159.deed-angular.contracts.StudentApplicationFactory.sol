pragma solidity ^0.6.6;

import "./interface/IStudentApplicationFactory.sol";
import "./StudentApplication.sol";


contract StudentApplicationFactory is IStudentApplicationFactory {
    function newStudentApplication(
        address studentAddress,
        address classroomAddress,
        address daiAddress,
        address challengeAddress,
        bytes32 seed
    ) public override returns (address studentApplicationAddress) {
        StudentApplication studentApplication = new StudentApplication(
            studentAddress,
            classroomAddress,
            daiAddress,
            challengeAddress,
            seed
        );
        studentApplication.transferOwnership(msg.sender);
        studentApplicationAddress = address(studentApplication);
    }
}
