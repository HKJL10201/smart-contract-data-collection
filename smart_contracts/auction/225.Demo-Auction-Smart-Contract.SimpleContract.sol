// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.8;
import "./DeliveryService.sol";

contract SimpleContract {
    address payable salesman;
    address payable[] tenderers;
    mapping(address => uint256) bids;
    address winner;
    DeliveryService deliveryService; // oracle
    address deliverServiceAddress; // address where this

    constructor() public {
        salesman = msg.sender;
        deliveryService = DeliveryService(deliveryServiceAddress);
    }

    function bid() public payable {
        require(msg.value >= 1 wei, "Not enough ether provided");
        // each tenderer's bid is saved
        tenderers.push(msg.sender);
        bids[msg.sender] = msg.value;
        // after 10 bids have been made, the winner is elected
        if (tenderers.length == 10) {
            settlement();
        }
    }

    function settlement() private {
        uint256 highestBid = 0 wei;
        address temporaryWinner;
        // determine winner of auction
        for (uint256 i = 0; i < tenderers.length; i++) {
            if (bids[tenderers[i]] > highestBid) {
                temporaryWinner = tenderers[i];
                highestBid = bids[tenderers[i]];
            }
        }
        winner = temporaryWinner;
        finalizeDeal();
        refund();
    }

    function finalizeDeal() private {
        salesman.transfer(bids[winner]); // auction winner pays vendor
        deliveryService.sendProduct(winner); // vendor sends product
    }

    function refund() private {
        for (uint256 i = 0; i < tenderers.length; i++) {
            if (tenderers[i] != winner) {
                // refund original bid for each non winner
                tenderers[i].transfer(bids[tenderers[i]]);
            }
        }
    }
}
