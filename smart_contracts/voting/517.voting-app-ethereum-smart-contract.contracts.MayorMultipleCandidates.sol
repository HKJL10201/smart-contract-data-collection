// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract MayorMultipleCandidates {

    struct Conditions {
        uint32 quorum;
        uint32 envelopes_casted;
        uint32 envelopes_opened;
        uint32 candidate_count;
    }
    
    struct Refund {
        uint soul;
        address _candidate;
    }

    struct Candidate {
        address payable id;
        uint vote_count;
        address payable[] voters;
    }

    event CandidateCounts(uint count);
    event Drawn(address _escrow);
    event NewMayor(address _candidate);
    event Sayonara(address _escrow);
    event EnvelopeCast(address _voter);
    event EnvelopeOpen(address _voter, uint _soul, address _candidate);
    
    // address payable[] candidates;
    mapping(address => Refund) souls;
    mapping(address => Candidate) candidates;
    mapping(address => bytes32) envelopes;
    mapping(address => uint) vote_counts;
    address payable[] public candidate_list;
    address payable public escrow;
    // address payable[] voters;
    
    Conditions voting_condition;
    bool private flag = false;    
    address payable private winning_candidate;
    bool private winning_flag;

    
    modifier canVote() {
        require(voting_condition.envelopes_casted < voting_condition.quorum,
                "Cannot vote now, voting quorum has been reached");
        _;
    }
    modifier canOpen() {
        require(voting_condition.envelopes_casted == voting_condition.quorum,
                "Cannot open an envelope, voting quorum not reached yet");
        _;
    }
    modifier canCheckOutcome() {
        require(voting_condition.envelopes_opened == voting_condition.quorum,
                "Cannot check the winner, need to open all the sent envelopes");
        _;
    }


    constructor(address payable _escrow, uint32 _quorum) public {
        escrow = _escrow;
        voting_condition = Conditions({quorum: _quorum, envelopes_casted: 0, envelopes_opened: 0, candidate_count: 0});
    }

    function add_candidate(address payable _candidate) public payable {
        require(msg.value > 0, "Deposite souls must be greater than 0...");
        candidates[_candidate] = Candidate({ id: payable(_candidate), vote_count: 0, voters: new address payable[](0)});
        voting_condition.candidate_count++;
        candidate_list.push(_candidate);
        souls[_candidate] = Refund(msg.value, _candidate);
        emit CandidateCounts(voting_condition.candidate_count);
    }

    function get_candidate_count() public view returns(uint) {
        return voting_condition.candidate_count;
    }

    function get_candidate_vote_count(address _candidate) public view returns(uint) {
        return candidates[_candidate].vote_count;
    }

    function cast_envelope(bytes32 _envelope) canVote public {
        require(voting_condition.candidate_count > 2, "Minimum 3 candidates required");
        
        if(envelopes[msg.sender] == 0x0) // checking if already voted, no increment, else increment
            voting_condition.envelopes_casted++;

        envelopes[msg.sender] = _envelope;
        emit EnvelopeCast(msg.sender);
    }

    function open_envelope(uint _sigil, address _candidate) canOpen public payable {
        require(envelopes[msg.sender] != 0x0, "The sender has not casted any votes");
        
        bytes32 _casted_envelope = envelopes[msg.sender];
        bytes32 _sent_envelope = compute_envelope(_sigil, _candidate, msg.value);

        require(_casted_envelope == _sent_envelope, "Sent envelope does not correspond to the one casted");
        souls[msg.sender] = Refund(msg.value, _candidate);

        candidates[_candidate].vote_count++;
        candidates[_candidate].voters.push(payable(msg.sender));

        // if (_doblon == true)
        //     yaySoul += msg.value;
        // else
        //     naySoul += msg.value;
        
        voting_condition.envelopes_opened++;
        emit EnvelopeOpen(msg.sender, msg.value, _candidate);
    }

    function get_candidate_using_idx(uint idx) public view returns(address) {
        return candidate_list[idx];
    }

    function check_result() public view returns(address, bool) {
        return (winning_candidate, winning_flag);
    }

    function mayor_or_sayonara() canCheckOutcome public {
        require(flag == false, "Envelope can be opened for a single time only.");
        
        flag = true;

        uint winningVote = 0;
        address payable winner;
        uint winningVote2 = 0;
        address payable winner2;

        // WINNER BASED ON VOTE COUNTS
        // for (uint p = 0; p < candidate_list.length; p++) {
        //     address payable candidate_address = candidate_list[p];
        //     uint vote_count = candidates[candidate_address].vote_count;

        //     if (vote_count > winningVote) { // if higher than winningVote - Winner
        //         winningVote = vote_count;
        //         winner = candidate_address;
        //     } else if (vote_count == winningVote) { // if equal to previous winningVote - Draw
        //         winningVote2 = vote_count;
        //         winner2 = candidate_address;
        //     }
        // }

        // WINNER BASED ON SUM OF SOULS
        for (uint i = 0; i < candidate_list.length; i++) {
            address payable candidate_address = candidate_list[i];
            uint soulSum = 0;
            for (uint v = 0; v < candidates[candidate_address].voters.length; v++) {
                address payable voter = candidates[candidate_address].voters[v];
                Refund memory voter_details = souls[voter];
                soulSum += voter_details.soul;
            }
            if (soulSum > winningVote) { // if higher than soulSum - Winner
                winningVote = soulSum;
                winner = candidate_address;
            } else if (soulSum == winningVote) { // if equal to previous soulSum - Draw
                winningVote2 = soulSum;
                winner2 = candidate_address;
            }
        }

        if(winningVote == winningVote2) {
            // WINNER BASED ON VOTE COUNTS
            winningVote = 0;
            winner;
            winningVote2 = 0;
            winner2;
            for (uint p = 0; p < candidate_list.length; p++) {
                address payable candidate_address = candidate_list[p];
                uint vote_count = candidates[candidate_address].vote_count;

                if (vote_count > winningVote) { // if higher than winningVote - Winner
                    winningVote = vote_count;
                    winner = candidate_address;
                } else if (vote_count == winningVote) { // if equal to previous winningVote - Draw
                    winningVote2 = vote_count;
                    winner2 = candidate_address;
                }
            }

            if(winningVote == winningVote2) {
                winning_candidate = winner;
                winning_flag = false;
                WinDraw(false,winner);
            } else {
                winning_candidate = winner;
                winning_flag = true;
                WinDraw(true,winner);
            }            
            // return (winningVote, winner, winningVote2, winner2);
        } else {
            winning_candidate = winner;
            winning_flag = true;
            WinDraw(true,winner);
            // return (winningVote, winner, winningVote2, winner2);
        }

    }

    function WinDraw(bool win, address payable winner) private {
        if(win) {
            // Win case
            for (uint i = 0; i < candidate_list.length; i++) { // amount from loosing candidates to winner
                address payable candidate_address = candidate_list[i];
                if(candidate_address != winner) { // LOSING CANDIATE SOUL TO THE WINNER CANDIDATE
                    Refund memory voter_detail = souls[candidate_address];
                    winner.transfer(voter_detail.soul); 
                    // LOSING VOTERS GET THEIR SOUL BACK
                    for (uint v = 0; v < candidates[candidate_address].voters.length; v++) { 
                        address payable voter = candidates[candidate_address].voters[v];
                        Refund memory loosing_voter_details = souls[voter];
                        voter.transfer(loosing_voter_details.soul);
                    }
                }            
            }            
            Refund memory winner_voter_details = souls[winner];
            uint soul = winner_voter_details.soul;
            uint share = soul / candidates[winner].voters.length;
            for (uint v = 0; v < candidates[winner].voters.length; v++) { // amount from winner to its voter (divided)
                address payable voter = candidates[winner].voters[v];
                voter.transfer(share); 
            }
            emit NewMayor(winner);
        } else {
            // Drawn case
            for (uint i = 0; i < candidate_list.length; i++) {
                address payable candidate_address = candidate_list[i];
                for (uint v = 0; v < candidates[candidate_address].voters.length; v++) {
                    address payable voter = candidates[candidate_address].voters[v];
                    Refund memory voter_details = souls[voter];
                    escrow.transfer(voter_details.soul);
                }                
            }
            emit Drawn(escrow);   
        }
    }
    
    function compute_envelope(uint _sigil, address _candidate, uint _soul) public pure returns(bytes32) {
        return keccak256(abi.encode(_sigil, _candidate, _soul)); // 30 gas + 6 gas for each 256 bits of data being hashed
    }

    
}