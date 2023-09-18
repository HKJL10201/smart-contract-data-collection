// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Vote {
    struct Candidate {
        address candidate;
        uint128 vote_count;
    }
    mapping(address => bool) isCandidate;
    uint8 private election_id;
    string public postion_title;
    address private manager;
    Candidate[] public candidate_list;
    uint8 constant public max_no_of_candidate = 10;
    bool public started;
    bool public ended;
    uint256 public election_duration;
    mapping(address => bool) private has_voted;
    bool isInitialized;
    Candidate winner;


    /// The contract has not been initalized, run the initalize function
    error HasNotBeenInit();

    /// You are not the election manager
    error NotManager();

    /// Election has not started 
    error ElectionNotStarted();

    /// Election has ended
    error ElectionHasEnded();

    /// Candidate must be at least two
    error AtLeastTwoCandidate();

    /// Candidates can not be more than ten
    error NotMoreThenTenCandidate();

    /// You are not allowed to vote more than ones
    error CannotVoteMoreThanOnce();

    /// Invalid Candidate 
    error NotACandidate();

    /// Contract has already been init
    error ContractAlreadyInit();



    modifier hasNotBeenInit {
        if(!isInitialized) {
            revert HasNotBeenInit();
        }
      _;
   }

   modifier cannotInitContract {
        if(isInitialized) {
            revert ContractAlreadyInit();
        }
    _;
   }

    modifier notManager {
        if(msg.sender == manager) {
            revert NotManager();
        }
      _;
   }

   modifier electionNotStarted {
        if(!started) {
            revert ElectionNotStarted();
        }
    _;
   }

   modifier electionHasEnded {
        if(ended) {
            revert ElectionHasEnded();
        }
    _;
   }

   modifier atLeastTwoCandidate {
        if(candidate_list.length < 2) {
            revert AtLeastTwoCandidate();
        }
    _;
   }


    event ElectionStarted(Candidate[] candidateList);
    event CandidateAdded(address[] newCandidates);
    event Voted(address voter, address voted);


    /// @dev this function starts the election process
    function start() 
        public 
        hasNotBeenInit 
        notManager 
        atLeastTwoCandidate 
    {
        started = true;
        emit ElectionStarted(candidate_list);
    }

    /// @dev using this function the manager would be able to add candidates to the election
    function addCandidates(
        address[] memory _cand
    )
        public 
        notManager
        hasNotBeenInit
    {
        if(_cand.length > 10) {
            revert NotMoreThenTenCandidate();
        }

        // looping throught the candidate and storing in the array (candidate list)
        for(uint i = 0; i < _cand.length; i++) {
            // creating the candidate struct 
            Candidate memory ss = Candidate(_cand[i], 0);
            isCandidate[_cand[i]] = true;
            candidate_list.push(ss);
        }


        // emiting 
        emit CandidateAdded(_cand);
    }

    /// @dev cast vote (this is where the real voting happens)
    function cast(address _cand) 
        public
        hasNotBeenInit
    {
        // checking if this caller has voted before 
        if(has_voted[msg.sender]) {
            revert CannotVoteMoreThanOnce();
        }

        // checking if the candidate if valid
        if(isCandidate[_cand]) {
            revert NotACandidate();
        }

        // looping the candidate array to obtain the main candidate 
        for (uint i = 0; i < candidate_list.length; i++){
            if(candidate_list[i].candidate == _cand) {
                // casting the vote here
                candidate_list[i].vote_count++;
            }
        }

        emit Voted(msg.sender, _cand);
    }

    /// @dev this function returns the vote count
    function returnVoteCount(address _cand) 
        public 
        view 
        hasNotBeenInit
        returns(Candidate memory cand) 
    {
        for(uint i = 0; i < candidate_list.length; i++) {
            if(candidate_list[0].candidate == _cand) {
                cand = candidate_list[0];
            }
        }
    }

    /// @dev this function returns the voting state
    function returnVotingState() 
        public 
        view 
        hasNotBeenInit
        returns(bool state) {
        state = started;
    }

    /// @dev this function returns the list of candidate struct list
    function returnCandidate() 
        public 
        view 
        hasNotBeenInit
        returns(Candidate[] memory ) {
        return candidate_list;
    }
    
    function endElection() 
        public 
        notManager
        hasNotBeenInit
        returns(Candidate memory can__)
    {
        uint winner_count;

        for (uint i = 0; i < candidate_list.length; i++) {
            if(winner_count < candidate_list[i].vote_count) {
                can__ = candidate_list[i];
                winner_count = candidate_list[i].vote_count;
            }
        }
        
        winner = can__;
    }

    function initalize(uint _election_id, string memory _postion_title, address _manager, uint256 _election_duration) 
        public 
        cannotInitContract
    {
        election_id = uint8(_election_id);
        postion_title = _postion_title;
        isInitialized = true;
        manager = _manager;
        election_duration = _election_duration;
    }
}
