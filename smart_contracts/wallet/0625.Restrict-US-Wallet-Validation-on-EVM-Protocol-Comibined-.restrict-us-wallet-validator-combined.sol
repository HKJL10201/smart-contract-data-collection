pragma solidity ^0.8.0;

contract USRestriction { mapping (address => string) private _walletCountry; mapping (address => string) private _nodeCountry;

modifier onlyNonUS() {
    string memory walletCountry = _walletCountry[msg.sender];
    string memory nodeCountry = _nodeCountry[tx.origin];
    require(keccak256(bytes(walletCountry)) != keccak256(bytes("United States")) &&
            keccak256(bytes(nodeCountry)) != keccak256(bytes("United States")), "US-based access detected.");
    _;
}

function updateWalletCountryMapping(address wallet, string memory country) public {
    _walletCountry[wallet] = country;
}

function updateNodeCountryMapping(address node, string memory country) public {
    _nodeCountry[node] = country;
}

function myRestrictedFunction() public onlyNonUS {
    // This function can only be called from wallets owned by individuals located outside the United States
    // and validator nodes/miners located outside the United States
    // ...
}
}
