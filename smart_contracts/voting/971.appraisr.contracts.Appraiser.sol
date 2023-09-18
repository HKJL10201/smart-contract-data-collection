//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./AppraiserOrganization.sol";
import "./Verifier.sol";
import "./Users.sol"; // to use struct
import "./Reviewer.sol"; // to use struct

/// @author Yan Man
/// @title Appraiser main contract
contract Appraiser is Ownable {
    using Counters for Counters.Counter;

    // State Vars
    struct Deployed {
        address AppraiserOrganization;
        address Verifier;
    }
    Counters.Counter public s_orgIds; // 0-indexed
    mapping(uint256 => uint256) public s_organizations; // orgId -> intbool isActive
    mapping(uint256 => Deployed) public s_deployedContracts; // orgId -> [AppraiserOrganization address, Verifier address]
    mapping(string => uint256) private s_orgNames; // org name -> intbool exists flag
    address private s_reviewerContract;

    // Events
    event LogAddOrganization(uint256 orgId);

    // Errors
    error Appraiser__DuplicateOrgName();

    // Modifiers
    constructor(address reviewerContract_) {
        s_reviewerContract = reviewerContract_;
    }

    /**
    @return # of orgs deployed
     */
    function numberOrganizations() external view returns (uint256) {
        return s_orgIds.current();
    }

    /** 
    @dev add new organization to be open for reviews
    @param name_ name of org
    @param addr_ account representing the org
    @param URI_ IPFS URL for Verifier token / Review NFT 
     */
    function addOrganization(
        string calldata name_,
        address addr_,
        string calldata URI_
    ) public onlyOwner {
        if (s_orgNames[name_] == 1) {
            revert Appraiser__DuplicateOrgName();
        }

        uint _orgId = s_orgIds.current();
        s_organizations[_orgId] = 1;
        s_orgNames[name_] = 1;
        s_orgIds.increment();

        address _verifierAddr = _deployVerifierTokenContract(
            _orgId,
            name_,
            addr_,
            URI_
        );
        address _aoContract = _deployAppraiserOrganizationNFTContract(
            _orgId,
            name_,
            addr_,
            URI_,
            _verifierAddr
        );
        Reviewer(s_reviewerContract).setAppraiserOrganizationContractAddress(
            _orgId,
            address(_aoContract)
        );

        s_deployedContracts[_orgId] = Deployed({
            Verifier: _verifierAddr,
            AppraiserOrganization: _aoContract
        });

        emit LogAddOrganization(_orgId);
    }

    /**
    @dev deploy Verifier ERC1155 token
    @param orgId_ id
    @param name_ match organization name
    @param addr_ organization admin account address
    @param URI_ IPFS URL for token
    @return Verifier contract address
     */
    function _deployVerifierTokenContract(
        uint256 orgId_,
        string memory name_,
        address addr_,
        string memory URI_
    ) private returns (address) {
        Verifier _verifier = new Verifier(orgId_, name_, addr_, URI_, owner());

        return address(_verifier);
    }

    /**
    @dev deploy Verifier ERC1155 token
    @param orgId_ id
    @param name_ match organization name
    @param addr_ organization admin account address
    @param URI_ IPFS URL for token
    @param verifierAddr_ Verifier contract address
    @return AppraiserOrganization contract address
     */
    function _deployAppraiserOrganizationNFTContract(
        uint256 orgId_,
        string calldata name_,
        address addr_,
        string calldata URI_,
        address verifierAddr_
    ) private returns (address) {
        AppraiserOrganization _ao = new AppraiserOrganization(
            orgId_,
            name_,
            addr_,
            URI_,
            verifierAddr_,
            s_reviewerContract
        );
        return address(_ao);
    }
}
