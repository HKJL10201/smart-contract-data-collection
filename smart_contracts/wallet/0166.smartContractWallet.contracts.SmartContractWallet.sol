// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//import "hardhat/console.sol";
import "./interface/IMulticall3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * how to get this contract's eth？ call address.transfer
 * how to approve swapRouter to spend this contract's token? just like wallet。
 */
contract SmartContractWallet {
    address private multicall3Address = 0xcA11bde05977b3631167028862bE2a173976CA11;
    address payable public owner;
    modifier onlyOwner() {
        //console.log('msg.sender=', msg.sender);
        require(msg.sender == owner, 'only owner');
        _;
    }
    event event_Multicall3(bool success, bytes returnData);
    event event_Multicall3Single(bool success, bytes returnData);

    /// only used when contract is deployed
    /// @param _owner who's wallet address
    /// @param multicall3 you can set you own multicall3 deploy address ,or set to '0x0000000000000000000000000000000000000000' to use default value
    constructor(address _owner, address multicall3) payable {
        owner = payable(_owner);
        if (multicall3 != address(0x0000000000000000000000000000000000000000)) {
            multicall3Address = multicall3;
        }
        //console.log("deployer= %s, multicall3Address=", msg.sender, multicall3Address);
    }

    function destruct() public onlyOwner {selfdestruct(owner);}

    /// receive function can give the ability to receive eth
    receive() external payable {}

    /// delegatecall the function multicall3.aggregate3Value. This let you run many non-static functions from any other contracts.
    /// you can use ethersJS interface.decodeEventLog to decode event_Multicall3; then use decodeFunctionResult to
    /// decode returnData to aggregate3Value's returns: [{bool success,bytes returnData}], (you need use the function abi); then decode inner returnData to origin returns (use origin abi).
    /// hardhat's ContractReceipt has automatically decode event_Multicall3.
    function aggregate3Value(IMulticall3.Call3Value[] calldata calls) public payable onlyOwner {
        //delegatecall cann't set value,can just set gas. It spend wallet's value(wallet must has enough value, otherwise provider will throw error).   {gas: 1000000, value: 1 ether }
        (bool success, bytes memory returnData) = multicall3Address.delegatecall(abi.encodeCall(IMulticall3.aggregate3Value, calls));
        emit event_Multicall3(success, returnData);
    }

    /// use this when you don't want to spend wallet's value, or wallet have not enough value
    function aggregate3ValueSingle(IMulticall3.Call3Value calldata call) public payable onlyOwner {
        (bool success, bytes memory returnData) = call.target.call{value: call.value}(call.callData);
        emit event_Multicall3Single(success, returnData);
    }

    /// get this contract's eth
    function ethTransfer(address payable to, uint256 valueWEI) public onlyOwner returns (bool) {
        require(valueWEI + 2300 <= address(this).balance, "too large");
        to.transfer(valueWEI);
        return true;
    }

    /// Owner withdraw this contract's erc20 token
    function erc20Transfer(address tokenAddress, address to, uint256 value) public onlyOwner returns (bool){
        return IERC20(tokenAddress).transfer(to, value);
    }

    function erc20BalanceOf(address tokenAddress, address _owner) public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(_owner);
    }

    /// approve spender to spend this contract's erc20 token
    function approve(address tokenAddress, address spender, uint256 value) public onlyOwner returns (bool){
        return IERC20(tokenAddress).approve(spender, value);
    }

}