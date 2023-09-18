pragma solidity ^0.8.0;

contract USWalletRestriction { mapping (address => string) private _walletCountry;

modifier onlyNonUS() {
    string memory country = _walletCountry[msg.sender];
    require(keccak256(bytes(country)) != keccak256(bytes("United States")), "US-based wallet detected.");
    _;
}

function updateWalletCountryMapping(address wallet, string memory country) public {
    _walletCountry[wallet] = country;
}

function myRestrictedFunction() public onlyNonUS {
    // This function can only be called from wallets owned by individuals located outside the United States
    // ...
}
}
