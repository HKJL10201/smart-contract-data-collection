pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
contract Ballot {
    //STRUCTS
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    struct VoterAddress {
        address vWallet;
        bool voted;
        bool weight;
    }

    // ARRAYS
    /*Voter[] public voters; // A dyamic array called 'voters,' containing 'Voter' structs*/
    Proposal[] public proposals; // A dyamic array called 'proposals,' containing 'Proposal' structs
    VoterAddress[] public voterInfo;

    // MAPPING
    mapping(address => VoterAddress) votersMap; // Mapping called 'votersMap.' Like a dictionary, 'address' is the key used to access a specific 'Voter' struct
    mapping(uint => address) registered;
    uint voteWeight; 
    
    //METHODS
    // Constructor that launches upon deployment, and requires an array of strings
    constructor(string[] memory proposalNames, address[] memory voterList) public {  // argument must be an array of strings, which is temorarily stored in 'memory' under the variable 'proposalNames'
        for (uint i = 0; i < proposalNames.length; i++) { // for loop: i = 0, loop through proposalNames array until 'i' is not less than the number of proposals in 'proposalNames' array
            proposals.push(Proposal({ // for each loop take the following info and push it to a new 'Proposal' struct inside of the 'proposals' array
                name: proposalNames[i],  // from the entry at index 'i' in the 'proposalNames' array, update 'name' in the associated 'Proposal' struct
                voteCount: 0 // for every entry in 'proposalNames', update 'voteCount' to 0 in the assocaiated 'Proposal' struct
            }));
        }
        for (uint i = 0; i< voterList.length; i++) {
            votersMap[voterList[i]].weight = true;
            voterInfo.push(VoterAddress({
            vWallet: voterList[i],
            voted: false,
            weight: true
            }));
        }
    }

    function deposit() public payable{
    }

    function contractBal() view public returns (uint) {
        uint amount = address(this).balance;
        return amount;
    }

    function getNumberRegistered() view public returns (uint) { // get function takes no arguments, and returns an unsigned integer
            uint votersCount = voterInfo.length;  // initialze variable 'votersCount' and use the .length method to count the number structs in our 'voters' array
            return votersCount; // return uint stored in 'votersCount' (aka, the number of 'Voter' structs in our 'voters' array)
    }
    // Create a New Proposal Function: creates a new proposal
    function makeProposal(string memory proposalName) public { // accepts as string that is temporarily saved in memory under 'proposalName'
        Proposal memory _proposal;  // inialize a new 'Proposal' struct called '_proposal' to temporarily store data in memory
        _proposal.name = proposalName; // save our new 'proposalName' from above in the the 'name' section of our '_proposal' struct
        proposals.push(_proposal); // save all the data stored in '_proposal' and push/save it to 'proposals' array as a new 'Proposal' struct
    }
    // Get Number of Proposals Function: returns the total number of proposals
    function getNumberProposals() view public returns (uint) { // get function takes no arguments, and returns an unsigned integer
            uint proposalCount = proposals.length; // initialze variable 'proposalCount' and use the .length method to count the number structs in our 'proposals' array
            return proposalCount; // return uint stored in 'proposalCount' (aka, the number of 'Proposal' structs in our 'proposals' array)
    }
    //Modifier to allow 'vote' function below to automatically reimburse/incentivize voting
    modifier refundGas {
        uint256 gasAtStart = gasleft();
        _;
        uint256 gasSpent = gasAtStart - gasleft() + 500000;
        msg.sender.transfer(gasSpent * tx.gasprice);
    }

    // Functin to cast your vote
    function vote(uint proposalIndex) public refundGas { // takes argument of index number in the 'proposals' array you want to vote for
        //VoterAddress memory sender = votersMap[msg.sender]; // initialze variable 'sender' and use the 'votersMap' mapping to find that voter based on their addres 'msg.sender'
        require(votersMap[msg.sender].weight, "You ain't registered son!"); // require that the sender is 'registered' as 'true'
        require(!votersMap[msg.sender].voted, "You cannot vote because you already voted."); // require that the sender's 'voted' status is 'false'
        votersMap[msg.sender].voted = true; // update 'voted' status of sender to 'true' since they have case their vote
        proposals[proposalIndex].voteCount += 1; // add 1 to the 'voteCount' of the 'Proposal' struct in the 'proposals' array at the 'proposalIndex'
        voterInfo.push(VoterAddress({vWallet: msg.sender, voted: true, weight: true}));
    }
    // Function to view the proposal that is winning.
    function winner() public view returns (uint _winningProposalIndex, string memory _winnerName) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) { // iterate through all 'proposals' with 'p' as the index
            if (proposals[p].voteCount > winningVoteCount) { // if the 'voteCount' of 'proposal' at index 'p' is greater than the current 'winningVoteCount,'
                winningVoteCount = proposals[p].voteCount; // then set 'winningVotecount' equal to the voteCount of proposal at index 'p'
                _winningProposalIndex = p;  // returns the index of the winning proposal
                _winnerName = proposals[p].name; // returns the name of the winning proposal
            }
        }
    }
}