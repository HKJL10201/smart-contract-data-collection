// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Admin.sol";
import "./Session.sol";

contract Vote is Session {
  struct Option{
    uint256 index; // 1 based
    uint votes;
  }

  struct Topic {
    uint256 index; // 1 based
    address[] voters;
    bytes32[] options;
    mapping(bytes32 => Option) nameToOption;
  }

  bytes32[] private topics;
  mapping(bytes32 => Topic) private nameToTopic;
  Admin adminContract;

  event Voted(bytes32 topicName, address voter);
  event TopicAdded(uint256 topicId, bytes32 name);
  event OptionAdded(bytes32 topicName, uint256 index, bytes32 name);
  event AdminUpdated(address _address);

  modifier validName(bytes32 _name) {
    require(_name != 0, "Name can't be empty");
    _;
  }

  modifier topicExist(bytes32 _name) {
    require(isTopicExists(_name), "Topic not found");
    _;
  }

  modifier optionExist(bytes32 _topicName, bytes32 _optionName) {
    require(isOptionExists(_topicName, _optionName), "Option not found");
    _;
  }

  modifier onlyAdmin() {
    require(adminContract.isExisted(msg.sender), "Only admin is allowed");
    _;
  }

  modifier onlyUser() {
    require(
      !adminContract.isExisted(msg.sender) && 
        owner() != msg.sender, 
      "Only user is allowed");
    _;
  }

  function isTopicExists(bytes32 _name) public view returns (bool) {
    return nameToTopic[_name].index > 0;
  }

  function isOptionExists(bytes32 _topicName, bytes32 _optionName) 
    public view returns (bool) 
  {
    return nameToTopic[_topicName].nameToOption[_optionName].index > 0;
  }

  function addTopic(bytes32 _name) external validName(_name) onlyOwner onlyInActive{
    topics.push(_name);
    nameToTopic[_name].index = topics.length;
    startSession();
    emit TopicAdded(topics.length, _name);
  }

  function addOption(bytes32 _topicName, bytes32 _optionName) external 
    validName(_topicName) topicExist(_topicName) validName(_optionName)
    onlyAdmin onlyRegister 
  {
    // push new option to topic
    Topic storage _topic = nameToTopic[_topicName];
    _topic.options.push(_optionName);

    // Initilize option index
    Option storage _option = _topic.nameToOption[_optionName];
    _option.index = _topic.options.length;

    emit OptionAdded(_topicName, _option.index, _optionName);
  }

  function addVote(bytes32 _topicName, bytes32 _optionName) external 
    validName(_topicName) topicExist(_topicName) 
    validName(_optionName) optionExist(_topicName, _optionName) 
    onlyUser onlyVote
  {
    // Increment vote count in option and add address to topic
    nameToTopic[_topicName].nameToOption[_optionName].votes++;
    nameToTopic[_topicName].voters.push(msg.sender);
    emit Voted(_topicName, msg.sender);
  }

  function getTopics() external view returns (bytes32[] memory) {
    return topics;
  }

  function getLatestTopic() external view returns (bytes32) {
    return topics[topics.length - 1];
  }

  function getVoteOptions(bytes32 _name) external 
    validName(_name) topicExist(_name) view returns (bytes32[] memory) 
  {
    return nameToTopic[_name].options;
  }

  function getVoters(bytes32 _name) external validName(_name) topicExist(_name) 
    view returns (address[] memory) 
  {
    return nameToTopic[_name].voters;
  }

  function getVoteCount(bytes32 _topicName, bytes32 _optionName) external
   validName(_topicName) topicExist(_topicName) validName(_optionName) 
   optionExist(_topicName, _optionName) view returns (uint256) 
  {
    return nameToTopic[_topicName].nameToOption[_optionName].votes;
  }

  function updateAdminContract(address _address) external onlyOwner {
    adminContract = Admin(_address);
    emit AdminUpdated(_address);
  }
}
