pragma solidity ^0.6.2;

contract multiSigWallet{
 // Types of consensus: 1. Atleast one  2. Majority  3. All  
  uint constant maxOwners = 3;

  uint consensusType= 1;  
  
  address[] owners;
  mapping(address=> mapping (bytes32 => bool)) approvals;
  event Received(address src, uint amount);
  event Sent(address dst, uint amount);
  event Signed(address dst, uint amount);
  event NewOwner(address owner);
  
  constructor(uint _consensusType) public {
    require(1<= _consensusType && _consensusType <=3);
    owners.push(msg.sender);
    consensusType = _consensusType;
  }
  
  function changeConsensusType(uint _type) public _isOwner{
  require(1<= _type && _type <=3 );
  consensusType= _type;
 }
 
 function addOwner(address _owner) public _isOwner _noDuplicate(_owner){
  require(owners.length < maxOwners);
  owners.push(_owner);
  emit NewOwner(_owner);
 }

  function signSendEthers(address dst, uint amt, bytes memory signature) public  _isOwner _isValidAddress(dst) {
   require(amt <= address(this).balance,"Error: not enough balance");
   bytes32 hash =  keccak256(abi.encodePacked(dst, amt));
   require(verifySign(msg.sender,hash,signature), "Error: Invalid Signature");
   approvals[msg.sender][hash]=true;
   emit Signed(dst,amt);
 }
 
 function send(address payable dst, uint amt) public payable  _isOwner _isValidAddress(dst){
      require(amt <= address(this).balance,"Error: not enough balance");
      bytes32 hash =  keccak256(abi.encodePacked(dst, amt));
      require(isapproved(hash),"Error: Transcation not approved");
      dst.transfer(amt);
      clearSigns(hash);
      emit Sent(dst,amt);
  }


 
 function recieve() external payable {
    emit Received(msg.sender, msg.value);
  }
  
  function getBalance() external view returns (uint) {
   return address(this).balance;
  }
  
  function destroy() public _isOwner{
   selfdestruct(msg.sender);
  }
  
   
 function recoverSigner(bytes32 hash,bytes memory signature) internal pure returns (address)
  {
    bytes32 signm = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    bytes32 r;
    bytes32 s;
    uint8 v;
    require(signature.length == 65);
     assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }  
    
    return ecrecover(signm, v, r, s);
  }
  
  function verifySign(address signee, bytes32 hash, bytes memory signature ) internal pure returns (bool){
        return (recoverSigner(hash,signature) == signee);
  }
  
 
    
 function consensus1(bytes32 hash) internal view returns(bool){
  for(uint i=0; i< owners.length; i++){
   if(approvals[owners[i]][hash]) 
   return true;
  }
 
  return false; 
  }
  
    
 function consensus2(bytes32 hash) internal view returns(bool){
  uint counter = 0;
  uint midWay= (owners.length /2);
  if (!(owners.length %2 == 0 ))
    midWay+=1;
  bool approved= true;
  for(uint i=0; i< owners.length; i++){
    approved=  approvals[owners[i]][hash];
    if(approved)
    {
      counter++;
    }
    if(counter >= midWay){
       return true;
    }
     
  }

  return false; 
  }
  
  
   function consensus3(bytes32 hash) internal view returns(bool){
   bool approved = true;
    for(uint i=0; i< owners.length; i++){
     approved= approvals[owners[i]][hash];
    if(!approved){
      break;
    }
  }
     return approved;
  }
  
  
  
  function clearSigns(bytes32 hash) public {
    for(uint i=0; i< owners.length; i++){
    approvals[owners[i]][hash]= false;
  }
  }
  
  
  function isOwner(address _owner) external view returns (bool) {
    for(uint i=0;i< owners.length;i++){
    if (owners[i] == _owner)
     return true;
  }
    return false;  
  }

  function getConsensus() external view returns (uint) {
    return consensusType;
  }
  
  function isapproved(bytes32 hash) internal view returns (bool) {
  bool appr;
  if (consensusType == 1)
    appr= consensus1(hash);
  else if (consensusType == 2)
    appr = consensus2(hash);
  else if (consensusType == 3)
    appr = consensus3(hash);
    return appr;
  }
  
  function isapprovedByOwner(address _owner,address dst, uint amt ) external view returns (bool){
  bool appr;
    for(uint i=0;i< owners.length;i++){
     appr = (owners[i] == _owner);
     if(appr)
      break;
  }
    require(appr,"Error: not owner");
    bytes32 hash =keccak256(abi.encodePacked(dst, amt));
    return approvals[_owner][hash];
  }
  

  modifier _isOwner{
  bool appr;
  for(uint i=0;i< owners.length;i++){
    appr = (owners[i] == msg.sender);
    if(appr)
    break;
  }
  require(appr,"Error: not owner");
   _;
  }
  
  modifier _isValidAddress(address _dst){
    require(_dst != address(0),"Error: Null address");
    _;
  }
  modifier _noDuplicate(address _owner){
  for(uint i=0;i< owners.length;i++){
   require(!(owners[i] == _owner),"Error: Owner already exists");
  }
   _;
  }
  
  function sendBack() public {
    msg.sender.transfer(address(this).balance);
  }
  
}