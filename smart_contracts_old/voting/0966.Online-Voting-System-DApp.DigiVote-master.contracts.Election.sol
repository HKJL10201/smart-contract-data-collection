pragma solidity ^0.5.0;

contract Election{

    //-------------------------Credentails Area--------------------------------------

    //Organizer mapping of Credentials and Personal Information, mapping of (Username => hash)
    mapping (string => string) OrganizerCredentials;
    mapping (string => string) OrganizerPersonal;
    string[] OrganizerUsername;

    //Candidate mapping of Credentials and Personal Information, mapping of (Username => hash)
    mapping (string => string) CandidateCredentials;
    mapping (string => string) CandidatePersonal;
    string[] CandidateUsername;

    //------------------------Organizer's  Elections Area------------------------------

    //struct for contain number of Elections in place
    struct ElectionHash{
        string hash;
    } 

    //mapping (OrganizerAddress => allElectionsOfOrganizer)
    mapping (address => ElectionHash[]) OrganizerElections;
    string[] public Elections;

    //------------------------ Candidate's Nomination Requests -----------------------------

    //mapping for candidate request for particular election
    struct RequestHash{
        string username;
        string electionHash;
        string time;
        string place;
        string status;
    }

    //mapping (Candidateusername => RequestHash)
    mapping (string => RequestHash[]) CandidateRequests;
    
    //Array of Request struct
    RequestHash[] public ElectionRequests;

    //------------------------ Election's Candidate Area -------------------------------

    struct CandidateOfElection{
        string username;
        uint votes;
        string place;
    }

    //mapping of (electionHash => allCandidatesOfElection)
    mapping (string => CandidateOfElection[]) SelectedCandidates;

    //--------------------------- Voter's Area --------------------------------------

    struct Voter{
        string voter;
    }

    struct VoterCredentails{
        address accAddress;
        string password;
    }

    //mapping of (electionHash => VoterHash)
    mapping (string => Voter[]) ElectionVoterPool;

    //mapping for (VoterHash => VoterCredentials)
    mapping (string => VoterCredentails) VotersAccount;

    //--------------------------- Aadhaar Area -------------------------------------

    struct AadhaarCard{
        uint aadhaar;
    }

    //mapping for (electionHash => aadhaarCard[]) for verifying the adhaar is voted only once for 
    mapping (string => AadhaarCard[]) AadhaarCheck;

    //-------------------- Functions Area ------------------------------------------





    //********************************** function for Organizers *******************

    function setOrganizerCredentials(string memory _username, string memory _hash) public {
        OrganizerCredentials[_username] = _hash;
        OrganizerUsername.push(_username);
    }

    function setOrganizerPersonal(string memory _username, string memory _hash) public {
        OrganizerPersonal[_username] = _hash;
    }

    function getOrganizerCredentials(string memory _username) public view returns(string memory){
        return OrganizerCredentials[_username];
    }

    function getOrganizerPersonal(string memory _username) public view returns(string memory){
        return OrganizerPersonal[_username];
    }

    function getOrganizersCount() public view returns(uint){
        return OrganizerUsername.length;
    }

    function findOrganizer(string memory _username) public view returns(bool){
        for(uint i = 0; i <= OrganizerUsername.length - 1; i++){
            if(keccak256(abi.encodePacked(OrganizerUsername[i])) == keccak256(abi.encodePacked(_username)))   return true;
        }
        return false;
    }

    //*********************************** function for Elections ***************************************
    
    function addElection(address _add, string memory _hash) public returns(bool){
        for(uint i = 0; i < OrganizerElections[_add].length ; i++){
            if(keccak256(abi.encodePacked(_hash)) == keccak256(abi.encodePacked(OrganizerElections[_add][i].hash))) return false;
        }
        OrganizerElections[_add].push(ElectionHash(_hash));
        Elections.push(_hash);
        return true;
    }
    
    function getElection(address _add, uint _index) public view returns(string memory){
        return OrganizerElections[_add][_index].hash;
    }

    function organizerElectionCount(address _add) public view returns(uint){
        return OrganizerElections[_add].length;
    } 

    function getElections(uint _index) public view returns(string memory){
        return Elections[_index];
    }

    function electionsCount() public view returns(uint){
        return Elections.length;
    } 

    //******************************* functions for Candidates **************************

    function setCandidateCredentials(string memory _username, string memory _hash) public {
        CandidateCredentials[_username] = _hash;
        CandidateUsername.push(_username);
    }

    function setCandidatePersonal(string memory _username, string memory _hash) public {
        CandidatePersonal[_username] = _hash;
    }

    function getCandidateCredentials(string memory _username) public view returns(string memory){
        return CandidateCredentials[_username];
    }

    function getCandidatePersonal(string memory _username) public view returns(string memory){
        return CandidatePersonal[_username];
    }

    function getCandidatesCount() public view returns(uint){
        return CandidateUsername.length;
    }

    function findCandidate(string memory _username) public view returns(bool){
        for(uint i = 0; i <= CandidateUsername.length; i++){
            if(keccak256(abi.encodePacked(CandidateUsername[i])) == keccak256(abi.encodePacked(_username))) return true;
        }
        return false;
    }

    //********************************************* function for Election Requests *************************

    function setRequest(string memory _username, string memory _electionHash, string memory _time, string memory _place, string memory _status) public {
        CandidateRequests[_username].push(RequestHash(_username, _electionHash, _time, _place, _status));
        ElectionRequests.push(RequestHash(_username, _electionHash, _time, _place, _status));
    }

    function getRequest(string memory _username, uint _index) public view returns(string memory, string memory, string memory, string memory, string memory){
        return (
                    CandidateRequests[_username][_index].username, 
                    CandidateRequests[_username][_index].electionHash, 
                    CandidateRequests[_username][_index].time, 
                    CandidateRequests[_username][_index].place, 
                    CandidateRequests[_username][_index].status
                );
    }

    function candidateRequestsCount(string memory _username) public view returns(uint){
        return CandidateRequests[_username].length;
    }

    function getAllRequest(uint _index) public view returns(string memory, string memory, string memory, string memory, string memory){
        return (
                    ElectionRequests[_index].username, 
                    ElectionRequests[_index].electionHash, 
                    ElectionRequests[_index].time, 
                    ElectionRequests[_index].place, 
                    ElectionRequests[_index].status
                );
    }

    function requestsCount() public view returns(uint){
        return ElectionRequests.length;
    } 

    function updateRequestStatus(uint _allRequestIndex, uint _candidateRequestIndex, string memory _username, string memory _status) public {
        ElectionRequests[_allRequestIndex].status = _status;
        CandidateRequests[_username][_candidateRequestIndex].status = _status;
    }

    //**************************** function for selected Candidate of Election ***********************

    function addCandidate(string memory _electionHash, string memory _username, string memory _place) public {
        SelectedCandidates[_electionHash].push(CandidateOfElection(_username, 0, _place));
    }

    function countElectionCandidates(string memory _electionHash) public view returns(uint){
       return SelectedCandidates[_electionHash].length;
    }

    function getSelectedCandidates(string memory _electionHash, uint _index) public view returns(string memory, uint, string memory){
       return (SelectedCandidates[_electionHash][_index].username, SelectedCandidates[_electionHash][_index].votes, SelectedCandidates[_electionHash][_index].place);
    }

    //*************************** function for voting for the candidate of election ************************
    

    function vote(string memory _electionHash, uint _index) internal {
        SelectedCandidates[_electionHash][_index].votes += 1;
    }

    function voteSelectedCandidates(string memory _electionHash, string memory _username, uint _index) public {
        
        require(keccak256(abi.encodePacked(SelectedCandidates[_electionHash][_index].username)) == keccak256(abi.encodePacked(_username)));
        vote(_electionHash, _index);
    } 

    //*************************** functions for checking the Aadhaar Card voted or not **********************

    //fucntion for finding the total number of voted aadhaar card
    function aadhaarCount(string memory _electionHash) public view returns(uint){
        return AadhaarCheck[_electionHash].length;
    }

    //function for find the aadhaar card for chechking that wheather it is voted or not
    function checkAadhaar(string memory _electionHash, uint _index) public view returns(uint){
        return AadhaarCheck[_electionHash][_index].aadhaar;
    }

    //function for adding the Aadhaar card to the Election Poll
    function addAadhaar(string memory _electionHash, uint _aadhaar)public {
        AadhaarCheck[_electionHash].push(AadhaarCard(_aadhaar));
    }

    //***************************** Functions for Voter ***********************************************

    //function for adding the voter credentails with its Object Hash
    function addVoterAccount(string memory _voterHash, address _add, string memory _password)public {
        VotersAccount[_voterHash] = VoterCredentails(_add, _password);
    }

    //function for get the Account details of the voter
    function getVoterAccount(string memory _voterHash)public view returns(address, string memory){
        return (VotersAccount[_voterHash].accAddress, VotersAccount[_voterHash].password);
    }

    //function for inserting the Voter credentials into thier respective elections
    function addVoterToElection(string memory _electionHash, string memory _voterHash)public {
        ElectionVoterPool[_electionHash].push(Voter(_voterHash));
    }

    //function for get the voters associated with election
    function getVoterToElection(string memory _electionHash, uint _index)public view returns(string memory){
        return ElectionVoterPool[_electionHash][_index].voter;
    }
}