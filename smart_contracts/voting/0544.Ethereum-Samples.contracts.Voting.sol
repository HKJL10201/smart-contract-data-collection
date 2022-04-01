pragma solidity ^0.4.4;

contract Voting {
    mapping (bytes32 => uint8) public votesReceived;

    // 存储候选人名字的数组
    bytes32[] public candidateList;

    function Voting(bytes32[] candidateNames) public {

        candidateList = candidateNames;
    }

    function totalVotesFor(bytes32 candidate) public constant returns (uint8) {
        //require(validCandidate(candidate) == true);
        if (validCandidate(candidate) == true) {
            return votesReceived[candidate];
        } else {
            return 0;
        }
    }

    function voteForCandidate(bytes32 candidate) public {
        //assert(validCandidate(candidate) == true);
        if (validCandidate(candidate) == true) {
            votesReceived[candidate] += 1;
            Voted(bytes32ToString(candidate));
        }
    }

    function validCandidate(bytes32 candidate) public constant returns (bool) {
        for (uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i]==candidate) {
                return true;
            }
        }
        return false;
    }

    function bytes32ToString(bytes32 x) constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    event Voted(string candidate);
}