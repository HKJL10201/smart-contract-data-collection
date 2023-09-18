pragma solidity >0.5.0;

// declare interface
interface DataBuyerInterface {

  function send_budget_and_epsilons(uint budget, uint[] calldata epsilons, uint[] calldata prices) external  returns (uint[] memory);

  function get_requirements() external returns (string memory);

  function send_result(string calldata result) external;
}
