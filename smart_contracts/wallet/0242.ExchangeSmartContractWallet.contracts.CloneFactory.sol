// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  function createClone(address _logic, bytes memory _data) internal returns (address) {
    return createClone0(_logic, _data);
  }

  function createClone0(address _logic, bytes memory _data) internal returns (address proxy) {
    bytes20 targetBytes = bytes20(_logic);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x37)
    }

    if(_data.length > 0) {
      (bool success,) = proxy.call(_data);
      require(success);
    }
  }

  function createClone1(address _logic, bytes memory _data) internal returns (address proxy) {
    bytes20 targetBytes = bytes20(_logic)<<32;
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602980600a3d3981f3363d3d373d3d3d363d6f000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x24), 0x5af43d82803e903d91602757fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x33)
    }

    if(_data.length > 0) {
      (bool success,) = proxy.call(_data);
      require(success);
    }
  }

  function createClone2(address _logic, bytes memory _data) internal returns (address proxy) {
    bytes20 targetBytes = bytes20(_logic)<<24;
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602a80600a3d3981f3363d3d373d3d3d363d70000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x25), 0x5af43d82803e903d91602857fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x34)
    }

    if(_data.length > 0) {
      (bool success,) = proxy.call(_data);
      require(success);
    }
  }

  function createClone3(address _logic, bytes memory _data) internal returns (address proxy) {
    bytes20 targetBytes = bytes20(_logic)<<16;
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602b80600a3d3981f3363d3d373d3d3d363d71000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x26), 0x5af43d82803e903d91602957fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x35)
    }

    if(_data.length > 0) {
      (bool success,) = proxy.call(_data);
      require(success);
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}