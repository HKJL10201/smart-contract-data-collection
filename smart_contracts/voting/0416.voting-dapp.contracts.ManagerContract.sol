pragma solidity 0.5.1;

import "./VotingContract.sol";
import "./CategoryContract.sol";


contract ManagerContract {
   
    address[] public categoryContractsList;
    mapping(address => bool) public doesCategoryExist;
    mapping(bytes32 => address) public categoryAddress;

    event CategoryCreated(address creator, address categoryAddress, bytes32 categoryName);
    event VotingCreated(address creator, address votingAddress, string question);

    function createVotingWithExistingCategory(address _category,
        string memory _question,
        bytes32[] memory _options,
        uint256 _votingEndTime,
        uint256 _resultsEndTime,
        bool _isPrivate,
        address[] memory _permissions) public {

        require(doesCategoryExist[_category], "Provided addresss does not point to an existing category!");
        CategoryContract cc = CategoryContract(_category);
        address vcAddress = cc.createVotingContract(_question, _options, _votingEndTime, _resultsEndTime, _isPrivate, _permissions);
        emit VotingCreated(msg.sender, vcAddress, _question);
    }

    function createVotingWithNewCategory(bytes32 _categoryName,
        string memory _question,
        bytes32[] memory _options,
        uint256 _votingEndTime,
        uint256 _resultsEndTime,
        bool _isPrivate,
        address[] memory _permissions) public {
        
        require(categoryAddress[_categoryName] == address(0), "This category name is already used");

        CategoryContract cc = new CategoryContract(_categoryName, address(this)); 
        categoryAddress[_categoryName] = address(cc);
        doesCategoryExist[address(cc)] = true;
        categoryContractsList.push(address(cc));
        emit CategoryCreated(msg.sender, address(cc), _categoryName);

        address vcAddress = cc.createVotingContract(_question, _options, _votingEndTime, _resultsEndTime, _isPrivate, _permissions);
        emit VotingCreated(msg.sender, vcAddress, _question);
    }

    function numberOfCategories() public view returns(uint) {
        return categoryContractsList.length;
    }
}