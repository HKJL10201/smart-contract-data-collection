pragma solidity 0.5.15;

interface ISynthetix {
    function issueMaxSynths() external;
    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint);
    function burnSynths(uint amount) external;
    function transferableSynthetix(address account) external view returns(uint);
    function collateralisationRatio(address account) external view returns(uint);
}