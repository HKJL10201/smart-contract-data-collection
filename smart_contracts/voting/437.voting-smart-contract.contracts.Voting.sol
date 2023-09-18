// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

error CandidateNotFound (
    uint256 candidate_id
);
error NotMeetingTimeConstraints();
error NotAValidPollId();
error PollAlreadyExists();

contract Voting {
    struct Voter {
        string email;
        string name;
        bool hasVoted;
    }
    struct Candidate {
        string name;
        string email;
        uint256 candidateID;
        uint256 votes;
    }
    struct Poll {
        string id;
        string organizationName;
        int256 startTime;
        int256 duration;
        bool isCreated;
    }

    mapping(string => Poll) public polls;
    mapping(string => Candidate[]) public candidates;
    mapping(string => Voter[]) public eligibleVoters;
    /**
    1. Creation of a poll by an organization.
    2. Ability to add eligible participants.
    3. Adding candidates in the poll.
    4. Allowing voters to vote, if they have not done so, and withing the time constraints.
    5. After the end time, remove the poll from the list.
    6. Allow view live vote count.
    7. View the candidates' id.
    */
    
    function createPoll (
        string memory poll_id, 
        string memory org_name,
        int256 start_time,
        int256 duration
    ) public {

        if(polls[poll_id].isCreated) {
            revert PollAlreadyExists();
        }

        Poll memory p;
        p.id = poll_id;
        p.organizationName = org_name;
        p.startTime = start_time;
        p.duration = duration;
        p.isCreated = true;
        polls[poll_id] = p;
    }


    function addEligibleVoters(
        string memory poll_id,
        string memory name,
        string memory email
    ) public {

        if(!polls[poll_id].isCreated) {
            revert NotAValidPollId();
        }

        Voter memory v;
        v.name = name;
        v.email = email;
        v.hasVoted = false;

        eligibleVoters[poll_id].push(v);
    }


    function addCandidate(
        string memory poll_id,
        string memory name,
        uint256 candidate_id,
        string memory email
    ) public {
        
        if(!polls[poll_id].isCreated) {
            revert NotAValidPollId();
        }

        if(int256(block.timestamp) - polls[poll_id].startTime > 0) {
            revert NotMeetingTimeConstraints();
        }

        Candidate memory c;
        c.name = name;
        c.candidateID = candidate_id;
        c.email = email;
        c.votes = 0;

        candidates[poll_id].push(c);
    }


    function addVote(
        string memory poll_id,
        uint256 candidate_id,
        string memory voter_email
    ) public {
        
        if(!polls[poll_id].isCreated) {
            revert NotAValidPollId();
        }

        if(int256(block.timestamp) - polls[poll_id].startTime > polls[poll_id].duration){
            revert NotMeetingTimeConstraints();
        }
        else if(int256(block.timestamp) - polls[poll_id].startTime < 0){
            revert NotMeetingTimeConstraints();
        }

        uint256 n = candidates[poll_id].length;
        bool candidateFound = false;

        for(uint256 i = 0 ;i < n;i++) {

            if(candidates[poll_id][i].candidateID == candidate_id) {
                candidateFound = true;
                uint256 m = eligibleVoters[poll_id].length;
                

                for(uint256 j = 0;j < m;j++) {
                    Voter memory v = eligibleVoters[poll_id][i];

                    /**
                    Comparing hash of the strings as string comparision is not available in solidity.
                    */

                    if(keccak256(abi.encodePacked(voter_email)) == keccak256(abi.encodePacked(v.email))){
                        
                        /**
                        Allow the candidate to vote if he has not voted before.
                        */

                        bool b = eligibleVoters[poll_id][j].hasVoted;
                        if(!b) {
                            candidates[poll_id][i].votes++;
                            eligibleVoters[poll_id][j].hasVoted = true;
                        }
                        break;
                    }
                }
                break;
            }
        }
        if(!candidateFound) {
            revert CandidateNotFound(
                candidate_id
            );
        }
    }


    function getVotes(
        string memory poll_id,
        uint256 candidate_id
    ) public view returns(uint256) {
        
        if(!polls[poll_id].isCreated) {
            revert NotAValidPollId();
        }

        uint256 n = candidates[poll_id].length;
        uint256 votes = 0;

        bool candidateFound = false;
        for(uint256 i = 0;i < n;i++) {
            if(candidates[poll_id][i].candidateID == candidate_id) {
                votes = candidates[poll_id][i].votes;
                candidateFound = true;
                break;
            }
        }

        if(!candidateFound) {
            revert CandidateNotFound(
                candidate_id
            );
        }
        return votes;
    }

    function getCandidateID(
        string memory poll_id,
        uint256 index
        
    ) public view returns(uint256 candidate_id) {
        
        return candidates[poll_id][index].candidateID;
    }

    function deletePoll(
        string memory poll_id
    ) private {

        if(!polls[poll_id].isCreated) {
            revert NotAValidPollId();
        }
        
        if(int256(block.timestamp) - polls[poll_id].startTime <= polls[poll_id].duration){
            revert NotMeetingTimeConstraints();
        }

        delete polls[poll_id];
        delete candidates[poll_id];
        delete eligibleVoters[poll_id];
    }
}

// create poll abc, aaravcorp, 1676355531, 1000
// candi abc, aarav1, 1, aarav1@gmail.com
// candi abc, aarav2, 2, aarav2@gmail.com
// voter abc, aaravO, aaravO@gmail.com
// voter abc, elon, elon@gmail.com
// vote abc, 1, aaravO@gmail.com
// vote abc, 2, elon@gmail.com

// create poll def, jaincorp, 1676353331, 1000
// candi  def, aarav1, 1, aarav1@gmail.com
// candi def, aarav2, 2, aarav2@gmail.com
// voter def, aaravO, aaravO@gmail.com
// voter def, elon, elon@gmail.com
// vote def, 1, aaravO@gmail.com
// vote def, 2, elon@gmail.com