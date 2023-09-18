pragma solidity 0.8.0;

contract Verify{
    
    function getMessage(address to, uint256 amount, string memory message, uint256 nonce) public pure returns(bytes32){
      
         return keccak256(abi.encode(to, amount, message, nonce
              ));   
    }
    
    function getEthSignedMessgae(bytes32 _message) public pure returns(bytes32){
        
        return keccak256(abi.encode("X19Ethereum Signed Message:\n32", _message
            ));
    }
    
    function _Verify(address _signer, address to, uint256 amount, string memory message, uint256 nonce,  bytes32 _signature ) external pure returns(bool){
        
               bytes32 _Message = getMessage(to, amount, message, nonce);
               bytes32 _eth_s_Message = getEthSignedMessgae(_Message);
               
               if ( Recoversigner(_eth_s_Message, _signature) == _signer){
                   return true;
                   
               }
    }
    
     function Recoversigner(bytes32 eth_s_Message, bytes32 _sig) public pure returns(address){
         
            (bytes32 r, bytes32 s, uint8 v) = split(_sig);
            
            return ecrecover(eth_s_Message, v, r, s);
         
     }
     
     function split (bytes32 sign) public pure returns(bytes32 r, bytes32 s, uint8 v){
         
         require(sign.length == 65, "invalid signature");
         
         assembly{
             
              r := mload(add(sign, 32))
              s := mload(add(sign, 64))
              v := byte(0, mload(add(sign, 96)))
         }
         
         
     }
}


//// web3.eth.personal.sign(hash, web3.eth.defaultAccount, console.log)
