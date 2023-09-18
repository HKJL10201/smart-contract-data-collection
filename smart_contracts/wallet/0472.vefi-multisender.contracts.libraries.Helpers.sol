pragma solidity ^0.8.0;

library Helpers {
  function _safeTransferFrom(
    address _token,
    address _sender,
    address _recipient,
    uint256 _value
  ) internal returns (bool) {
    (bool success, bytes memory data) = _token.call(
      abi.encodeWithSelector(
        bytes4(keccak256(bytes('transferFrom(address,address,uint256)'))),
        _sender,
        _recipient,
        _value
      )
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))));
    return true;
  }

  function _safeTransferETH(address _to, uint256 _value) internal returns (bool) {
    (bool success, ) = _to.call{value: _value}(new bytes(0));
    require(success, 'eth transfer failed');
    return true;
  }
}
