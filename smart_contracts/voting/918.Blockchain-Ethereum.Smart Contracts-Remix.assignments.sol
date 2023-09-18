//pragma solidity >=0.70 <0.90;
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Voteapp{

    struct registeredCandidate{
        uint castvote;       //do
        bool alreadyvoted;   //y/n----or----voted?
        string votername;

    }

    struct castVote{
        string name;
        uint voteCount;
    }
    struct vote{
        address voterAddress;
        bool opt;
    }

    mapping(uint => vote) private votes;
    mapping(address => registeredCandidate) public voters;

    //mapping(address => Voter) public voters;
    // Voters vs. VotesReceived
    // ProposalNames==CandidateList
    //mapping(string => uint256) private votesReceived;
    uint private sum = 0;
    uint public finalVotes = 0;
    uint public numVoters = 0;
    uint public totalVote = 0;


    

    address public chair;    //Chairperson/BallotOfficialName+BallotOfficialAddress
       //Voter class
    string public proposal;                                  //voters=voterRegister
    string public chairName;


    enum Checkpoint{Start, Ongoing, Stop}
        Checkpoint public checkpoint;
        constructor(string memory _chairName,string memory _proposal) {
            chair=msg.sender;
            chairName=_chairName;
            proposal=_proposal;

            checkpoint=Checkpoint.Start;
    }

        modifier condition(bool _condition) {
		    require(_condition);
		    _;
	    }

        modifier restrictedChair() {
            require(msg.sender == chair);
            _;
        }

        modifier currentState(Checkpoint _checkpoint) {
            require(checkpoint == _checkpoint);
            _;
        }
        

        event voterAdded(address registeredCandidate);
        event voteDone(address registeredCandidate);
        event voteStarted();
        event voteStopped(uint finalVotes);

        function addVoter(address _voterAddress, string memory _votername) 
            public
            currentState(Checkpoint.Start)
            restrictedChair 
        {
            registeredCandidate memory poll;    //poll==v
            poll.votername = _votername;
            poll.alreadyvoted = false;
            voters[_voterAddress] = poll;
            numVoters++;
        emit voterAdded(_voterAddress);
        }

        function startVote() public
        
            currentState(Checkpoint.Start)
            restrictedChair
        {
            checkpoint = Checkpoint.Ongoing;     
            emit voteStarted();
        }

        function castBallot(bool _opt) public
        
            currentState(Checkpoint.Ongoing)
            returns (bool alreadyvoted)
            {
                bool found=false;

                if (bytes(voters[msg.sender].votername).length != 0 
                    && !voters[msg.sender].alreadyvoted){
                    voters[msg.sender].alreadyvoted = true;
                    vote memory poll;
                    poll.voterAddress = msg.sender;
                    poll.opt = _opt;
                    if (_opt){
                        sum++; //counting on the go
                    }
                votes[totalVote] = poll;
                totalVote++;
                found = true;
            }
            emit voteDone(msg.sender);
            return found;
            }
        function stopVote()
        public
        currentState(Checkpoint.Ongoing)
        restrictedChair
    {
        checkpoint = Checkpoint.Stop;
        finalVotes = sum; //move result from private countResult to public finalResult
        emit voteStopped(finalVotes);
    }



    
    
}