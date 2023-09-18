// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

contract Authentication {

    /* Storage */

    /** @dev address to user name mapping. */
    mapping (address => bytes32) private users;


    /* Public Functions */

    /**
     * @notice Sign up.
     *
     * @dev Adds a new user to the `users` mapping.
     *      - Checks whether user is already signedup or not.
     *
     * @param _name - user's name
     */
    function signup(bytes32 _name)
        public
        returns (bytes32)
    {
        require(
            users[msg.sender] == bytes32(0),
            "User must not already exists."
        );

        users[msg.sender] = _name;
    }
}
