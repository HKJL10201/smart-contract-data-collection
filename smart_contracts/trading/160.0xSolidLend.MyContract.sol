// SPDX-License-Identifier: MIT
pragma solidity >0.5.1;

/**
 * @title MyContract
 * @dev This is a Solidity smart contract written in the Ethereum blockchain programming language. It is named "MyContract" and contains two functions, "set" and "get", which allow a user to set and retrieve a string value, respectively. The contract is licensed under the MIT License and includes a custom development script that can be run with the command "dev-run-script file_path". When the contract is deployed, the initial value of the string is set to "default value".
 * @custom:dev-run-script file_path
 */
contract MyContract {
    constructor()  {
        state = State.Waiting;
        owner = msg.sender;
    }

    //works for get and set
    string public value = "my default value"; // value;
    string public stringValue = "my default value"; // value;
    bool public myBool = true;
    int256 age = -24;
    int256 temp =
        33333333333333333333333333333333333333333333333333333333333333333333333333332;

    //only get, use const
    // string public constant value = "my default value";// value;

    // constructor() {
    //     value = "my defaultValue";
    // }

    // function get() public view returns (string memory) {
    //     return value;
    // }

    // function set(string memory _value) public {
    //     value = _value;
    // }

    enum State {
        Waiting,
        Ready,
        Active,
        Inactive,
        Closed
    }

    State public state;

    uint256 openingTime =  1681254150;


    modifier onlyWhileOpen() {
        require(block.timestamp >= openingTime, "TIME NEVER REACH BOSS");
        _;
    }
    /// @dev The owner of the contract
    /// @notice This variable is immutable
    address public owner;

    modifier onlyOwner() {
        // require(msg.sender == owner);
        require(msg.sender == owner, "Only the owner can add people");
        _;
    }

    function changeOwner(address _newOwner) public {
        require(msg.sender == owner, "Only the owner can change the owner");
        owner = _newOwner;
    }

    function activate() public returns (string memory) {
        state = State.Active;
        return "Activation successful!";
    }

    function isActive() public view returns (bool) {
        return state == State.Active;
    }

    struct Person {
        uint256 _id;
        string _firstName;
        string _lastName;
    }

    // Person[] public people;
    uint256 public peopleCount = 0;

    //use mapping instead
    mapping(uint256 => Person) public people;

    function addPerson(string memory _firstName, string memory _lastName)
        public
        onlyWhileOpen
        onlyOwner
    {
        // people.push(Person(_firstName, _lastName));
        incrementCount();
        people[peopleCount] = Person(peopleCount, _firstName, _lastName);

        // now we can access based on id instead of index
    }

    function incrementCount() internal {
        peopleCount += 1;
    }

    //only owner can call function
}
