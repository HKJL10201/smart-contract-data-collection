pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "jcc-solidity-utils/contracts/math/SafeMath.sol";
import "jcc-solidity-utils/contracts/owner/Administrative.sol";
import "jcc-solidity-utils/contracts/utils/AddressUtils.sol";
import "jcc-solidity-utils/contracts/list/HashList.sol";

/**
SWTC钱包风险评价
1. 支持设置SWTC钱包hash
2. 支持用SWTC钱包地址查询
 */
contract SwtcAccountCredit is Administrative {
  using SafeMath for uint256;
  using AddressUtils for address;
  using HashList for HashList.hashMap;

  HashList.hashMap _swtcAccounts;

  constructor() Administrative() public {
  }

  function addSwtcAccountHashs(bytes32[] _hashs) public onlyOwner returns (bool) {
    uint256 len = _hashs.length;

    for (uint256 i = 0; i < len; i++) {
      if (!_swtcAccounts.insert(_hashs[i])){
        return false;
      }
    }

    return true;
  }

  function removeSwtcAccountHash(bytes32 _hash) public onlyOwner returns (bool) {
    return _swtcAccounts.remove(_hash);
  }

  function queryCredit(string _jtAddr) public view returns (bool) {
    bytes32 k = keccak256(abi.encodePacked(_jtAddr));
    return _swtcAccounts.exist(k);
  }
}