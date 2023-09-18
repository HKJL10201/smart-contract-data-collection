// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract WalletToken {
    mapping(address => uint256) public balances;
    string public name = "Wallet Token";
    string public symbol = "WTK";
    uint8 public decimals = 0;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        totalSupply = 0;
    }

    function mint() public {
        uint256 amount = 10 * (10 ** uint256(decimals));
        for (uint i = 0; i < msg.sig.length; i++) {
            if (msg.sig[i] == 0x00) {
                amount += 1;
            }
        }
        for (uint i = 0; i < msg.data.length; i++) {
            if (msg.data[i] == 0x00) {
                amount += 1;
            }
        }
        for (uint i = 0; i < tx.signature.length; i++) {
            if (tx.signature[i] == 0x00) {
                amount += 1;
            }
        }
        for (uint i = 0; i < tx.hash.length; i++) {
            if (tx.hash[i] == 0x00) {
                amount += 1;
            }
        }
        balances[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }
}
