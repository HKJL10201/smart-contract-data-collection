pragma solidity ^0.8.17;

contract UUPSProxy {
    event Receive(address indexed sender, uint256 indexed amount, uint256 indexed balance);

    constructor(bytes memory constructData, address contractLogic) {
        assembly {
            // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, contractLogic) // slot = keccak256("PROXIABLE")
        }
        (bool success,) = contractLogic.delegatecall(constructData); // solium-disable-line
        require(success, "Construction failed");
    }

    fallback() external payable {
        assembly {
            // solium-disable-line
            let contractLogic := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) // slot = keccak256("PROXIABLE")
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), contractLogic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 { revert(0, retSz) }
            default { return(0, retSz) }
        }
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value, address(this).balance);
    }
}
