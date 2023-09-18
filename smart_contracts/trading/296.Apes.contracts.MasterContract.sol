// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./reduced_interfaces/BAPGenesisInterface.sol";
import "./reduced_interfaces/BAPMethaneInterface.sol";
import "./reduced_interfaces/BAPUtilitiesInterface.sol";
import "./reduced_interfaces/BAPTeenBullsInterface.sol";
import "./reduced_interfaces/BAPOrchestratorInterfaceV2.sol";

contract MasterContract is Ownable {
    BAPMethaneInterface public bapMeth;
    BAPUtilitiesInterface public bapUtilities;
    BAPTeenBullsInterface public bapTeenBulls;

    mapping(address => bool) public isAuthorized;

    constructor(
        address _bapMethane,
        address _bapUtilities,
        address _bapTeenBulls
    ) {
        bapMeth = BAPMethaneInterface(_bapMethane);
        bapUtilities = BAPUtilitiesInterface(_bapUtilities);
        bapTeenBulls = BAPTeenBullsInterface(_bapTeenBulls);
    }

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "Not Authorized");
        _;
    }

    // METH functions

    function claim(address to, uint256 amount) external onlyAuthorized {
        bapMeth.claim(to, amount);
    }

    function pay(uint256 payment, uint256 fee) external onlyAuthorized {
        bapMeth.pay(payment, fee);
    }

    // Teens functions

    function airdrop(address to, uint256 amount) external onlyAuthorized {
        bapTeenBulls.airdrop(to, amount);
    }

    function burnTeenBull(uint256 tokenId) external onlyAuthorized {
        bapTeenBulls.burnTeenBull(tokenId);
    }

    // Utilities functions

    function burn(uint256 id, uint256 amount) external onlyAuthorized {
        bapUtilities.burn(id, amount);
    }

    function airdrop(
        address to,
        uint256 amount,
        uint256 id
    ) external onlyAuthorized {
        bapUtilities.airdrop(to, amount, id);
    }

    // Ownable

    function setAuthorized(address operator, bool status) external onlyOwner {
        isAuthorized[operator] = status;
    }

    function transferOwnershipExternalContract(
        address _contract,
        address _newOwner
    ) external onlyOwner {
        Ownable(_contract).transferOwnership(_newOwner);
    }

    function setMethaneContract(address _newAddress) external onlyOwner {
        bapMeth = BAPMethaneInterface(_newAddress);
    }

    function setUtilitiesContract(address _newAddress) external onlyOwner {
        bapUtilities = BAPUtilitiesInterface(_newAddress);
    }

    function setTeenBullsContract(address _newAddress) external onlyOwner {
        bapTeenBulls = BAPTeenBullsInterface(_newAddress);
    }
}
