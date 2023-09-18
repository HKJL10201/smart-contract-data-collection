// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import './Election.sol';

contract ElectionFactory {
  struct ElectionDet {
    address deployedAddress;
    string el_n;
    string el_d;
  }

  mapping(string => ElectionDet) companyEmail;

  function createElection(
    string memory email,
    string memory election_name,
    string memory election_description
  ) public {
    Election newElection = new Election(
      msg.sender,
      election_name,
      election_description
    );

    companyEmail[email].deployedAddress = address(newElection);
    companyEmail[email].el_n = election_name;
    companyEmail[email].el_d = election_description;
  }

  function getDeployedElection(string memory email)
    public
    view
    returns (
      address,
      string memory,
      string memory
    )
  {
    address val = companyEmail[email].deployedAddress;
    if (val == address(0)) return (address(0), '', 'Create an election.');
    else
      return (
        companyEmail[email].deployedAddress,
        companyEmail[email].el_n,
        companyEmail[email].el_d
      );
  }
}
