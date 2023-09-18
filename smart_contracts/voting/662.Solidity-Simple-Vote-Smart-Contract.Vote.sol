pragma solidity >= 0.8.0;



contract poll{

    enum Decision {ACCEPT, DENY, ABSTAIN}
    
    struct Voter{
        address voterID;
        string voterName;
        uint voterIndex;
        uint voteWeight;
        bool isVoted;
        Decision decision;
    }

    string private pollName;

    uint private numVoters;

    uint private accepters;
    uint private deniers;
    uint private abstains;

    enum VotingState {CLOSED, OPENED, AWAITING}
   
    VotingState private currentState;

    mapping (uint => Voter) private Voters_byindex;
    mapping (address => Voter) private Voters_byaddress;

    constructor(string memory _pollName)
    {
        pollName = _pollName;
        currentState = VotingState.OPENED;
        numVoters = 0;
        accepters = 0;
        deniers = 0;
        abstains = 0;
    }

    modifier checkPollStatus(){ //TO CHECK IF THE POLL WAS ALREADY CLOSED
        require(currentState == VotingState.OPENED, "Poll was already closed");
        _;
    }
    /* modifier checkVoterExists(address _voterID){
         require(Voters_byaddress[msg.sender].voterID == _voterID, "There is any ID related in that poll");
        _;

    }  */


    event votesUpdated(uint accepters,uint deniers, uint abstains);

    function addVoter(string memory _voterName,uint _voteWeight,Decision _decision) public checkPollStatus()
    {
             require(Voters_byaddress[msg.sender].voterID != msg.sender, "You have already voted in that transaction ID"); //FOR CHECKING IF VOTED ID IS ALREADY IN POLL
             //Yet can be sent in the same transaction ID.
             Voters_byindex[numVoters] = Voter({voterID: msg.sender ,voterName:_voterName,voteWeight: _voteWeight, isVoted: false, voterIndex: numVoters, decision: _decision}); //FOR QUICK CALCULATIONS
             Voters_byaddress[msg.sender] = Voter({voterID: msg.sender ,voterName:_voterName,voteWeight: _voteWeight, isVoted: false, voterIndex: numVoters, decision: _decision}); //FOR TRANSACTIONS
             numVoters++;
             updateResults();


    }

    function updateResults() public
    {

        accepters = 0;
        deniers = 0;
        abstains = 0;

        for(uint i=0; i <= numVoters; i++)
        {  
            Voter memory voter = Voters_byindex[i];
            uint weight = 0;
            if(voter.isVoted == false)
            {
                  if(voter.decision == Decision.ACCEPT)
                  {
                    weight = 1 * voter.voteWeight;
                    accepters += weight;
                  }
                  else if(voter.decision == Decision.DENY){
                  
                    weight = 1 * voter.voteWeight;
                    deniers += weight;
                  }
                  else if (voter.decision == Decision.ABSTAIN)   
                  {
                    weight = 1 * voter.voteWeight;
                    abstains += weight;
                  }
                 voter.isVoted = true;   
            }
            emit votesUpdated(accepters,deniers,abstains);
        }
    }

    function Invalidate_Vote(address _voterID) public payable checkPollStatus() //TO INVALIDATE SUSPICIOUS VOTES
    {
        require(Voters_byaddress[msg.sender].voterID == _voterID, "There is any ID related in that poll");
            Voter memory voter = Voters_byaddress[msg.sender];
            address ID = voter.voterID;
            uint index = voter.voterIndex;
            delete(Voters_byaddress[ID]);
            delete(Voters_byindex[index]);
            numVoters -=1;
            updateResults();
    }

    function Increase_VoteWeight(address _voterID) public payable checkPollStatus() //INCREASE VOTE WEIGHT IF VOTER SENDS MORE VALUE
    {   
        uint limitPrice = 1; //Limit price to increase voteWeight
        require(Voters_byaddress[msg.sender].voterID == _voterID, "There isn't any ID related");
        if(msg.value > limitPrice)
        {
            Voters_byaddress[msg.sender].voteWeight += 1;
        }
    }

    function CheckResults() public view returns(string memory)
    {

        if (accepters > (deniers & abstains)) return "PASSED";
    
        else if (deniers > (deniers & abstains)) return "NOT PASSED";

        else return "ABSTAIN";

    }

    function ClosePoll() public checkPollStatus()
    {
         currentState = VotingState.CLOSED;
    }
}



    
   
