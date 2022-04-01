pragma solidity ^0.6.6;

import "./interface/IClassroomFactory.sol";
import "./Classroom.sol";


contract ClassroomFactory is IClassroomFactory {
    function newClassroom(
        bytes32 name,
        uint24 principalCut,
        uint24 poolCut,
        int32 minScore,
        uint256 entryPrice,
        uint256 duration,
        address payable universityAddress,
        address challengeAddress,
        address daiAddress,
        address compoundAddress,
        address studentApplicationFactoryAddress
    ) public override returns (address classroomAddress) {
        Classroom classroom = new Classroom(
            name,
            principalCut,
            poolCut,
            minScore,
            entryPrice,
            duration,
            universityAddress,
            challengeAddress,
            daiAddress,
            compoundAddress,
            studentApplicationFactoryAddress
        );
        classroom.transferOwnership(msg.sender);
        classroomAddress = address(classroom);
    }
}
