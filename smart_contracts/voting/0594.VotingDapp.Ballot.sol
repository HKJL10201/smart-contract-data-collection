contract Ballot {
            struct Candidate{
                uint id;
                string name;
                uint TotalCount;
            }
            Candidate[] public ListOfCandidates;
            uint public totalVote;
            uint VotingTimePeriod;
            address[] ListofECIMembers;
            struct Voter{
                bool authorized;
                bool hasVoted;
                uint vote;
            }
            mapping(address => Voter) public voters;
            address public owner;
            string public electionName;

            address public Owner;

            modifier onlyOwner {
            require(msg.sender == Owner);
            _;
            }

            function _ballot(string _name) public{
                owner = msg.sender;
                electionName = _name;
            }
            function getNumberOfCandidates() public view returns(uint){
                return ListOfCandidates.length;
            }
            function GetMyVote() public view returns(address) {
                require(hasVoted==true,false);
                return CandidateVote;
            }
            function GetResult() public view returns(uint) {
                return totalVote;
            }
            function CastVote(uint _voteIndex) public  {
                require(!voters[msg.sender].hasVoted);
                require(voters[msg.sender].IsRegistred);

                voters[msg.sender].vote = _voteIndex;
                voters[msg.sender].hasVoted = true;

                ListOfCandidates[_voteIndex].voteCount += 1;
                totalVote += 1;
            }
            function GetUserVote(address) public{
                voters[address].hasVoted = false;
                bool permission = voters[address].authorised;
                if(permission == false){
                    return "You are not autharised to vote";
                }
                
            }
            function GetVoteMap() public view returns(address) {
                for(uint i = 0; i<ListOfCandidates.length; i++){
                    return ListOfCandidates[i]+ ListOfCandidates[i]._voteIndex;
                } 
            }
            function ConsolidateVote() {
                
            }
}
