// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Library {
    using Counters for Counters.Counter;
    Counters.Counter private _bookIds;

    event MemberCreated(
        address indexed member,
        string firstName,
        string lastName
    );

    address public owner;
    uint256 public totalNumberOfBooks;
    string public libraryName;

    enum BookStatus {
        Closed,
        Open
    }

    struct Book {
        address member;
        uint256 bookId;
        uint256 startDate;
        uint256 dueDate;
        string bookName;
        BookStatus bookStatus;
    }

    struct Member {
        address member;
        string firstName;
        string lastName;
    }

    Member[] public members;
    Book[] public books;

    mapping(uint => address) public bookToMembers;
    mapping(address => uint8) memberToBookCount;

    constructor() {
        owner = msg.sender;
        totalNumberOfBooks = 0;
        libraryName = "Sandbox Library";
    }

    function joinMembership(address _member, string memory _firstName, string memory _lastName) public {
        Member memory newMember = Member({
            member: _member,
            firstName: _firstName,
            lastName: _lastName
        });

        members.push(newMember);

        emit MemberCreated(
            msg.sender,
            _firstName,
            _lastName
        );
    }
 }