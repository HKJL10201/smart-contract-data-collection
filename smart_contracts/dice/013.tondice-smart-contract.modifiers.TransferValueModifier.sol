pragma solidity >= 0.6.2;

/**
 * Error codes
 *     • 200 — Transfer value is zero
 *     • 201 — Transfer value is more than balance
 */
contract TransferValueModifier {
    modifier validTransferValue(uint128 value) {
        require(value > 0, 200, "Transfer value is zero");
        require(value < address(this).balance, 201, "Transfer value is more than balance");
        _;
    }
}