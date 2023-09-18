// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./Constants.sol";
import "./Structures.sol";

contract Ballot is Constants,Structures{
    BallotDetails[] mayorBallots;
    BallotDetails[] deputyBallots;
    BallotDetails[] wardBallots;
    CandidateDetails[] candidates;
    VoterDetails[] voters;

    function vote(uint256 _voter_id, uint256 _candidate_id,string memory _election_type, string memory _position) public payable {
        // vote duplicacy validation
        if(DistrictLevelPositionDict[_position] == 1101 && mayorBallots.length > 0){
            for (uint256 i = 0; i < mayorBallots.length; i++) {
                if(mayorBallots[i].voter_id == _voter_id && mayorBallots[i].candidate_id == _candidate_id){
                    return;
                }
            }
        }else if(DistrictLevelPositionDict[_position] == 1102 && deputyBallots.length > 0){
            for (uint256 i = 0; i < deputyBallots.length; i++) {
                if( deputyBallots[i].voter_id == _voter_id && deputyBallots[i].candidate_id == _candidate_id){
                    return;
                }
            }
        }else if(DistrictLevelPositionDict[_position] == 1103 && wardBallots.length > 0){
            for (uint256 i = 0; i < wardBallots.length; i++) {
                if( wardBallots[i].voter_id == _voter_id && wardBallots[i].candidate_id == _candidate_id){
                    return;
                }
            }
        }

        // vote limit count
        for (uint256 i = 0; i < voters.length; i++) {
            if(voters[i].citizenship_number == _voter_id){
                if( voters[i].limitCount >= 3){
                    return;
                }
            }
        }

        // increase the vote limit count
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i].citizenship_number == _voter_id) {
                voters[i].limitCount = voters[i].limitCount + 1;
                break;
            }
        }

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].citizenship_number == _candidate_id) {
                candidates[i].totalVotes = candidates[i].totalVotes + 1;
                break;
            }
        }

        // store votes
        BallotDetails memory details = BallotDetails(_voter_id, _candidate_id);
        
        if(DistrictLevelPositionDict[_position] == DistrictLevelPositionDict["Mayor"]){ 
            mayorBallots.push(details);
        }else if(DistrictLevelPositionDict[_position] == DistrictLevelPositionDict["Deputy Mayor"]){
            deputyBallots.push(details);
        }else{
            wardBallots.push(details);
        }
    }

    function addCandidate(
        uint256 _citizenship_number,
        string memory _name,
        string memory _email,
        string memory _party,
        string memory _electionType,
        string memory _position
    ) public {
        // store candidates
        CandidateDetails memory details = CandidateDetails(
            _citizenship_number,
            0,
            _name,
            _email,
            _party,
            _electionType,
            _position
        );
        candidates.push(details);
    }

    function addVoter(
        uint256 _citizenship_number,
        string memory _name,
        string memory _email
    ) public {
        // store voter
        VoterDetails memory details = VoterDetails(
            _citizenship_number,
            _name,
            _email,
            0
        );
        voters.push(details);
    }

    function getVoterDetails(uint256 _citizenship_number)
        public
        view
        returns (VoterDetails memory)
    {
        VoterDetails memory result;
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i].citizenship_number == _citizenship_number) {
                result = voters[i];
                break;
            }
        }

        return result;
    }

    function getCandidateDetails(uint256 _citizenship_number)
        public
        view
        returns (CandidateDetails memory)
    {
        CandidateDetails memory result;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].citizenship_number == _citizenship_number) {
                result = candidates[i];
                break;
            }
        }

        return result;
    }

    function getAllCandidates()
        public
        view
        returns (CandidateDetails[] memory)
    {
        return candidates;
    }

    function getAllParties() public view returns (string[] memory) {
        return Parties;
    }

    function getAllElectionType() public view returns (string[] memory) {
        return ElectionType;
    }

    function getAllDistrictLevelPosition()
        public
        view
        returns (string[] memory)
    {
        return DistrictLevelPosition;
    }

    function getAllProvince() public view returns (string[] memory) {
        return Provinces;
    }

    // filter highest vote         [Helper function]
    function getWinnerId(string memory _position)
        public
        view
        returns (uint256)
    {
        uint256 winnerId = 0;
        uint256 tempVoteCount = 0;
        // mayor winner
        for (uint256 i = 0; i < candidates.length; i++) {
            if (DistrictLevelPositionDict[candidates[i].position] == DistrictLevelPositionDict[_position]) { 
                if (candidates[i].totalVotes > tempVoteCount) {
                    winnerId = candidates[i].citizenship_number;
                    tempVoteCount = candidates[i].totalVotes;
                }
            }
        }

        return winnerId;
    }

    function getWinners(string memory _electionType) public view returns (WinnerDetails memory){
        if(ElectionTypeDict[_electionType] == 3303){
            return WinnerDetails(getWinnerId("Mayor"),getWinnerId("Deputy Mayor"),getWinnerId("Ward Chairperson"));
        }else{
            return WinnerDetails(0,0,0);
        }
    }
}


// 11,parbat,a@gmail.com,NEPALI CONGRESS,Local Election,Mayor
// 12,hari,b@gmail.com,EMALAY,Local Election,Mayor
// 13,gopal,g@gmail.com,MAOIST,Local Election,Mayor

// 14,krishna,a@gmail.com,NEPALI CONGRESS,Local Election,Deputy Mayor
// 15,suman,b@gmail.com,EMALAY,Local Election,Deputy Mayor
// 16,gautam,g@gmail.com,MAOIST,Local Election,Deputy Mayor

// 17,imran,a@gmail.com,NEPALI CONGRESS,Local Election,Ward Chairperson
// 18,khan,b@gmail.com,EMALAY,Local Election,Ward Chairperson
// 19,juma,g@gmail.com,MAOIST,Local Election,Ward Chairperson

// 21,karma,k@gmail.com
// 22,jamal,j@gmail.com
// 23,jira,i@gmail.com
// 24,mira,mi@gmail.com
// 25,lioom,li@gmail.com
// 26,zoomal,z@gmail.com


// ******* voters vote ******

// 21,11,Local Election,Mayor
// 21,15,Local Election,Deputy Mayor
// 21,17,Local Election,Ward Chairperson


// 22,13,Local Election,Mayor
// 22,14,Local Election,Deputy Mayor
// 22,15,Local Election,Ward Chairperson

// 23,12,Local Election,Mayor
// 23,15,Local Election,Deputy Mayor
// 23,17,Local Election,Ward Chairperson

// 24,12,Local Election,Mayor
// 24,17,Local Election,Deputy Mayor
// 24,16,Local Election,Ward Chairperson

// 25,12,Local Election,Mayor
// 25,14,Local Election,Deputy Mayor
// 25,18,Local Election,Ward Chairperson

// 26,13,Local Election,Mayor
// 26,16,Local Election,Deputy Mayor
// 26,19,Local Election,Ward Chairperson
