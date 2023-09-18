// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./BasicVoting.sol";

contract VotingWithOffChainDelegation is BasicVoting {

  function voteAsDelegate(uint proposalId, bool shouldPass, address[] calldata voterAddresses, bytes[] memory signatures) external isVotingOngoing(proposalId) {
    require(voterAddresses.length == signatures.length, "Voters and signature are not the same count!");

    if(!_hasVoted(proposalId, msg.sender)) {
      vote(proposalId, shouldPass);                     
    } else {
      Voter storage voter = voters[_getVoterId(proposalId, msg.sender)];
    
      require(
        voter.votedToPass == shouldPass, 
        "Can not change opinion for delegate voting!"
      );        
    }

    for(uint i = 0; i < voterAddresses.length; i++) {
      _verifyVoterSignature(proposalId, voterAddresses[i], signatures[i]);
    
      _delegate(proposalId, msg.sender, voterAddresses[i]);
    }
  }

  function _verifyVoterSignature(uint proposalId, address voterAddress, bytes memory signature) private view {
    bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, proposalId, this));
    
    bytes32 message = _prefixed(messageHash);

    address signer = _recoverSigner(message, signature);
    
    require(signer == voterAddress, "Voter is not the signer!");
  }

  function _splitSignature(bytes memory sig)
      private
      pure
      returns (uint8 v, bytes32 r, bytes32 s)
  {
      require(sig.length == 65, "Signature must be 65 bytes long!");

      assembly {
          // first 32 bytes, after the length prefix.
          r := mload(add(sig, 32))
          // second 32 bytes.
          s := mload(add(sig, 64))
          // final byte (first byte of the next 32 bytes).
          v := byte(0, mload(add(sig, 96)))
      }

      return (v, r, s);
  }

  function _recoverSigner(bytes32 message, bytes memory sig)
      private
      pure
      returns (address)
  {
      (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sig);

      return ecrecover(message, v, r, s);
  }

  /// builds a prefixed hash to mimic the behavior of eth_sign.
  function _prefixed(bytes32 hash) private pure returns (bytes32) {
      return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}