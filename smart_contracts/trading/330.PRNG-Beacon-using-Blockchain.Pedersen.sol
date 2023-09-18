pragma solidity ^0.4.10;
import {ECCMath, Secp256k1} from "./LocalCrypto.sol";


contract Pedersen{

  struct ECPoint {
    uint[2] points;
  }
  struct Info {
      uint[2] pubkey;
      uint comm;
      uint X;
      uint[2] Y;
      uint r;
      uint[] coef;
      uint[2][] genshares;
  }


  mapping(address=> Info) public delegate_info;
  mapping(address=>uint64) public indexes;
  mapping(address=>uint[2])public publickeys;

 address[] public delegates;
 uint64 idx=0;

  // Modulus for public keys
  //uint constant pp = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

  // Base point (generator) G
  uint constant Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint constant Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

  // New point (generator) Y
  //uint constant Yx = 98038005178408974007512590727651089955354106077095278304532603697039577112780;
 // uint constant Yy = 1801119347122147381158502909947365828020117721497557484744596940174906898953;

  // Modulus for private keys (sub-group)
  uint constant nn = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

  uint[2] G;
  //[2] Y;

    address owner;


  function Pedersen() public{
    owner = msg.sender;
    G[0] = Gx;
    G[1] = Gy;
    //Y[0] = Yx;
   // Y[1] = Yy;
  }


   function AddDelegate(address _delegate, uint privatekey) public returns(bool){
      delegates.push(_delegate);
      indexes[_delegate]=idx+1;
      delegate_info[_delegate].pubkey= ECCMath.toZ1(Secp256k1._mul(uint(sha256(privatekey)),G),nn);
      publickeys[_delegate]= delegate_info[_delegate].pubkey;
      return true;
  }


function DelegateInfoAccess(address _delegate) public returns(uint[2] publickeys)
{
 // return (delegate_info[_delegate].pubkey,delegate_info[_delegate].comm,delegate_info[_delegate].X,delegate_info[_delegate].Y,delegate_info[_delegate].r, delegate_info[_delegate].coef,delegate_info[_delegate].genshares);
    return (delegate_info[_delegate].pubkey);

}


  function GenCommit(string seed) public returns (bool){
       for(uint j=0; j < delegates.length; j++){
        delegate_info[delegates[j]].X=uint(sha256(j, seed,delegates[j],block.timestamp));
        delegate_info[delegates[j]].coef[0]=delegate_info[delegates[j]].X;
        delegate_info[delegates[j]].Y=ECCMath.toZ1(Secp256k1._mul(delegate_info[delegates[j]].X,G),nn);
        delegate_info[delegates[j]].r= uint(sha256(j, seed));
        delegate_info[delegates[j]].comm=uint(sha256(delegate_info[delegates[j]].Y,delegate_info[delegates[j]].r));
      }
      return true;
  }


  function DistributeShares(uint _th) public {
      for(uint j=0; j < delegates.length; j++){
          for(uint k=0; k< delegates.length;k++){
              uint res;
              for (uint i=0; i < _th; i++)
              res= addmod(res,mulmod(delegate_info[delegates[j]].coef[i],ECCMath.expmod(k,i,nn),nn),nn);

          }
          delegate_info[delegates[j]].genshares[0][k]=k;
         delegate_info[delegates[j]].genshares[1][k]=res;
      }

  }

  function ChooseCoeff(uint _th) public {
      for(uint j=0; j< delegates.length; j++){
      uint[] memory Coef = new uint[](_th); // test polynomial
    for(uint i=0; i<Coef.length; i++) {
      Coef[i] = addmod(uint(sha256(i, block.blockhash(1))),1,nn); // Picking random elements in Fq
    }
      delegate_info[delegates[j]].coef=Coef;
      }
  }




}
