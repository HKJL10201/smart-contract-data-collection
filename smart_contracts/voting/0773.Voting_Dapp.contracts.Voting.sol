pragma solidity ^0.5.0;

contract Voting{
    address admin;
    address[] miners;
    uint votingTime;
    address winner;
    // Candidtate Details for Registration
    struct voter{
       string name; 
       address voterAddr;
       uint dob;
       uint cnic;
       string education;
       string district;
       string UC;
       bool voteStatus;    
    }
    // Candidate Details 
     struct  candidate {
        string name;
        uint cnic;
        string education;
        string district;
        string UC;
        // address voterAddr;
        // bool registeredStatus;
        address candidateAddr;
        // string addrFrom;
        // string employment;
        // string uinionName;
        uint dob;
        uint voteReceived;
        
    }

    mapping(address => voter) Voters; // storeing the struct of voters 
    address[] votersArr;
    mapping(address => candidate) Candidates; // Storing the struct of Candidates
     address[] candidatesArr;
    // constructor of the contract
   constructor()public {
        admin = msg.sender; // The Contract Deployer is Assign as Administrator
        votingTime = now;
    }
    event CheckingFucnctionEvent(string messag);
    event eventCalled(string name, string messag);
    event eventCalledAddrssed(string mes,address y);
    event checkAdmin(address addm,address sen);
    //OnlyAdmin modifier
    modifier onlyAdmin(){
        require(msg.sender ==admin);
        _;
    }
    
       // Check Voters are aleady Registerd or not
    function checkVotersRegistered()public view returns(bool){
        uint i;
        for(i = 0 ; i < votersArr.length ; i++){
            if(votersArr[i]== msg.sender)
            {
                return true;
            }
        }
        return false;
    }
       
    // Voter Registrations
    function voterRegistration(string memory _name, uint  _dob ,uint _cnic, string memory _disrict, string memory _uc, string memory _education) public returns(bool) {
        
        // require(!checkVotersRegistered(), " This Voter is Aleady Registerd Thanks\n");
        if(!checkVotersRegistered())
        {
            return false;
        }
     voter storage voters= Voters[msg.sender];
     voters.name = _name;
     voters.dob = _dob;
     voters.cnic = _cnic;
     voters.education = _education;
     voters.district = _disrict;
     voters.UC = _uc;
     voters.voterAddr = msg.sender;
     voters.voteStatus = false;
     votersArr.push(msg.sender);
     return true;
    }
    // Registered Voter Vote To Candidate
    
    function voteForCandidate(address _voteTo)  public{
        
     require(checkVotersRegistered()," Sorry!\n\n You are not Registered Voters \n\n ");
     require(Voters[msg.sender].voteStatus == false, " You Already Voted");
     Candidates[_voteTo].voteReceived +=1;
     Voters[msg.sender].voteStatus = true;
        
    }
    //Candidate Reigistation
    function candidateRegistration(string memory _name, string memory _education, uint _cnic , uint _dob, string memory _district ,string memory _uc)
    public returns(bool){
        
        // require(!checkIsRegistered() , " You alerady Registered Thanks\n\n");
        if(!checkIsRegistered()){
            return false;
        }
        candidate storage candi = Candidates[msg.sender];
        candi.name = _name;
        candi.education = _education;
        // candi.addrFrom = _addrOfCnic;
        candi.voteReceived = 0;
        candi.dob = _dob;
        candi.candidateAddr = msg.sender;
        candi.cnic =_cnic;
        candi.district = _district;
        candi.UC = _uc;
        Candidates[msg.sender]=candi;
        candidatesArr.push(msg.sender);
        return true;
    }
    
    
   
    // Reveal Winner
    function winners()  public view returns(address){
        uint i;
      
     if(msg.sender == admin){ // For Instant Admin Only Show the Winner
        uint highest ;//= Candidates[candidatesArr[0]].voteReceived;
         address winAddress;// =Candidates[candidatesArr[0]].candidateAddr;
         for(i = 0 ; i < candidatesArr.length - 1; i++)
         {
             if(Candidates[candidatesArr[i]].voteReceived <= Candidates[candidatesArr[i++]].voteReceived)
             {
                 highest= Candidates[candidatesArr[i++]].voteReceived;
                 winAddress = Candidates[candidatesArr[i++]].candidateAddr;
             }
             else{
                 highest=Candidates[candidatesArr[i]].voteReceived;
                winAddress = Candidates[candidatesArr[i]].candidateAddr;

             }
         }
         return winAddress;
     }
     else{ // The User only See the Winner after the voting time is end.
         require(now > votingTime + 86400," Voting is Continued");
         uint highest = Candidates[candidatesArr[0]].voteReceived;
         address winAddress = Candidates[candidatesArr[0]].candidateAddr;
         for(i = 0 ; i < candidatesArr.length - 1; i++)
         {
             if(Candidates[candidatesArr[i]].voteReceived <= Candidates[candidatesArr[i++]].voteReceived)
             {
                 highest= Candidates[candidatesArr[i++]].voteReceived;
                 winAddress = Candidates[candidatesArr[i++]].candidateAddr;
             }
             else{
                 highest=Candidates[candidatesArr[i]].voteReceived;
                winAddress = Candidates[candidatesArr[i]].candidateAddr;

             }
         }
         
         return winAddress;
     }
    }
    
    // Contract Destruction if any Error found this only done by Admin
    function selfDestruction() public  onlyAdmin {

        selfdestruct(msg.sender);
       // return "Your Contract is Destroyed";
    }
    
    
    
     // Check Candidate are alerady Registered or not
    function checkIsRegistered() public view returns(bool)
    {

        for(  uint i = 0 ; i < candidatesArr.length ; i++)
        {
            if(candidatesArr.length ==0)   {     return false;  }
            
            if(candidatesArr[i] == msg.sender) {  return true;  }
         }
        return false;
    }
    
    // Return All Registend address
    function retAllAddresses()public view  returns(address){
        
        for(uint i=0; i<candidatesArr.length; i++){
           return Candidates[candidatesArr[i]].candidateAddr;
        //return(candidatesArr[i].voteReceived  , Candidates[candidatesArr[i]].candidateAddr);
        }
    }
    
    // Check voteReceived By The candidateAddr
    function voteReceviedToMe()public view returns(uint){
        require(checkIsRegistered(),"You are not registered Candidate");
        return Candidates[msg.sender].voteReceived;
    }
    // function for total Voters registered
    function totalVotersRegistered()public view returns(uint){
        return votersArr.length;
    }


    
}