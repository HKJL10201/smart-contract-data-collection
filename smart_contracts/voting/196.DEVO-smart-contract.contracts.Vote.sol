pragma solidity 0.8.10;

//  [x]  register voters
//  [x]  get their votes
//  [x]  ensure that they can't vote more than once
//  [x]  ensure that the votes of the apirants are well appended


contract Vote {

    //  address of the owner / admin/ deployer

    address public owner;
    
    //  a map to store the number of votes submitted to each candidates
    mapping(address => uint256) public voteCount;


    //  map to store candidates' registration state as true or false
    mapping(address => bool)  registeredCandidates;

    //   a struct to save the candidates registration data
    struct CandidateRegistration {
        string name;
        string ipfsHash;
        address candidateAddress;
    }

    //  that saves the candidate data to their address
    mapping(address => CandidateRegistration) public registeredCandidatesData;





    //  a struct to save the voter's details on registration
    struct ElectorateRegistration {

        string FirstName;
        string LastName;
        string MiddleName;
        string stateOfOrigin;
        string NIN;
        address registrantAddress;
        uint256 timestamp;

    }

    //  an array of registered electorates addresses
    address[] public registeredElectoratesAddresses; 


    //  an array of registered candidates data
    CandidateRegistration[] public registeredCandidatesArray;

    //  mapping the registered user's details to their address
    mapping(address => ElectorateRegistration) public electorates;


    //  mapping marks addresses as registered
    mapping(address => bool) public registered;

    //  mapping that validates an electorates' vote 
    mapping(address => bool) public validateVote;


     /////   Events
    //  1. Registered event
    //  2. Vote event

    event ElectorateRegistered(string _firstname, string _lastName, address _address, uint256 _timestamp);
    event VoteCandidate(address _candidate, address _electorate, uint256 _timestamp);
    event CandidateRegistered(address _candidate, string _name, string _ipfsHash);


     constructor () {

        owner = msg.sender;
    }

    // declare a modifier that makes some functions to be exclusive to just the owner of the contract

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }




    function registerVoter(string memory _firstname, string memory _lastname, string memory _middlename, string memory _stateOfOrigin, string memory _nin) public returns(bool success) {

        //  check if the address has been registered
        require(!registered[msg.sender]);

        //  if not registered, append the address to the array of registered users
        registered[msg.sender] = true;
        registeredElectoratesAddresses.push(msg.sender);  

        //  saving their registration details
        electorates[msg.sender] = ElectorateRegistration(_firstname, _lastname, _middlename, _stateOfOrigin, _nin, msg.sender, block.timestamp);

        //  emit registration event
        emit ElectorateRegistered( _firstname, _lastname , msg.sender, block.timestamp);

        return true;
  
    }

    function voteCandidate(address _candidate) public returns(bool success) {

        //  validate that this address is eligible for voting through registration
        require(electorates[msg.sender].registrantAddress == msg.sender);

        //  validate that this address hasn't voted
        require(!validateVote[msg.sender]);


        // validate that this candidate's address is not invalid and it is registered
        require(_candidate != address(0));
        require(registeredCandidates[_candidate]);
        voteCount[_candidate] += 1;

        //  ensures that this address can't vote again
        validateVote[msg.sender] = true;

        //  emit event
        emit VoteCandidate(_candidate, msg.sender, block.timestamp);

        return true;
    }

    function noOfRegisteredVoters() public view returns (uint256) {
        return registeredElectoratesAddresses.length;
    }


    function registerCandidates(address _candidate, string memory _name , string memory _ipfsHash ) public onlyOwner {

        // candidates can only be registered via the contract owner

        require(_candidate != address(0));
        require(!registeredCandidates[_candidate]);

        registeredCandidatesData[_candidate] = CandidateRegistration(_name, _ipfsHash, _candidate);

        registeredCandidatesArray.push(registeredCandidatesData[_candidate]);

        registeredCandidates[_candidate] = true;

        emit CandidateRegistered(_candidate, _name, _ipfsHash);
        
    }

    function getAllCandidates() public view returns (CandidateRegistration[] memory) {
        return registeredCandidatesArray;
    }

   

 
    
}