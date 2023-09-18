//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";

import {ISafetyLocks} from "../interfaces/ISafetyLocks.sol";

import "../types/CallTypes.sol";

import "forge-std/Test.sol";

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256 wad) external payable;
}

// contract SearcherBase is Test {
contract SearcherBase {
    address public constant WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // TODO consider making these accessible (internal) for searchers which may want to use them
    address private immutable _owner;
    address private immutable _escrow;

    constructor(address atlasEscrow, address owner) {
        _owner = owner;
        _escrow = atlasEscrow;
    }

    function metaFlashCall(address sender, bytes calldata searcherCalldata, BidData[] calldata bids)
        external
        payable
        safetyFirst(sender)
        payBids(bids)
        returns (bool success, bytes memory data)
    {
        (success, data) = address(this).call{value: msg.value}(searcherCalldata);

        require(success, "CALL UNSUCCESSFUL");
    }

    modifier safetyFirst(address sender) {
        // Safety checks
        require(sender == _owner, "INVALID CALLER");
        uint256 msgValueOwed = msg.value;

        _;

        // NOTE: Because this is nested inside of an Atlas meta transaction, if someone is attempting
        // to innappropriately access your smart contract then THEY will have to pay for the gas...
        // so feel free to run the safety checks at the end of the call.
        // NOTE: The searcherSafetyCallback is mandatory - if it is not called then the searcher
        // transaction will revert.  It is payable and can be used to repay a msg.value loan from the
        // Atlas Escrow.
        
        require(ISafetyLocks(_escrow).searcherSafetyCallback{value: msgValueOwed}(msg.sender), "INVALID SEQUENCE");
    }

    modifier payBids(BidData[] calldata bids) {
        // Track starting balances
        uint256[] memory balances = new uint256[](bids.length);
        uint256 i;
        for (; i < bids.length;) {
            balances[i] = ERC20(bids[i].token != address(0) ? bids[i].token : WETH_ADDRESS).balanceOf(address(this));

            unchecked {
                ++i;
            }
        }

        _;

        uint256 newBalance;
        uint256 balanceDelta;
        // Handle bid payment
        i = 0;
        for (; i < bids.length;) {
            newBalance = ERC20(bids[i].token != address(0) ? bids[i].token : WETH_ADDRESS).balanceOf(address(this));

            balanceDelta = newBalance > balances[i] ? newBalance - balances[i] : 0;

            /*
            console.log("---SEARCHER BID---");
            console.log("Searcher      ",address(this));
            console.log("BidToken      ",bids[i].token);
            console.log("BalanceDelta  ",balanceDelta);
            console.log("BidAmount     ",bids[i].bidAmount);
            console.log("SearcherProfit", balanceDelta > bids[i].bidAmount ? balanceDelta - bids[i].bidAmount : 0);
            console.log("---============---");
            */

            // Ether balance
            if (bids[i].token == address(0)) {
                IWETH9(WETH_ADDRESS).withdraw(bids[i].bidAmount);
                SafeTransferLib.safeTransferETH(msg.sender, bids[i].bidAmount);

                // ERC20 balance
            } else {
                SafeTransferLib.safeTransfer(ERC20(bids[i].token), msg.sender, bids[i].bidAmount);
            }
            unchecked {
                ++i;
            }
        }
        
    }
}
