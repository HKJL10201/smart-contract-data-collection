pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "../Constants.sol";
import "./ITagsRepository.sol";
import "./IERC20.sol";
import "./IDuster.sol";
import "../IConstantsRepository.sol";
import "./ClaimerEvents.sol";

/// @title Base contract to be used to represent all ERC20 PoB tokens
contract Claimer is ClaimerEvents {

   struct Commit {
      bytes32 proofHash;
      uint block;
   }

   // Set of reveals: (burnTxHash -> is revealed)
   // with burnTxHash = H(raw burn transaction)
   // The idea is to keep track of all the burn transactions that were already claimed
   mapping (bytes32 => bool) private reveals;

   // Set of commits: (commitHash -> burn proof hash and block number)
   // with commitHash = H(prover address | H(raw burn transaction))
   // The idea is to keep track of all committed proofs given a prover and a burn transaction
   mapping (bytes32 => Commit) private commits;

   /// @param proofHash H(proof)
   //  with proof = abi.encode(
   //                chainId,
   //                claimAddress,
   //                fee,
   //                txRoot,
   //                mmrRoot,
   //                autoExchange,
   //                rawTransaction,
   //                transactionProofOfInclusion,
   //                mmrProof
   //              )
   /// @param burnTxHash H(rawTransaction)
   //  with rawTransaction = PoB transaction sent to the source Blockchain
   function commitToBurnProof(bytes32 proofHash, bytes32 burnTxHash) public {
      bytes32 commitHash = getCommitHash(burnTxHash, msg.sender);

      require(reveals[burnTxHash] == false, "Burn transaction already claimed");
      require(commits[commitHash].block == 0, "Proof already committed for this sender");

      commits[commitHash].proofHash = proofHash;
      commits[commitHash].block = block.number;

      emit Committed(
         msg.sender,
         burnTxHash,
         proofHash,
         commitHash
      );
   }

   /// @param chainId Source ChainId
   /// @param claimAddress Address to be assigned the tokens if the proof is valid
   /// @param fee Fee to be paid, in tokens, to the prover that broadcasted the transaction
   /// @param txRoot Root of transaction tree of the block, to be used to prove transaction has beed included in the block
   /// @param mmrRoot MMR root to be used to prove block has been included in the source blockchain
   /// @param autoExchange If true, ERC20 tokens will be exchanged to Dust automatically
   /// @param rawTransaction PoB raw transaction sent to the source Blockchain
   /// @param transactionProofOfInclusion RLP serialised proof of inclusion to be ran to check the tx was included in the source block
   /// @param mmrProof RLP serialised mmr proof to be ran to check the block was included in the source Blockchain
   function redeem (
      uint8 chainId,
      address claimAddress,
      uint256 fee,
      bytes32 txRoot,
      bytes32 mmrRoot,
      bool autoExchange,
      bytes memory rawTransaction,
      bytes memory transactionProofOfInclusion,
      bytes memory mmrProof
   ) public {
      bytes memory proof = abi.encode(
         chainId,
         claimAddress,
         fee,
         txRoot,
         mmrRoot,
         autoExchange,
         rawTransaction,
         transactionProofOfInclusion,
         mmrProof
      );

      uint256 burnedCoins = verifyPoBAndGetBurnedTokens(
        chainId,
        mmrRoot,
        proof,
        rawTransaction
      );

      require(burnedCoins >= fee, "No enough to pay for the mint fees");

      // ERC20 tokens are deployed by chainId starting from address 0x0b
      IERC20 erc20 = IERC20(address(uint160(Constants.erc20TokenStart()) + chainId));
      // Assign the minted tokens to the user
      uint tokenToMintForClaimer = burnedCoins - fee;
      erc20.mint(claimAddress, tokenToMintForClaimer);
      // Assign the fee tokens to the prover who sent the transaction
      erc20.mint(msg.sender, fee);

      if(autoExchange) {
         IDuster dusterContract = IDuster(Constants.duster());
         dusterContract.toDustFrom(chainId, claimAddress, tokenToMintForClaimer);
      }
      emit Redeemed(
         msg.sender,
         getBurnTxHash(rawTransaction),
         getProofHash(proof),
         getCommitHash(rawTransaction, msg.sender),
         autoExchange
      );
   }

   /// @param burnTxHash H(rawTransaction)
   //  with rawTransaction = PoB transaction sent to the source Blockchain
   function wasRedeemed(bytes32 burnTxHash) external view returns(bool) {
        return reveals[burnTxHash];
   }

   /// @param chainId Source ChainId
   /// @param mmrRoot MMR root to be used to prove block has been included in the source blockchain
   /// @param proof abi encode of chainId, claimAddress, fee, txRoot, mmrRoot, autoExchange, rawTransaction, transactionProofOfInclusion, mmrProof
   /// @param rawTransaction PoB raw transaction sent to the source Blockchain
   function verifyPoBAndGetBurnedTokens (
      uint8 chainId,
      bytes32 mmrRoot,
      bytes memory proof,
      bytes memory rawTransaction
   ) internal returns (uint256 burnedCoins) {
      // Retrieve the tag in order to check the proof of inclusion is made using a Federation created Tag
      ITagsRepository tagsRepositoryContract = ITagsRepository(Constants.tagsRepository());
      require(tagsRepositoryContract.isRecentMMRRoot(chainId, mmrRoot), "MMR Root does not exist, cannot check PoB proof");

      // Verify proof of burn commitment and reveal
      reveal(proof, rawTransaction);

      // Claim and return the tokens
      uint160 verifierAddr = uint160(Constants.proofOfBurnVerifier());
      bool verifierCallSuccessful;
      assembly {
         // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
         let resultPointer := mload(0x40)
         // First 32 bytes are the length of the encode abi
         let inputDataPointer := add(proof, 0x20)
         let inputDataLength := mload(proof)

         // Invoke the precompiled contract with params https://solidity.readthedocs.io/en/v0.5.3/assembly.html
         // call(g, a, v, in, insize, out, outsize)
         // - g: send all the remaining gasleft
         // - a: verify precompiled contract
         // - v: zero value
         // - in: pointer to input data
         // - insize: size of input data
         // - out: pointer to output data
         // - outsize: size of output data
         verifierCallSuccessful := call(not(0), verifierAddr, 0, inputDataPointer, inputDataLength, resultPointer, 0x20)
         burnedCoins := mload(resultPointer)
      }
      require(verifierCallSuccessful, "Call to PoB verifier failed");
   }

   // Do all the required validations, if all of them are ok, reveal the burn
   /// @param proof abi encode of chainId, claimAddress, fee, txRoot, mmrRoot, autoExchange, rawTransaction, transactionProofOfInclusion, mmrProof
   /// @param rawTransaction PoB raw transaction sent to the source Blockchain
   function reveal(bytes memory proof, bytes memory rawTransaction) private {
      bytes32 burnTxHash = getBurnTxHash(rawTransaction);
      bytes32 commitHash = getCommitHash(rawTransaction, msg.sender);
      require(reveals[burnTxHash] == false, "Burn transaction already claimed");
      require(commits[commitHash].block > 0, "Uncommitted hash");
      require(commits[commitHash].proofHash ==
         getProofHash(proof), "Current proof does not match with the committed one");

      IConstantsRepository constantsRepository = IConstantsRepository(Constants.constantsRepository());

      // Require that the block number is greater than the original block plus stability param
      // It means block is buried exactly under k blocks
      require(block.number > commits[commitHash].block + constantsRepository.getRevealMinAge(),
         "Reveal happened too early");

      // Gas refund for the committer.
      delete commits[commitHash];

      // Reveal the burn
      reveals[burnTxHash] = true;
   }

   function getBurnTxHash(bytes memory rawTransaction) internal pure returns (bytes32) {
      return sha256(rawTransaction);
   }

   function getCommitHash(bytes memory rawTransaction, address prover) internal pure returns (bytes32) {
      return sha256(abi.encodePacked(prover, getBurnTxHash(rawTransaction)));
   }

   function getCommitHash(bytes32 burnTxHash, address prover) internal pure returns (bytes32) {
      return sha256(abi.encodePacked(prover, burnTxHash));
   }

   /// @param proof abi encode of chainId, claimAddress, fee, txRoot, mmrRoot, autoExchange, rawTransaction, transactionProofOfInclusion, mmrProof
   function getProofHash(bytes memory proof) internal pure returns (bytes32) {
      return sha256(proof);
   }
}