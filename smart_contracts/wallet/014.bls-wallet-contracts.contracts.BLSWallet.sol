//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;


//To avoid constructor params having forbidden evm bytecodes on Optimism
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./lib/IERC20.sol";
import "hardhat/console.sol";

interface IVerificationGateway {
    function walletCrossCheck(bytes32 publicKeyHash) external;
}

contract BLSWallet is Initializable
{
    address public gateway;
    bytes32 public publicKeyHash;
    uint256 public nonce;

    function initialize(bytes32 blsKeyHash) public initializer {
        publicKeyHash = blsKeyHash;
        gateway = msg.sender;
        nonce = 0;
    }

    receive() external payable {}
    fallback() external payable {}

    function payTokenAmount(
        IERC20 token,
        address recipient,
        uint256 amount
    ) public onlyGateway returns (
        bool success
    ) {
        bytes memory transferFn = abi.encodeWithSignature(
            "transfer(address,uint256)",
            recipient,
            amount
        );
        (success, ) = address(token).call(transferFn);
    }

    function action(
        uint256 ethValue,
        address contractAddress,
        bytes calldata encodedFunction
    ) public payable onlyGateway returns (bool success) {
        if (ethValue > 0) {
            (success, ) = payable(contractAddress).call{value: ethValue}(encodedFunction);
        }
        else {
            (success, ) = address(contractAddress).call(encodedFunction);
        }
        nonce++;
    }

    //TODO: reset admin (via bls key)

    //TODO: social recovery

    modifier onlyGateway() {
        require(msg.sender == gateway);
        _;
    }
}
