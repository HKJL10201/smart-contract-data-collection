pragma solidity ^0.5.17;


contract Poll{

    // Poll Data ===============================

    struct Polls{
        string poll_name;
        string state;
        uint256 total_votes;
        uint256 created_date;
        uint256 expire_date;
        address admin_creator;
        uint candidates;
    }
    
    // Users for the poll ============================
    struct Voter{
        string state_id;
        string email;
        address wallet_address;         
    }

    struct Admin{
        string state_id;
        string email;
        address wallet_address;
        bool super_admin;
    }

    // Candidates for the poll
    struct Candidate{
        string state_id;
        string state;
        string first_name;
        string last_name;
        string gender;
        string poll_name;
        uint votes;
    }

    // Mapping of all the users
    mapping(address => Voter) public voters;
    uint voter_count = 0;
    mapping(address => Admin) public admins;
    uint admin_count = 0;
    mapping(string => Polls) public polls;
    uint poll_count = 0;
    mapping(string => Candidate) public candidates;
    uint candidate_count = 0;



    // Adding Voter Details
    function addVoter(string memory _email, string memory _state_id, address _wallet_address) public{

        if(voters[_wallet_address].wallet_address == address(0)){
            voters[_wallet_address] =  Voter(_state_id, _email, _wallet_address);
            voter_count += 1;
        }
        
    }

    // Checking if Wallet ID belongs to a voter
    function isVoter(address _wallet_address) public view returns (bool){

        if(voters[_wallet_address].wallet_address == address(0)){
            return false;
        }

        else{
            return true;
        }
        
      
    }

    // Adding Admin Details
    function addAdmin(string memory _email, string memory _state_id, address _wallet_address, bool _super_admin) public{

        if(admins[_wallet_address].wallet_address == address(0)){
            admins[_wallet_address] =  Admin(_state_id, _email, _wallet_address, _super_admin);
            admin_count += 1;
        }
        
    }

    // Checking if Wallet ID belongs to an admin
    function isAdmin(address _wallet_address) public view returns (bool){

        if(admins[_wallet_address].wallet_address == address(0)){
            return false;
        }

        else{
            return true;
        }
      
    }

    // Creation of new poll
    function createNewPoll(string memory _poll_name,
                           string memory _state,
                           uint256 _created_date,
                           uint256 _expire_date,
                           address _admin_creator) public {
                               
        if(bytes(polls[_poll_name].poll_name).length == 0){
            polls[_poll_name] =  Polls(_poll_name, _state, 0, _created_date, _expire_date, _admin_creator, 0);
            poll_count += 1;
        }

    }

    // Checking if poll is created
    function isPollCreated(string memory _poll_name) public view returns (bool){

        if(bytes(polls[_poll_name].poll_name).length == 0){
            return false;
        }

        else{
            return true;
        }
        
    }

    // Add Candidate with respective poll id
    function addCandidate(string memory _state_id,
                          string memory _state,
                          string memory _first_name,
                          string memory _last_name,
                          string memory _gender,
                          string memory _poll_name) public{

        if(bytes(candidates[_state_id].state_id).length == 0){
            candidates[_state_id] =  Candidate(_state_id, _state, _first_name, _last_name, _gender, _poll_name, 0);
            polls[_poll_name].candidates += 1;
            candidate_count += 1;
        }
        
    } 

    // Checking if candidate is created
    function isCandidate(string memory _state_id) public view returns (bool){

        if(bytes(candidates[_state_id].state_id).length == 0){
            return false;
        }

        else{
            return true;
        }
        
    }  

    
}