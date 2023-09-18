// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Proposals.sol";

contract Main is Proposals {
    constructor(address chairMan_) public {
        chairMan = chairMan_;
        registeredVoter[msg.sender] = true;
        registeredVoter[chairMan] = true;
        numberOfVoters += 2;
    }

    address public chairMan;
}
