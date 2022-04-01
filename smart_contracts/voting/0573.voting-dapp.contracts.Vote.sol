// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./VoteToken.sol";
import "./VoterData.sol";

struct Candidate {
    string candidate;
    uint256 count;
    bool exists;
}

contract Vote {
    mapping(string => Candidate) private count;
    string[] public candidateList; // Should be predefined list
    address voterDataAddress;
    address voterTokenAddress;

    constructor() public {
        candidateList = [string("A"), "B"];
        voterDataAddress = 0x99c53cd5Bce3E74965ca0624a03812984629f68D;
        voterTokenAddress = 0x04b2B6FF0b94D2B68dC4fDa10863299E0cB4856D;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i + 2] = char(hi);
            s[2 * i + 3] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    modifier validVoter(address add) {
        require(
            VoterData(voterDataAddress).isAddressInUse(toAsciiString(add)) ==
                true,
            "Not a valid Address"
        );
        _;
    }

    function castVote(string calldata candidate)
        public
        validVoter(msg.sender)
        returns (string memory)
    {
        address voter = msg.sender;

        uint256 checkIfVoted = IERC20(voterTokenAddress).balanceOf(voter);

        require(checkIfVoted == 0, "Already Voted.");

        if (!count[candidate].exists) {
            count[candidate] = Candidate(candidate, 0, true);
        }
        count[candidate].count++;
        bool transferred = IERC20(voterTokenAddress).transfer(voter, 1);
        require(transferred == true, "Transfer of token failed");

        return ("success");
    }

    function getCount(string calldata candidate) public view returns (uint256) {
        uint256 cnt = count[candidate].count;
        return cnt;
    }

    function getCandidates() public view returns (string[] memory) {
        return candidateList;
    }
}
