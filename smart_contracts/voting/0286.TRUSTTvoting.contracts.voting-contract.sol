pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original "owner" of the contract to the sender
   * account.
   */
  constructor () public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract VotingDapp is Ownable {
  using SafeMath for uint;

  mapping (uint => bytes32) public titles;

  mapping (uint => string) public descriptions;

  mapping (uint => string[]) public options;
  
  mapping (uint => address) public creators;
  
  
  mapping (address => mapping (uint => bool)) public hasVotedFor;
  
  // this mapping is adjusted to store +1 int for the indexed
  // for example, when user is voting for 0, this will store 1, and so on 
  // this is to keep in mind the fact that this mapping will be initialized
  // to have 0 as the result for all possible values in the beginning
  mapping (address => mapping (uint => uint)) public votedFor;
  
  //   mapping (uint => mapping (uint => uint)) public votesPerOption;
    
  mapping (uint => uint[]) public votesPerOption;
  
  mapping (uint => uint) public endsOn;

  uint public lastIndex;

  event newPoll(uint pollIndex);
  
  function getTitles() public view returns (bytes32[]) {
      bytes32[] memory _titles = new bytes32[](lastIndex);
      for (uint i = 1; i <= lastIndex; i++) {
          _titles[i-1] = titles[i];
      }
      return _titles;
  }
  
  function getPoll(uint _pollIndex) public view returns (bytes32, string, string[], uint[], uint, address) {
      
      return (titles[_pollIndex], 
            descriptions[_pollIndex], 
            options[_pollIndex], 
            votesPerOption[_pollIndex], 
            endsOn[_pollIndex], 
            creators[_pollIndex]);
  }
  
  function vote(uint _pollIndex, uint _optionIndex) public {
      address sender = msg.sender;
      
      require(now < endsOn[_pollIndex] && !hasVotedFor[sender][_pollIndex]);
      
      votesPerOption[_pollIndex][_optionIndex]++;
      
      hasVotedFor[sender][_pollIndex] = true;
      votedFor[sender][_pollIndex] = _optionIndex+1;
  }

    
  function createPoll(bytes32 _title, string _description, string[] _options, uint _endsOn) public {
      require(_endsOn > now && _options.length <= 16 && _options.length > 1);
      address sender = msg.sender;
      
      uint[] memory _votesPerOption = new uint[](_options.length);
      
      uint _index = ++lastIndex;
      titles[_index] = _title;
      descriptions[_index] = _description;
      options[_index] = _options;
      endsOn[_index] = _endsOn;
      creators[_index] = sender;
      
      votesPerOption[_index] = _votesPerOption;

      emit newPoll(_index);
  }
}
