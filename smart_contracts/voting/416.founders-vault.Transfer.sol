/* Discussion:
 * https://dfohub.eth
 */
/* Description:
 * This function keeps track founders funds to their own wallets
 */
pragma solidity ^0.6.0;

contract MultiSigTransfer {

    function onStart(address, address) public {
    }

    function onStop(address) public {
    }

    function transfer(address sender, uint256, address to, uint256 value, address token) public {
        IMVDProxy proxy = IMVDProxy(msg.sender);
        require(IMVDFunctionalitiesManager(proxy.getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(sender), "Unauthorized Access!");
        IStateHolder stateHolder = IStateHolder(proxy.getStateHolderAddress());
        string memory key = getKey(to, token);
        uint256 oldValue = stateHolder.getUint256(key);
        require(oldValue >= value, "Insufficient Balance!");
        proxy.transfer(to, value, token);
        stateHolder.setUint256(key, oldValue - value);
    }

    function toString(address _addr) private pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    function toLowerCase(string memory str) private pure returns(string memory) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            bStr[i] = bStr[i] >= 0x41 && bStr[i] <= 0x5A ? bytes1(uint8(bStr[i]) + 0x20) : bStr[i];
        }
        return string(bStr);
    }

    function getKey(address to, address token) private pure returns(string memory) {
        return string(
            abi.encodePacked(
                toLowerCase(toString(to)),
                "_",
                toLowerCase(toString(token))
            )
        );
    }
}

interface IMVDProxy {
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function getStateHolderAddress() external view returns(address);
    function transfer(address receiver, uint256 value, address token) external;
}

interface IStateHolder {
    function getUint256(string calldata varName) external view returns (uint256);
    function setUint256(string calldata varName, uint256 val) external returns(uint256);
}

interface IMVDFunctionalitiesManager {
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}