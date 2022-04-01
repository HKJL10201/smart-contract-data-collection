pragma solidity ^0.5.0;

contract Election1{
    
    struct Organizer{
        string username;
        string organization;
        uint contact;
        //uint numberOfElelction;
    }
    
    struct Candidate{
        string Name;
        string Address;
        uint Age;
        uint Contact;
        //uint numberOfElelction;
    }
    
    struct Elections{
        string typeOfElection;
        string constituency;
        string organizer;
        string electionDate;
        string resultDate;
        uint ICRD;
        uint FCRD;
        uint voters;
        uint candidates;
    }
    
    //maaping of organizer and candidates with thier addresses
    mapping (address => Organizer) public Organizers;
    mapping (address => Candidate) public Candidates;
    mapping (address => Elections) public ElelctionsCollection;
    address[] public OrganizersArray;
    address[] public CandidatesArray;
    uint public count;


    
    // //function for registering the Organizer
    // function addOrganizer(string memory _name, string memory _org, uint _contact) public {
    //     Organizers[msg.sender].name = _name;
    //     Organizers[msg.sender].organization = _org;
    //     Organizers[msg.sender].contact = _contact;
        
    //     OrganizersArray.push(msg.sender);
    // }

    // function addCount(uint _num) public{
    //     count = _num;
    // }

    // function countUp() public view returns(uint){
    //     return count;
    // }

    // function seeThrough(address _addr) public view returns(address){
    //     return _addr;
    // }
    
    //  //function for registering the Candidate
    // function newCandidate(string memory _name, string memory _address, uint _age, uint _contact) public {
    //     Candidates[msg.sender].Name = _name;
    //     Candidates[msg.sender].Address = _address;
    //     Candidates[msg.sender].Age = _age;
    //     Candidates[msg.sender].Contact = _contact;
        
    //     CandidatesArray.push(msg.sender);
    // }
    
    // //function for get the data of organizer from its address
    // function getOrganizer(address _add) public view returns(string memory, string memory, uint){
    //     return(Organizers[_add].name, Organizers[_add].organization, Organizers[_add].contact );
    // }
    
    // //function for get the data of candidate from its address
    // function getCandidate(address _add) public view returns(string memory, string memory, uint, uint){
    //     return(Candidates[_add].Name, Candidates[_add].Address, Candidates[_add].Age, Candidates[_add].Contact);
    // }
    
    // //function for counting the number of candidates
    // function candidateCount() public view returns(uint){
    //     return CandidatesArray.length;
    // }
    
    // //function for counting the number of candidates
    // function organizerCount() public view returns(uint){
    //     return OrganizersArray.length;
    // }
    
    // //function modifier for only organizer can call the election function
    // modifier onlyOrganizer{
        
    //     for(uint i=0;i<=OrganizersArray.length-1;i++){
    //        require(msg.sender == OrganizersArray[i]);
    //        _;
    //     }
       
    // }
    
    // //function for creating election
    // function createElection(string memory _ToE, string memory _constitunecy, string memory _Org, string memory _ED, string memory _RD,uint _ICRD, uint _FCRD, uint _voters, uint _candidates) public {
    //     ElelctionsCollection[msg.sender].typeOfElection = _ToE;
    //     ElelctionsCollection[msg.sender].constituency = _constitunecy;
    //     ElelctionsCollection[msg.sender].organizer = _Org;
    //     ElelctionsCollection[msg.sender].electionDate = _ED;
    //     ElelctionsCollection[msg.sender].resultDate = _RD;
    //     ElelctionsCollection[msg.sender].ICRD = _ICRD;
    //     ElelctionsCollection[msg.sender].FCRD = _FCRD;
    //     ElelctionsCollection[msg.sender].voters = _voters;
    //     ElelctionsCollection[msg.sender].candidates = _candidates;
    // }
    
    // //function for get the election data according to the organizer's Address
    // function getElelction(address _add) public view returns(string memory, string memory, string memory, string memory, string memory, uint, uint, uint, uint){
    //     return(ElelctionsCollection[_add].typeOfElection, ElelctionsCollection[_add].constituency, ElelctionsCollection[_add].organizer, ElelctionsCollection[_add].electionDate, ElelctionsCollection[_add].resultDate, ElelctionsCollection[_add].ICRD, ElelctionsCollection[_add].FCRD, ElelctionsCollection[_add].voters, ElelctionsCollection[_add].candidates);
    // }
    
    
    
}