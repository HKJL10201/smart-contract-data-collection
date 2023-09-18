pragma solidity ^0.5.0;

import "../SnowflakeResolver.sol";
import "../interfaces/IdentityRegistryInterface.sol";
import "../interfaces/HydroInterface.sol";
import "../interfaces/SnowflakeInterface.sol";


contract Voting is SnowflakeResolver {
mapping(uint=>Candidate) public candidates;
mapping(uint=>bool) public aParticipant;
mapping(uint=>bool) public aCandidate;
mapping(uint=>bool) private hasVoted;

struct Candidate{
    uint voteCount;
}


//uint256 candidateFee= 20000000000000000000;//200tokens
uint256 regFee= 40000000000000000000;//40tokens


uint256 burnAmount=500000000000000000000;//500tokens
uint maxNoOfCandidates=2;
address _snowflakeAddress;
uint deadlineInDays;

uint[] candidateEINs;
uint[] voterEINs;

//requires that the ein is a registered candidate
modifier isCandidate(uint ein){
    require(aCandidate[ein]==true,'This EIN has not registered as a candidate');
    _;
}

//requires that the ein has set this contract a resolver
modifier isParticipant(uint _ein){
    require(aParticipant[_ein]==true, 'this EIN has not registered as a participant');
    _;
}

//requires that the entered ein is not a candidate yet
modifier isNotCandidate(uint _ein){
    require(aParticipant[_ein]==true && aCandidate[_ein]==false,"you are a candidate");
    _;
}

//requires that the target does not have a hydroId yet
modifier noIdYet(address target){
    require(checkforReg(target)==false);
    _;
}

modifier HasEIN(address target){
    require(checkforReg(target)==true);
    _;
}

//requires that the deadline hasn't passed
modifier voteStillValid(){
    require (now<=deadlineInDays,"this election has expired");
    _;
}


event voted(uint _candidate);
event becameCandidate(uint _candidateEIN);
event registeredAsVoter(uint voterEin);
event newDeadlineSet(uint _newDeadline);

 constructor (address snowflakeAddress,string memory _name,string memory _description,uint _days)
        SnowflakeResolver(_name, _description, snowflakeAddress, true, false) public
    {
        snowflakeAddress=_snowflakeAddress;
        deadlineInDays=now+_days*1 days;
        
    }
//sets the maximum no of candidates for this resolver
//can only be set by contract owner
function setMaxCandidacy(uint _max) public  voteStillValid() onlyOwner(){
    maxNoOfCandidates=_max;
}
//check if address interacting with contract already has an ein
function checkforReg(address _target) public  returns(bool){
    SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
    IdentityRegistryInterface idRegistry= IdentityRegistryInterface(snowfl.identityRegistryAddress());
    _target=msg.sender;
    bool hasId=idRegistry.hasIdentity(msg.sender);
    return hasId;
}

//basic check to return ein of the specific address
   function checkEIN(address _address) public returns(uint){
        SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
    IdentityRegistryInterface idRegistry= IdentityRegistryInterface(snowfl.identityRegistryAddress());
       uint Ein=idRegistry.getEIN(_address);
       return Ein;
   }
        
 /**   

//implement create Identity function
//might not be needed for now
function createId(address recoveryAddress) public returns(uint ein){
    SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
    IdentityRegistryInterface idRegistry= IdentityRegistryInterface(snowfl.identityRegistryAddress());
    address[] memory _providers = new address [](2);
    address[] memory _resolvers= new address [](1);
    _providers[0]= address(this);
    _providers[1]= _snowflakeAddress;
    _resolvers[0]= address(this);
    
    return idRegistry.createIdentity(recoveryAddress,_providers,_resolvers);
    
    
} 

**/
//called to register any new actor in the system
//makes the ein to be a participant in the system
//this might have to be done from the frontend with the ({from: snowflakeAddress}) tag because of the modifier
function onAddition(uint ein,uint /**allocation**/,bytes memory) public senderIsSnowflake() returns (bool){
    SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
    snowfl.withdrawSnowflakeBalanceFrom(ein, owner(), regFee );
    aParticipant[ein]=true;
     emit registeredAsVoter(ein);
    return true;
   
}

 function onRemoval(uint, bytes memory) public senderIsSnowflake() returns (bool) {}
 
 //anyone who wants to become a candidate
 function becomeCandidate(uint ein) public isParticipant(ein)  voteStillValid() isNotCandidate(ein){
   uint candidateCount= candidateEINs.length;
    require(candidateCount<=maxNoOfCandidates,"candidate limit reached!");
    aCandidate[ein]=true;
    candidateEINs.push(ein);
    emit becameCandidate(ein);
 }
 
 //main vote function
function vote(uint _ein) public  HasEIN(msg.sender) isCandidate(_ein)  voteStillValid() returns(bool){
 SnowflakeInterface snowfl=SnowflakeInterface(snowflakeAddress);
 IdentityRegistryInterface idRegistry= IdentityRegistryInterface(snowfl.identityRegistryAddress());
 uint ein=checkEIN(msg.sender);
 
 require(aParticipant[ein]==true,'you are not a voter,register first');
 require (aCandidate[ein]==false,"you are a candidate");
 require(idRegistry.isResolverFor(ein,address(this)),"This EIN has not set this resolver.");
 require (hasVoted[ein]==false,"you have already voted");
 
 snowfl.withdrawSnowflakeBalanceFrom(ein,owner(), burnAmount);
 candidates[_ein].voteCount++;
 hasVoted[ein]=true;
  emit voted(_ein);
 return (true);


}
//return the current max number of candidates
function getMaxCandidates() public view returns(uint[] memory,uint){
    return(candidateEINs,maxNoOfCandidates);
}



    function withdrawFees(address to) public onlyOwner {
        SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
        HydroInterface hydro = HydroInterface(snowfl.hydroTokenAddress());
        withdrawHydroBalanceTo(to, hydro.balanceOf(address(this)));
    }
    
    function setNewDeadline(uint _newDays) public onlyOwner voteStillValid returns(uint){
        deadlineInDays=now+_newDays*1 days;
        emit newDeadlineSet(deadlineInDays);
        return deadlineInDays;
    }
    
    function getDeadline() public view returns(uint){
        return deadlineInDays;
    }

}
