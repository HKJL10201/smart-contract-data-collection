pragma solidity ^0.5.0;
import "../Culturestake.sol";

contract MockCulturestake is Culturestake {
    constructor(address[] memory _owners, address _questionMasterCopy)
    Culturestake(_owners, _questionMasterCopy)
    public {

    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

  function checkBoothSignatureAndBurnNonce(
    bytes32 _festival,
    bytes32[] memory _answers,
    uint256 _nonce,
    uint8 sigV,
    bytes32 sigR,
    bytes32 sigS
  ) public returns (bool) {
    address addressFromSig = checkBoothSignature(_festival, _answers, _nonce, sigV, sigR, sigS);
    require(addressFromSig != address(0));
    _burnNonce(addressFromSig, _nonce);
    return true;
  }
}