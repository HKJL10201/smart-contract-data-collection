pragma solidity 0.5.1;

import "./VotingContract.sol";


contract CategoryContract {
    
    address[] public votingContracts;
    bytes32 public categoryName;
    address internal managerContract;

    constructor(bytes32 _categoryName, address _managerContract) public {
        categoryName = _categoryName;
        managerContract = _managerContract;
    }
    
    function createVotingContract (
        string memory _question,
        bytes32[] memory _options,
        uint256 _votingEndTime,
        uint256 _resultsEndTime,
        bool _isPrivate,
        address[] memory _permissions) public returns(address) {
        
        require(msg.sender == managerContract, "Only the ManagerContract is authorised to create a new voting");

        VotingContract vc = new VotingContract(
            _question, address(this), _options, _votingEndTime, _resultsEndTime, _isPrivate, _permissions);
        
        uint8 i = 0;
        // iterating to remove the contract which is expired
        for (i = 0; i < votingContracts.length; i++) {
            VotingContract v = VotingContract(votingContracts[i]);
            if (now > v.resultsEndTime()) {
                votingContracts[i] = address(vc);
                break;
            }
        }
        
        if (i == votingContracts.length) {
            votingContracts.push(address(vc));
        }

        return address(vc);
    }

    function numberOfContracts() public view returns (uint) {
        return votingContracts.length;
    }
}