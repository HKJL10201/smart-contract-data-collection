/* Discussion:
 * https://dfohub.eth
 */
/* Description:
 * Initialization of the funds owned by Holders
 */
pragma solidity ^0.6.0;

contract FirstInitialization {
    function callOneTime(address) public {
        IStateHolder stateHolder = IStateHolder(IMVDProxy(msg.sender).getStateHolderAddress());
        //Founder 1 total funds: 0.3 ONE
        stateHolder.setUint256("0x748b2d8e120508b23929a6e17387be7ed418f62d_0x55d467b0802f7b70bb826c0ff9a2284040088729", 300000000000000000);
        //Founder 2 total funds: 0.25 ONE
        stateHolder.setUint256("0xec615449e4f38647f4b04425503feff069bee571_0x55d467b0802f7b70bb826c0ff9a2284040088729", 250000000000000000);
        //Founder 3 total funds: 0.2 ONE
        stateHolder.setUint256("0x01fc336274c2523c23e42af24e91ec0172bafac9_0x55d467b0802f7b70bb826c0ff9a2284040088729", 200000000000000000);
    }
}

interface IMVDProxy {
    function getStateHolderAddress() external view returns(address);
}

interface IStateHolder {
    function setUint256(string calldata varName, uint256 val) external returns(uint256);
}