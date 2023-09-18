// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../src/interfaces/IWorldId.sol";
import "../test/mocks/USDCMock.sol";

import "../src/LeP2P.sol";

contract LeP2PScript is Script {
    IWorldId public worldId = IWorldId(0x719683F13Eeea7D84fCBa5d7d17Bf82e03E3d260);
    IERC20 public usdc = IERC20(0xB6070545E83827182446F0B00405f04456e594ca);
    // LeP2PEscrow public escrow = LeP2PEscrow(0x9B63d91850694D66a7B10F3a0AA2AF74F4AA5631);
    // Params for ZKP Request Setup: https://0xpolygonid.github.io/tutorials/verifier/on-chain-verification/overview/#set-the-zkp-request
    address public validator = 0xF2D4Eeb4d455fb673104902282Ce68B9ce4Ac450;
    uint256 public schema = 74977327600848231385663280181476307657;
    uint256 public claimPathKey = 20376033832371109177683048456014525905119173674985843915445634726167450989630;
    uint256[] public value = new uint256[](64);
    function setUp() public {
        value[0] = 20020101;
    }

    function run() public {
        vm.startBroadcast();
        LeP2PEscrow escrow = new LeP2PEscrow(worldId, "app_staging_1031c7704926adf29c35a8f92008a648", "register", IERC20(address(usdc)));
        escrow.setZKPRequest(escrow.KYC_REQUEST_ID(), ICircuitValidator(validator), schema, claimPathKey, 2, value);
        vm.stopBroadcast();
    }
}
