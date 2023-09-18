pragma solidity ^0.4.24;


library BPackedUtils {

    // the uint16 ending at 128 bits should be 0s
    uint256 constant sbMask        = 0xffffffffffffffffffffffffffff0000ffffffffffffffffffffffffffffffff;
    uint256 constant startTimeMask = 0xffffffffffffffffffffffffffffffff0000000000000000ffffffffffffffff;
    uint256 constant endTimeMask   = 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000;

    function packedToSubmissionBits(uint256 packed) internal pure returns (uint16) {
        return uint16(packed >> 128);
    }

    function packedToStartTime(uint256 packed) internal pure returns (uint64) {
        return uint64(packed >> 64);
    }

    function packedToEndTime(uint256 packed) internal pure returns (uint64) {
        return uint64(packed);
    }

    function unpackAll(uint256 packed) internal pure returns (uint16 submissionBits, uint64 startTime, uint64 endTime) {
        submissionBits = uint16(packed >> 128);
        startTime = uint64(packed >> 64);
        endTime = uint64(packed);
    }

    function pack(uint16 sb, uint64 st, uint64 et) internal pure returns (uint256 packed) {
        return uint256(sb) << 128 | uint256(st) << 64 | uint256(et);
    }

    function setSB(uint256 packed, uint16 newSB) internal pure returns (uint256) {
        return (packed & sbMask) | uint256(newSB) << 128;
    }

    // function setStartTime(uint256 packed, uint64 startTime) internal pure returns (uint256) {
    //     return (packed & startTimeMask) | uint256(startTime) << 64;
    // }

    function setEndTime(uint256 packed, uint64 endTime) internal pure returns (uint256) {
        return (packed & endTimeMask) | uint256(endTime);
    }
}
