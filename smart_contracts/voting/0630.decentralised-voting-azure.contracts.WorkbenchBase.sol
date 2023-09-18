pragma solidity ^0.5.10;

contract WorkbenchBase {
  event WorkbenchContractCreated(string applicationName, string workflowName, address originatingAddress);
  event WorkbenchContractUpdated(string applicationName, string workflowName, string action, address originatingAddress);

  string internal ApplicationName;
  string internal WorkflowName;

  constructor(string memory applicationName, string memory workflowName) internal {
    ApplicationName = applicationName;
    WorkflowName = workflowName;
  }

  function ContractCreated() internal {
    emit WorkbenchContractCreated(ApplicationName, WorkflowName, msg.sender);
  }

  function ContractUpdated(string memory action) internal {
    emit WorkbenchContractUpdated(ApplicationName, WorkflowName, action, msg.sender);
  }
}