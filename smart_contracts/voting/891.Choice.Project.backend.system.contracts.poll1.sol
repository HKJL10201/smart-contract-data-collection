pragma solidity ^0.5.17;



// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}





contract Insignia47 is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = 'Insignia';
        symbol = 'ins';
        decimals = 0;
        _totalSupply = 1000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }



    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}



contract EvmPoll is Insignia47{


    struct Voter{
        string state_id;
        string email;
        string state;
    }

    struct Candidate{
        string state_id;
        string state;
        string first_name;
        string last_name;
        string gender;
        string poll_name;
        address admin_creator;
    }

    struct Admin{
        string state_id;
        string email;
    }

    struct Polls{
        string poll_name;
        string state;
        uint256 total_votes;
        uint256 created_date;
        uint256 expire_date;
        address admin_creator;
        uint candidates;
    }

    // Mapping index for the object of this structure is the combination of the voter's state_id and the poll_name
    // Used to keep track of all the vote submissions
    struct VoterTrack{
        string voter_state_id;
        string poll_name;
        string state;
        string candidate_state_id;
    }

    // Mapping address for the object of this structure is the combination of the candidate's state_id and the poll_name
    // Used to keep track of the vote counts for individual candidates based on specific polls
    struct CandidateVoteTrack{
        string candidate_state_id;
        string poll_name;
        string state;
        uint votes;

    }

    address public contract_creator;

    mapping(address=> Voter)public voters;
    mapping(string => Candidate) public candidates;
    mapping(address => Admin) public admins;
    mapping(string => Polls) public polls;
    mapping(string => VoterTrack) public voter_tracks;
    mapping(string => CandidateVoteTrack) public candidate_vote_tracks;


    // Keeps track of the total number of voters, polls, candidates, admins, vote submissions, candidates vote details on a specific poll
    uint public voter_count = 0;
    uint public poll_count = 0;
    uint public candidate_count = 0;
    uint public admin_count = 0;
    uint public voter_track_count = 0;
    uint public candidate_vote_track_count = 0;



    constructor() public {
        contract_creator = msg.sender;
    }

    modifier ecPrivilege(){
        require(msg.sender == contract_creator);
        _;
    }

    modifier adminPrivilege(){
        require(bytes(admins[msg.sender].state_id).length != 0);
        _;
    }


    // Polls can only be created by a admin
    // Polls will last for 7 days only
    function createNewPoll(string memory _poll_name,
                           string memory _state
                           ) adminPrivilege public {

            require(bytes(polls[_poll_name].poll_name).length == 0);
            polls[_poll_name] =  Polls(_poll_name, _state, 0,now,now +7 days,msg.sender, 0);
            poll_count += 1;


    }


    // The contract creator will be able to add admins
    function addAdmin(string memory _email, string memory _state_id, address _wallet_address) ecPrivilege public{
            require(bytes(admins[_wallet_address].state_id).length == 0);
            admins[_wallet_address] =  Admin(_state_id, _email);
            admin_count += 1;
    }


    // The admins can add new voters
    function addVoter(string memory _state_id, string memory _email, string memory _state, address from) adminPrivilege public {
        require(bytes(voters[from].state_id).length == 0);
        voters[from]=Voter(_state_id,_email, _state);
        voter_count +=1 ;
    }



    // The admins can add a candidate based on a specific poll
    function addCandidate(string memory _state_id,
                          string memory _state,
                          string memory _first_name,
                          string memory _last_name,
                          string memory _gender,
                          string memory _poll_name) adminPrivilege public{

            candidates[_state_id] =  Candidate(_state_id, _state, _first_name, _last_name, _gender, _poll_name, msg.sender);
            candidate_vote_tracks[string(abi.encodePacked(_state_id,_poll_name))] = CandidateVoteTrack(_state_id, _poll_name, _state, 0);
            polls[_poll_name].candidates += 1;
            candidate_count += 1;


    }

    // During registration of a voter, a voter will be authorized with an Insignia Token
    function authorizeVoter(address _voter) ecPrivilege public{
        if(balanceOf(_voter)==0){
           transfer(_voter,1);
        }
    }


    // Votes will be submitted directly from the admin's wallet address, and the reward will be transferred to the voter's wallet address
    // The admin's wallet address is used both for every function execution and reward transfer
    // The admin's wallet is used for most of the function execution to avoid voters to pay for their votes
    function castVote(address _voter, string memory _candidate_state_id, string memory _poll_name, string memory _state) adminPrivilege public {
        require(bytes(voters[_voter].state_id).length != 0);
        require(candidates[_candidate_state_id].admin_creator != address(0));
        require(bytes(voter_tracks[string(abi.encodePacked(_voter, _poll_name))].voter_state_id).length != 0);
        require(balanceOf(msg.sender) >= 1);

        // Submitting Vote
        voter_tracks[string(abi.encodePacked(_voter, _poll_name))] =  VoterTrack(voters[_voter].state_id, _poll_name, _state, _candidate_state_id);
        candidate_vote_tracks[string(abi.encodePacked(_candidate_state_id,_poll_name))].votes += 1;

        // Transfer Reward
        address payable wallet = address(uint160(_voter));
        wallet.transfer(0.00074 ether);

        // Updating Variables
        voter_track_count += 1;
        candidate_vote_track_count += 1;
    }



}
