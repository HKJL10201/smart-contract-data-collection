pragma solidity ^0.4.24;

/// @title aid development, should not be released into final version
contract Debuggable {
  event Logui(string label, uint256 value);
  event Logi(string label, int256 value);
  event Logaddress(string label, address value);

  function logui64(string s, uint64 x) internal {
    emit Logui(s, uint256(x));
  }

  function logui256(string s, uint256 x) internal {
    emit Logui(s, x);
  }

  function logi256(string s, int256 x) internal {
    emit Logi(s, x);
  }

  function logb(string s, bool b) internal {
    uint256 n = 0;
    if (b) {
      n = 1;
    }
    emit Logui(s, n);
  }

  function timeNow() public view returns (uint256) {
    /* solium-disable-next-line */
    return now;
  }
}
