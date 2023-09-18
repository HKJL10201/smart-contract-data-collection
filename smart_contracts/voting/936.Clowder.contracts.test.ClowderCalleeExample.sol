// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {IClowderCallee} from "../interfaces/IClowderCallee.sol";

import {BuyOrderV1} from "../libraries/passiveorders/BuyOrderV1.sol";
import {IClowderMain} from "../interfaces/IClowderMain.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IWETH} from "../interfaces/IWeth.sol";

struct CallInfo {
    uint256 value;
    address to;
    bytes data;
}

contract ClowderCalleeExample is IClowderCallee, Ownable {
    IClowderMain public clowderMain;
    IWETH public immutable wNativeToken;

    constructor(address _clowderMain, address _wNativeToken, address _owner) {
        clowderMain = IClowderMain(_clowderMain);
        wNativeToken = IWETH(_wNativeToken);
        _transferOwnership(_owner);
    }

    error ExternalCallFailed(uint256 index);

    // To be able to receive NFTs
    // Note: parameters must stay as it is a standard
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // to be able to receive eth
    receive() external payable {}

    function clowderCall(bytes calldata data) external {
        require(
            msg.sender == address(clowderMain),
            "ClowderCalleeExample: clowderCall can only be called by ClowderMain"
        );
        // it's not necessary to check who originally called ClowderMain.executeOnPassiveBuyOrders
        // because ClowderMain only calls this function on the sender of the transaction

        // intented to buy and transfer the NFT, left open for the
        // caller to implement according to each marketplace's API
        (CallInfo[] memory calls, address _excessWNativeTokenReceiver) = abi
            .decode(data, (CallInfo[], address));
        for (uint256 i = 0; i < calls.length; i++) {
            (bool _success, ) = calls[i].to.call{value: calls[i].value}(
                calls[i].data
            );
            if (!_success) {
                revert ExternalCallFailed(i);
            }
        }

        // transfer any excess wNativeToken to _excessWNativeTokenReceiver
        // as this contract shouldn't keep any wNativeToken
        uint256 _excessWNativeToken = wNativeToken.balanceOf(address(this));
        if (_excessWNativeToken > 0) {
            wNativeToken.transfer(
                _excessWNativeTokenReceiver,
                _excessWNativeToken
            );
        }
    }

    function execute(
        BuyOrderV1[] calldata buyOrders,
        uint256 executorPrice,
        uint256 tokenId,
        bytes calldata data
    ) external payable onlyOwner {
        clowderMain.executeOnPassiveBuyOrders(
            buyOrders,
            executorPrice,
            tokenId,
            data
        );
    }

    // arbitrary call for pre-approvals, etc
    function call(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success, "ClowderCalleeExample: external call failed");
        return _result;
    }

    function changeClowderMainAddress(address _clowderMain) external onlyOwner {
        clowderMain = IClowderMain(_clowderMain);
    }
}
