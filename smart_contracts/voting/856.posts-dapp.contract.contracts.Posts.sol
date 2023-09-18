//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract Posts {
    struct Post {
        uint256 id;
        string content;
        uint256 upVotedAmount;
        uint256 downVoteAmount;
    }

    event CreatedEventSuccess(uint256 id);
    event UpVoteSuccess(uint256 id);
    error UpVoteFail(uint256 id);
    event DownVoteSuccess(uint256 id);
    error DownVoteFail(uint256 id);

    mapping(uint256 => mapping(address => bool)) addressVoted;

    address private owner;
    uint256 private count;
    mapping(address => Post[]) private posts;

    constructor() {
        owner = msg.sender;
        count = 0;
    }

    function addPost(string memory _content) external {
        count++;
        posts[msg.sender].push(Post(count, _content, 0, 0));
        emit CreatedEventSuccess(count);
    }

    function getPostByAddress() external view returns (Post[] memory) {
        Post[] storage postsOfAddress = posts[msg.sender];
        return postsOfAddress;
    }

    function upVotePost(uint256 _index) external {
        Post storage postCurrent = posts[msg.sender][_index];
        uint256 idCurrent = postCurrent.id;
        mapping(address => bool) storage postVoted = addressVoted[idCurrent];
        if (!postVoted[msg.sender]) {
            postCurrent.upVotedAmount++;
            postVoted[msg.sender] = true;
            emit UpVoteSuccess(idCurrent);
        } else {
            revert UpVoteFail(idCurrent);
        }
    }

    function downVotePost(uint256 _index) external {
        Post storage postCurrent = posts[msg.sender][_index];
        uint256 idCurrent = postCurrent.id;
        mapping(address => bool) storage postVoted = addressVoted[idCurrent];
        if (!postVoted[msg.sender]) {
            postCurrent.downVoteAmount++;
            postVoted[msg.sender] = true;
            emit DownVoteSuccess(idCurrent);
        } else {
            revert DownVoteFail(idCurrent);
        }
    }
}
