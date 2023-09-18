pragma solidity ^0.5.17;

contract EvmPoll{


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
                           string memory _state,
                           uint
                           _no_days
                           ) adminPrivilege public {

            require(bytes(polls[string(abi.encodePacked(_state, _poll_name))].poll_name).length == 0);
            polls[string(abi.encodePacked(_state, _poll_name))] =  Polls(_poll_name, _state, 0,now,now +(_no_days*24*60*60),msg.sender, 0);
            poll_count += 1;


    }


    // The contract creator will be able to add admins
    function addAdmin(string memory _email, string memory _state_id, address _wallet_address) ecPrivilege public{
            require(bytes(admins[_wallet_address].state_id).length == 0);
            admins[_wallet_address] =  Admin(_state_id, _email);
            admin_count += 1;
    }


    // The admins can add new voters
    function addVoter(string memory _state_id, string memory _email, string memory _state, address voter_address) adminPrivilege public {
        require(bytes(voters[voter_address].state_id).length == 0);
        voters[voter_address]=Voter(_state_id,_email, _state);
        voter_count +=1 ;
    }



    // The admins can add a candidate based on a specific poll
    function addCandidate(string memory _state_id,
                          string memory _state,
                          string memory _first_name,
                          string memory _last_name,
                          string memory _gender,
                          string memory _poll_name) adminPrivilege public{

            if(bytes(candidates[_state_id].state_id).length == 0){
                candidates[_state_id] =  Candidate(_state_id, _state, _first_name, _last_name, _gender, _poll_name, msg.sender);
            }
            candidate_vote_tracks[string(abi.encodePacked(_state_id,_poll_name))] = CandidateVoteTrack(_state_id, _poll_name, _state, 0);

            polls[string(abi.encodePacked(_state,_poll_name))].candidates += 1;
            candidate_count += 1;


    }

    // Votes will be submitted directly from the admin's wallet address, and the reward will be transferred to the voter's wallet address
    // The admin's wallet address is used both for every function execution and reward transfer
    // The admin's wallet is used for most of the function execution to avoid voters to pay for their votes
    function castVote(address _voter, string memory _candidate_state_id, string memory _poll_name, string memory _state) adminPrivilege public {
        require(bytes(voters[_voter].state_id).length != 0);
        require(candidates[_candidate_state_id].admin_creator != address(0));
        require(bytes(voter_tracks[string(abi.encodePacked(_voter, _poll_name))].voter_state_id).length == 0);

        // Submitting Vote
        voter_tracks[string(abi.encodePacked(voters[_voter].state_id, _poll_name))] =  VoterTrack(voters[_voter].state_id, _poll_name, _state, _candidate_state_id);
        candidate_vote_tracks[string(abi.encodePacked(_candidate_state_id,_poll_name))].votes += 1;
        polls[string(abi.encodePacked(_state, _poll_name))].total_votes += 1;

        // Updating Variables
        voter_track_count += 1;
        candidate_vote_track_count += 1;
    }



}
