pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "./GlacierDrop.sol";

// Makes all the hardcoded constants from GlacierDrop be configurable on deployment
contract ConfigurableGlacierDrop is GlacierDrop {

  address private constantsRepositoryAddress;

  constructor(address constantsRepositoryAddressParam) payable {
    IConstantsRepository constantsRepository = IConstantsRepository(constantsRepositoryAddressParam);
    require(constantsRepository.getTotalAtomToBeDistributed() <= msg.value, "The total amount of atom to be distributed on the drops should be provided on deployment");

    constantsRepositoryAddress = constantsRepositoryAddressParam;
  }

  function getConstantsRepositoryAddress() override internal view returns(address){
    return constantsRepositoryAddress;
  }
}
