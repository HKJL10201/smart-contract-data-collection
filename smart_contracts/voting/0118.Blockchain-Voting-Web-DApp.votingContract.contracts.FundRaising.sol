pragma solidity >=0.4.21 <0.6.0;


contract FundRaising {

    string[] public choices;
    mapping(address => string) public votes;
    mapping(address => string) public allowedAddresses;
    mapping(string => uint256) public voteChoices;

    address[] public voters;
    uint256 public n_choices;
    uint256 public n_voters;
    uint256 public choiceThresh;
    address payable public owner;
    uint256 public voteCount;
    uint256 public voteThresh;
    uint256 public maxVotes;
    uint256 public winningChoice;






    constructor(uint256 _voteThresh, uint256 _choiceThresh) public {
        owner = msg.sender;
        choiceThresh = _choiceThresh;
        voteThresh = _voteThresh;
        voteCount = 0;
        n_choices = 0;
        n_voters = 0;
        maxVotes = 0;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }


    modifier choiceThreshReached {
        require(n_choices >= choiceThresh, "Vote allowed only when number of choices >= choiceThresh");
        _;
    }

    modifier addressCanVote {
        require(keccak256(abi.encodePacked(allowedAddresses[msg.sender])) == keccak256(abi.encodePacked("Allowed")),
         "Voter only allowed to vote if added by owner and voting 1st time");
        _;
    }


    modifier votingCompleted {
        require(voteCount>=voteThresh, "Voting Not Completed");
        _;
    }

    modifier votingNotCompleted {
        require(voteCount<voteThresh, "Voting Completed");
        _;
    }


    function addChoices (string memory c) public onlyOwner {
        choices.push(c);
        n_choices += 1;
        voteChoices[c] = 0;

    }

    function addAddress(address adrs)public onlyOwner{

        if (!(keccak256(abi.encodePacked(allowedAddresses[adrs])) == keccak256(abi.encodePacked("Allowed")))){
            n_voters += 1;
            allowedAddresses[adrs] = "Allowed";

        }


    }

    function vote(uint256 choice_no) public votingNotCompleted choiceThreshReached addressCanVote {
        votes[msg.sender] = choices[choice_no];
        voteChoices[choices[choice_no]] += 1;
        uint256 currVotes = voteChoices[choices[choice_no]];
        allowedAddresses[msg.sender] = "Voted";
        if (currVotes>maxVotes){
            maxVotes = currVotes;
            winningChoice = choice_no;
        }
        voteCount += 1;
    }

    function checkWinner () public view votingCompleted returns(string memory){
        return choices[winningChoice];

    }

    function add() public payable {
        // donations[msg.sender] += msg.value;
        // donatedAmount += msg.value;
        // donors.push(msg.sender);
    }
}
