// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract FakeBusters {
    
    event PollCreated(uint256 indexed _id, address indexed _submitter, string _url); 
    event PollClosed(uint256 indexed _id, Outcome _gameOutcome, Outcome _votingOutcome, Outcome _certOutcome); 
    // event Voted(uint256 indexed _id, address indexed _voter, Outcome _belief); 
    // event Certified(uint256 indexed _id, address indexed _certifier, Outcome _belief); 

    // event ClosingDetails(uint256 indexed _id, uint256 totalTrueVoteStake, uint256 totalFalseVoteStake, uint256 totalOpinionVoteStake, uint256 totalTrueCertStake, uint256 totalFalseCertStake, uint256 totalOpinionCertStake); 
    // event Debug(string info); 

    enum Outcome { FALSE, TRUE, OPINION, NO_DECISION }

    struct Belief {
        uint256 trueStake; 
        uint256 falseStake;
        uint256 opinionStake; // add enhancement 7/01: amount of opinion stake for busters
    }
 
    struct Poll {
        address submitter; 
        bool open;

        uint256 totalTrueVoteStake; 
        uint256 totalFalseVoteStake; 
        uint256 totalOpinionVoteStake; // add enhancement 7/01: amount of opinion stake for busters
        mapping(address => Belief) votes; 

        uint256 totalTrueCertStake;
        uint256 totalFalseCertStake; 
        uint256 totalOpinionCertStake; // add enhancement 7/01: opinion stake for certifiers
        mapping(address => Belief) certs; 

        // outcomes 
        Outcome votingOutcome; 
        Outcome certOutcome; 
        Outcome gameOutcome; 

        uint256 certReward; 
    }

    // all polls 
    mapping(uint256 => Poll) polls; 

    // active polls
    uint256[] public activePolls; 
    mapping(uint256 => uint256) pollToIndex; 

    function getActivePolls() public view returns(uint256[] memory) {
        return activePolls; 
    }

    function addActivePoll(uint256 pollId) public {
        activePolls.push(pollId); 
        pollToIndex[pollId] = activePolls.length; // store the index+1 (to avoid problems since default for uint is 0)  
    }

    function removeActivePoll(uint256 pollId) public {
        uint index = pollToIndex[pollId]; 
        require(index > 0); // otherwise means that the poll is not inside the activePolls array 

        // swap the last and the removed elements 
        if(activePolls.length > 1) {
            activePolls[index-1] = activePolls[activePolls.length-1]; 
            pollToIndex[activePolls[index-1]] = index;  // store always the index+1
        }
        activePolls.pop(); // remove last element and update length 
    }

    uint256 public constant MAX_VOTE_STAKE = 10000000000000000; 
    uint256 public constant MIN_CERT_STAKE = 100000000000000000; 
    uint256 public constant VOTE_STAKE_LIMIT = 290000000000000000; 
    uint256 public constant SUBMISSION_FEE = 20000000000000000; 

    uint256 trueRewardPool = 0; 
    uint256 falseRewardPool = 0; 
    uint256 opinionRewardPool = 0; // add enhancement 7/01: new pool in order to not penalize certifier in case of opinion
    uint256 tetha = 10; 

    /** SUBMITTER **/ 
    function submit(string memory url) public payable { 
        // check minimum submission fee 
        require(msg.value >= SUBMISSION_FEE); 

        // check that the url has not been already sent     
        uint256 hash = uint(keccak256(abi.encodePacked(url)));
        require(polls[hash].submitter == address(0)); 

        // set the poll to active status 
        polls[hash].submitter = msg.sender; 
        polls[hash].open = true; 

        // add poll to the active polls 
        addActivePoll(hash); 

        emit PollCreated(hash, msg.sender, url); 
    }

    /** VOTER **/ 
    function random() public view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));  
    }

    struct VoteReservation {
        uint256 pollId; 
        uint256 stake; 
    }
    mapping(address => VoteReservation) public voterReservations;  
    function requestVote() public payable {
        // check the voter has not already request an id (assume no poll has id == 0) 
        require(voterReservations[msg.sender].pollId == 0); 

        // check max voting stake 
        require(msg.value <= MAX_VOTE_STAKE); 
        
        // get id of random poll 
        uint randomIndex = random() % activePolls.length;  
        uint256 randomId = activePolls[randomIndex]; 

        // store the reservation 
        VoteReservation memory voteReservation = VoteReservation({pollId: randomId, stake: msg.value});
        voterReservations[msg.sender] = voteReservation; 
    }

    function outcomeToString(Outcome outcome) internal pure returns (string memory) {
        if(outcome == Outcome.TRUE) return "TRUE"; 
        if(outcome == Outcome.FALSE) return "FALSE"; 
        if(outcome == Outcome.OPINION) return "OPINION"; 
        if(outcome == Outcome.NO_DECISION) return "NO_DECISION"; 
    }

    function vote(Outcome belief) public {
        // check that the voter has previously request a reservation 
        VoteReservation storage reservation = voterReservations[msg.sender]; 
        require(reservation.pollId != 0); 

        Poll storage currentPoll = polls[reservation.pollId];  

        // check that the poll actually exist and its open 
        require(currentPoll.submitter != address(0));
        require(currentPoll.open == true); 

        // check maximum voting stake ??? 
        // require(reservation.stake + polls[reservation.pollId].votes[msg.sender] <= MAX_VOTE_STAKE);  
        
        if(belief == Outcome.TRUE) {
            currentPoll.votes[msg.sender].trueStake += reservation.stake; 
            currentPoll.totalTrueVoteStake += reservation.stake; 
        } else if(belief == Outcome.FALSE){
            currentPoll.votes[msg.sender].falseStake += reservation.stake; 
            currentPoll.totalFalseVoteStake += reservation.stake; 
        } else {
            currentPoll.votes[msg.sender].opinionStake += reservation.stake; 
            currentPoll.totalOpinionVoteStake += reservation.stake; 
        }      
        
        // emit Voted(reservation.pollId, msg.sender, belief); 

        // Termination condition 
        if(currentPoll.totalTrueVoteStake + currentPoll.totalFalseVoteStake + currentPoll.totalOpinionVoteStake >= VOTE_STAKE_LIMIT) {
            currentPoll.open = false; 
           
            // set outcomes 
            //______________________
            //|    | T   F   O   U  |
            //|----|----------------|
            //|  T | U   U   U   U  |
            //|  F | U   F   U   U  |
            //|  O | U   U   O   U  |
            //|  U | U   U   U   U  |
            //|____|________________|

            //outcome from busters
            if(currentPoll.totalFalseVoteStake > currentPoll.totalTrueVoteStake){ // F > T
                // emit Debug("totalFalseVoteStake > totalTrueVoteStake"); 
                currentPoll.votingOutcome = currentPoll.totalFalseVoteStake > currentPoll.totalOpinionVoteStake ? Outcome.FALSE : // T < F > O
                (currentPoll.totalFalseVoteStake < currentPoll.totalOpinionVoteStake ? Outcome.OPINION : Outcome.NO_DECISION); // O > F > T : F == O > T
            }
            else if(currentPoll.totalFalseVoteStake < currentPoll.totalTrueVoteStake){ // T > F
                // emit Debug("totalFalseVoteStake < totalTrueVoteStake"); 
                currentPoll.votingOutcome = currentPoll.totalTrueVoteStake > currentPoll.totalOpinionVoteStake ? Outcome.TRUE : // F < T > O
                (currentPoll.totalTrueVoteStake < currentPoll.totalOpinionVoteStake ? Outcome.OPINION : Outcome.NO_DECISION); // O > T > F : T == O > F
            }
            else {
                currentPoll.votingOutcome = currentPoll.totalOpinionVoteStake > currentPoll.totalTrueVoteStake ? Outcome.OPINION : Outcome.NO_DECISION; // T == F < O : T == F >= O 
                // emit Debug("Voting ELSE"); 
            }
            // emit Debug(string(abi.encodePacked("votingOutcome: ", outcomeToString(currentPoll.votingOutcome)))); 

            // outcome from experts (same of busters)
            if(currentPoll.totalFalseCertStake > currentPoll.totalTrueCertStake){ 
                // emit Debug("totalFalseCertStake > totalTrueCertStake"); 
                currentPoll.certOutcome = currentPoll.totalFalseCertStake > currentPoll.totalOpinionCertStake ? Outcome.FALSE :
                (currentPoll.totalFalseCertStake < currentPoll.totalOpinionCertStake ? Outcome.OPINION : Outcome.NO_DECISION);
            }
            else if(currentPoll.totalFalseCertStake < currentPoll.totalTrueCertStake){
                // emit Debug("totalFalseCertStake < totalTrueCertStake"); 
                currentPoll.certOutcome = currentPoll.totalTrueCertStake > currentPoll.totalOpinionCertStake ? Outcome.TRUE :
               (currentPoll.totalTrueCertStake < currentPoll.totalOpinionCertStake ? Outcome.OPINION : Outcome.NO_DECISION);
            }
            else { 
                // emit Debug("Cert ELSE"); 
                currentPoll.certOutcome = currentPoll.totalOpinionCertStake > currentPoll.totalTrueCertStake ? Outcome.OPINION : Outcome.NO_DECISION;
            }
            // emit Debug(string(abi.encodePacked("certOutcome: ", outcomeToString(currentPoll.certOutcome)))); 
            
            currentPoll.gameOutcome = currentPoll.votingOutcome == currentPoll.certOutcome ? 
                currentPoll.votingOutcome : Outcome.NO_DECISION; 

            if(currentPoll.gameOutcome == Outcome.NO_DECISION) {
                // if no decision is taken, the submission fee goes to the reward pools 
                
                if(currentPoll.certOutcome == Outcome.NO_DECISION) { 
                    trueRewardPool += SUBMISSION_FEE / 3;
                    falseRewardPool += SUBMISSION_FEE / 3;
                    opinionRewardPool += SUBMISSION_FEE / 3; 
                } else if(currentPoll.certOutcome == Outcome.TRUE) {
                    falseRewardPool += SUBMISSION_FEE / 2;
                    opinionRewardPool += SUBMISSION_FEE / 2; 
                } else if(currentPoll.certOutcome == Outcome.FALSE) {
                    trueRewardPool += SUBMISSION_FEE / 2;
                    opinionRewardPool += SUBMISSION_FEE / 2; 
                } else {
                    trueRewardPool += SUBMISSION_FEE / 2;
                    falseRewardPool += SUBMISSION_FEE / 2;
                }
            } else {
                // save the reward to give to the certifiers 
                if(currentPoll.certOutcome == Outcome.TRUE) {
                    currentPoll.certReward = trueRewardPool / tetha; 
                } else if(currentPoll.certOutcome == Outcome.FALSE) {
                    currentPoll.certReward = falseRewardPool / tetha; 
                } else if(currentPoll.certOutcome == Outcome.OPINION){
                    currentPoll.certReward = opinionRewardPool / tetha; 
                }
            }
        
            // emit closing event 
            // emit ClosingDetails(reservation.pollId, currentPoll.totalTrueVoteStake, currentPoll.totalFalseVoteStake, currentPoll.totalOpinionVoteStake, currentPoll.totalTrueCertStake, currentPoll.totalFalseCertStake, currentPoll.totalOpinionCertStake); 
            emit PollClosed(reservation.pollId, currentPoll.gameOutcome, currentPoll.votingOutcome, currentPoll.certOutcome); 

            // remove poll from activePolls 
            removeActivePoll(reservation.pollId); 
        }

        // delete reservation (all values are set to 0 or default) 
        delete voterReservations[msg.sender]; 
    }

    /** CERTIFIER **/ 
    function certify(uint256 pollId, Outcome belief) public payable {
        // check that the poll actually exist and its open 
        require(polls[pollId].submitter != address(0));
        require(polls[pollId].open == true); 

        // check min voting stake 
        require(msg.value >= MIN_CERT_STAKE);  
        
        if(belief == Outcome.TRUE) {
            polls[pollId].certs[msg.sender].trueStake += msg.value; 
            polls[pollId].totalTrueCertStake += msg.value; 
        } else if(belief == Outcome.FALSE){
            polls[pollId].certs[msg.sender].falseStake += msg.value; 
            polls[pollId].totalFalseCertStake += msg.value; 
        } else{
            polls[pollId].certs[msg.sender].opinionStake += msg.value;
            polls[pollId].totalOpinionCertStake += msg.value; 
        }
        
        // emit Certified(pollId, msg.sender, belief);  
    }

    function withdraw(uint256 poolId) public payable{
        Poll storage currentPoll = polls[poolId]; 
        require(currentPoll.open == false, "poll is not closed"); 

        uint256 reward = 0; 
    
        // check votes 
        if(currentPoll.gameOutcome == Outcome.NO_DECISION) 
            reward += currentPoll.votes[msg.sender].trueStake + currentPoll.votes[msg.sender].opinionStake + currentPoll.votes[msg.sender].falseStake; 
        else if(currentPoll.gameOutcome == Outcome.TRUE && currentPoll.votes[msg.sender].trueStake > 0)
            reward +=  currentPoll.votes[msg.sender].trueStake + currentPoll.votes[msg.sender].trueStake * SUBMISSION_FEE / currentPoll.totalTrueVoteStake; 
        else if(currentPoll.gameOutcome == Outcome.FALSE && currentPoll.votes[msg.sender].falseStake > 0)
            reward += currentPoll.votes[msg.sender].falseStake + currentPoll.votes[msg.sender].falseStake * SUBMISSION_FEE / currentPoll.totalFalseVoteStake; 
        else if(currentPoll.gameOutcome == Outcome.OPINION && currentPoll.votes[msg.sender].opinionStake > 0)
            reward += currentPoll.votes[msg.sender].opinionStake + currentPoll.votes[msg.sender].opinionStake * SUBMISSION_FEE / currentPoll.totalOpinionVoteStake; 

        // check certs 
        if(currentPoll.gameOutcome == Outcome.TRUE && currentPoll.certs[msg.sender].trueStake > 0)
            reward += currentPoll.certs[msg.sender].trueStake + currentPoll.certReward  * currentPoll.certs[msg.sender].trueStake / currentPoll.totalTrueCertStake; 
        else if (currentPoll.gameOutcome == Outcome.FALSE && currentPoll.certs[msg.sender].falseStake > 0)
            reward +=currentPoll.certs[msg.sender].falseStake + currentPoll.certReward  * currentPoll.certs[msg.sender].falseStake / currentPoll.totalFalseCertStake;         
        else if (currentPoll.gameOutcome == Outcome.OPINION && currentPoll.certs[msg.sender].falseStake > 0)
            reward += currentPoll.certs[msg.sender].opinionStake + currentPoll.certReward  * currentPoll.certs[msg.sender].opinionStake / currentPoll.totalOpinionCertStake;   

        // send reward
        if(reward > 0) {
            payable(msg.sender).transfer(reward);
        }
    }   
}
