pragma solidity ^0.4.10;
import {ECCMath, Secp256k1} from "./LocalCrypto.sol";


contract RNG{

    enum State { SETUP, COMMITMENT, OPENING, DISTRIBUTION, VALIDATION, RECONSTRUCTION, FINISHED, FAILED }
  State public state;

  struct ECPoint {
    uint[2] points;
  }
  struct Info {
      uint comm;
      uint[2] y;
      uint256 r;
      uint[2][] comcoef;
      uint[2][] shares;
      uint xvalue;
  }


  mapping(address=> Info) public delegate_info;
  mapping(address=>uint64) public indexes;
  mapping(address=>uint[2])public publickeys;
  mapping(address => bytes32) public DState;

  uint[] public x;
  uint blockhash;
  uint public beacon;
  uint count=0;
  uint Threshold;
  uint firstcome;
  uint e;
 address[] public delegates;
 uint64 idx=0;
 uint constant RoundTime= 2;

uint[] points;
uint[]  pos;

  // Modulus for public keys
  //uint constant pp = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

  // Base point (generator) G
  uint constant Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint constant Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

  // New point (generator) Y
  //uint constant Yx = 98038005178408974007512590727651089955354106077095278304532603697039577112780;
  //uint constant Yy = 1801119347122147381158502909947365828020117721497557484744596940174906898953;

  // Modulus for private keys (sub-group)
  uint constant nn = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

  uint[2] G;
  //uint[2] Y;

  uint64 NumberOfDelegates;

address owner; // i.e. the Random Contract



  modifier onlyOwner {
      require(msg.sender == owner);
      _;
  }

    // Setup is already complete. Creator of this contract must already have a public key.
  function RNG(uint64 _number,uint _th) public{
    owner = msg.sender;
    Threshold=_th;
    NumberOfDelegates=_number; //Maximum number of participants

    // Make sure his public key is valid!
    state = State.SETUP;
    G[0] = Gx;
    G[1] = Gy;
    //Y[0] = Yx;
    //Y[1] = Yy;
  }

  function delegateInfoAccess(address _delegate) public returns (uint, uint[2],uint256,uint[2][],uint[2][],uint)
  {
      return (delegate_info[_delegate].comm,
      delegate_info[_delegate].y,
      delegate_info[_delegate].r,
      delegate_info[_delegate].comcoef,
      delegate_info[_delegate].shares,
      delegate_info[_delegate].xvalue);
  }

  function AddDelegate(address _delegate, uint[2] _pk) onlyOwner public returns(bool){
      require(delegates.length < NumberOfDelegates);
      delegates.push(_delegate);
      indexes[_delegate]=idx+1;
      if(!Secp256k1.isPubKey(_pk)) {
        return false;
      }
      else{
      publickeys[_delegate]=_pk;
      return true;
      }
  }

  function RemoveDelegate(address _delegate) onlyOwner public returns (bool){
      delete delegates[indexes[_delegate]];
      delete publickeys[_delegate];
      return true;
  }

  function ModifyDelegate(address _olddelegate, address _newdelegate, uint[2] _pk) onlyOwner public returns (bool){
      if(!Secp256k1.isPubKey(_pk)) {
        return false;
      }
      else{
      delegates[indexes[_olddelegate]]=_newdelegate;
      publickeys[_olddelegate]=_pk;
      return true;
      }
  }

  function SetupFinished(bool _flag) onlyOwner public returns(bool){
      state=State.COMMITMENT;
      return _flag;
  }


 function Commitment(uint _comm) public returns (bool){
     if(state==State.COMMITMENT)
     {
     delegate_info[msg.sender].comm=_comm;
     if (firstcome==0)
     {
        uint256 T=Time_call();
        firstcome=1;
     }

     DState[msg.sender]='Committed';
     if (Time_call()-T >= RoundTime){
         state=State.OPENING;
         firstcome=0;
     }

     return true;
     }
     else{
         return false;
     }
 }


 function OpeningCom(uint[2] _y, uint256 _r) public returns (bool){
     if(state==State.OPENING){
     uint h=uint(sha256(_y,_r));
     if (h==delegate_info[msg.sender].comm){
      delegate_info[msg.sender].y=_y;
      delegate_info[msg.sender].r=_r;
     if (firstcome==0)
     {
        uint256 T=Time_call();
        firstcome=1;
     }

     DState[msg.sender]='Opened';
     }
     if (Time_call()-T >= RoundTime){
         blockhash=uint(block.blockhash(block.number));
         state=State.DISTRIBUTION;
         firstcome=0;
     }

     return true;
     }
     else{
         return false;
     }
 }


 function Distribution(uint[2][] _commcoef) public returns (bool){
     if(state==State.DISTRIBUTION){
         delegate_info[msg.sender].comcoef=_commcoef;
     if (firstcome==0)
     {
        uint256 T=Time_call();
        firstcome=1;
     }

     DState[msg.sender]='DistributedShare';
     if (Time_call()-T >= RoundTime){
         state=State.VALIDATION;
         firstcome=0;
     }

     return true;
     }
     else{
         return false;
     }
 }

 function Validation(uint _share, address _Mal) public returns (bool){
     if(state==State.VALIDATION){
         uint[3] memory res;

     if (firstcome==0)
     {
        uint256 T=Time_call();
        firstcome=1;
     }
     if(_share==0){
         DState[msg.sender]='Validated';
     }
     else{
         for(uint i=0; i<=Threshold-1; i++){
         res=Secp256k1._add(res,Secp256k1._mul(i,delegate_info[_Mal].comcoef[i]));
         }
         uint[3] memory gs= Secp256k1._mul(_share,G);
         if(res[0] != gs[0] && res[1] != gs[1] && res[2] != gs[2]){
         DState[_Mal]='Cheating';
         }
         else{
             DState[msg.sender]='Cheating';
         }
     }

     if (Time_call()-T >= RoundTime){
         state=State.RECONSTRUCTION;
         firstcome=0;
     }

     return true;
     }
     else{
         return false;
     }
 }


  function ReceiveShares(uint[2][] _share) public returns (bool){
     if(state==State.RECONSTRUCTION){
     count=count+1;
     delegate_info[msg.sender].shares=_share;
     if (firstcome==0)
     {
        uint256 T=Time_call();
        firstcome=1;
     }

     if (Time_call()-T >= RoundTime){
         for(uint j=0; j < delegates.length; j++){
         Reconstruction(j);
         }
         uint sumx;
         for(uint kk=0; kk< delegates.length; kk++){
           sumx=addmod(sumx,x[kk],nn);
         }
         beacon=uint(sha256(blockhash,sumx));
         state=State.FINISHED;
         firstcome=0;
     }

     return true;
     }
     else{
         return false;
     }
 }

 function Reconstruction(uint _j)  internal {
   if(count< Threshold || state != State.RECONSTRUCTION) {
      return;
    }
    //uint[] memory points = new uint[](Threshold);
     // uint[] memory pos = new uint[](Threshold);
      uint accum;

    (points,pos)=Findshares(_j);
    // Outter loop is a sigma, inner loop is a product
    for(uint formula = 0; formula < points.length; formula++) {

      uint numerator = 1;
      uint denominator = 1;

      // Product... x_{m} is the share's position (i.e. first/second/third point).
      for(uint countt=0; countt<points.length; countt++) {

        if(formula != countt) {
          uint startpos = pos[formula];
          uint nextpos = pos[countt];

          // x_{m}, where m is inner loop
          numerator = mulmod(numerator,nextpos,nn);
          // x_{m} - x_{j}, where j is outter loop
          denominator = mulmod(denominator,((startpos-nextpos)%nn),nn);
        }
      }
 // Numerator / Denominator i.e. x_{m} / x_{m} - x_{j}
      uint ndd = mulmod(numerator,ECCMath.invmod(denominator, nn),nn);

      // val * (numerator / denominator) i.e. f(x_{j}) * (x_{m} / x_{m} - x_{j})

        // Accumlate all values so far
        accum = addmod(accum,ndd,nn);
    }
    x[_j] = accum;
    delegate_info[delegates[_j]].xvalue=accum;

 }


function Findshares(uint jj) internal returns(uint[], uint[]){
       uint found = 0;

       // Lets find out which shares made it!
           for(uint i=0; i<delegates.length; i++) {
            if(delegate_info[delegates[i]].shares[1][jj]!=0){
               points[found] = delegate_info[delegates[i]].shares[1][jj];
               pos[found] = delegate_info[delegates[i]].shares[0][jj];
               found = found + 1;
               }
      // We do not need more points than our threshold!
      if(found == Threshold) {
        break;
      }
      // Did we find less than 't' valid decryptions (i.e. voted as valid)?
    if(found < Threshold) { return;  }
    }
    return(points,pos);
}

 function getDelegateState(address _delegate) returns (bytes32) {
    return(DState[_delegate]);
  }

 function Time_call() internal returns (uint256){
        return block.number;
    }



}
