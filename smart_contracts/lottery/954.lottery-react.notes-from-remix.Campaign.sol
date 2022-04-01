pragma solidity ^0.4.17;

contract Campaign {
    // When placing a struct, we are introducing
    // a new type into our contract,
    // A type is a definition and not an instance
    // of a variable.
    // When we eventually want to make a request,
    // we will make a new variable and specify
    // that it's type is Request.
    struct Request {
        // listing the variable's type
        string description;
        uint value;
        address recipient;
        bool complete;
    }

    // Making a new array and specifying its type
    // as Request
    Request[] public requests;
    // Want people to know who the manager is as it
    // instills more confidence in the users
    address public manager;
    uint public minimumContribution;
    // initializing the approvers variable as an array
    // of addresses
    address[] public approvers;

    modifier restricted() {
        require(msg.sender == manager);
        // we mark where we want our code to be
        // virtually pasted
        _;
    }

    // Whenever someone calls the Campaign() function
    // they're required to provide a minimum
    // contribution
    function Campaign(uint minimum) public {
        // Recall that the '.sender' property is always
        // available to us and describes exactly who is
        // attempting to create the contract
        manager = msg.sender;
        minimumContribution = minimum;
    }

    // 'payable' keyword   what lets this function
    // receive some amount of money.
    function contribute() public payable {
        // Making sure that the user is sending in an
        // amount of money greater than minimum
        // where 'msg.value' is the amount in Wei
        require(msg.value > minimumContribution);

        // Adding user onto our approvers list.
        // Address of the user who is sending in
        // this transaction,  which is coming from
        // our global variable message
        approvers.push(msg.sender);
    }

    // We want the function to be public because it
    // should be callable from an external account.
    // We also want to lock the function down by using
    // the 'restricted' modifier.
    function createRequest(string description, uint value, address recipient)
        public restricted {
        // Code that will create the new requests

        // We are creating a brand new Request variable in 'memory'
        // 'Request' is pointing to 'newRequest', and thus, this new variable
        // cannot point to a variable in storage because it doesn't
        // exist in storage.

        Request memory newRequest = Request({
           // placing collection of key: value pairs that specify:
           description: description,
           value: value,
           recipient: recipient,
           complete: false
        });

        requests.push(newRequest);
    }

}
