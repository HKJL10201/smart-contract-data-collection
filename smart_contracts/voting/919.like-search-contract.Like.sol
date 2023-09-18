// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./utils/redBlackTree.sol";
import "./utils/bytes32Array.sol";
import "./url/UrlDatabase.sol";
import "./ERC20/ERC20.sol";
contract Like is ERC20,UrlDatabase {
    using RedBlackTree for RedBlackTree.Tree;
    using Bytes32Array for Bytes32Array.Array;
    // keyword => number of urls
    mapping(bytes32 => uint256) public total;
    // keyword => likes tree
    // The red black tree stores the number of likes.
    mapping(bytes32 => RedBlackTree.Tree) likesTree;
    // keyword => likes => urls
    // The mapping sotres urls with the same number of likes
    mapping(bytes32 => mapping(uint256 => Bytes32Array.Array)) likesUrls;
    // keyword => urls => likes
    // The mapping sotres total number of likes of a url
    mapping(bytes32 => mapping(bytes32 => uint256)) public urlsLikes;
    // keyword => urls => address => likes
    // The mapping sotres balance
    mapping(bytes32 => mapping(bytes32 => mapping(address => uint256)))
        public urlsLikesBalances;
    event Liked(
        bytes32 indexed keywordId,
        bytes32 indexed urlId,
        address indexed from,
        uint256 likes,
        uint256 totalLikes
    );
    event Withdrawn(
        bytes32 indexed keywordId,
        bytes32 indexed urlId,
        address indexed from,
        uint256 likes,
        uint256 totalLikes
    );

    constructor () ERC20("Like Search Token", "LKS") {
        _mint(msg.sender, 1000000000000);
    }
    function decimals() public pure override returns (uint8) {
        return 0;
    }
    function _like(bytes32 keywordId, UrlLibrary.Url memory url, address sender, uint256 amount) internal{
        bytes32 urlId = saveUrl(url);
        uint256 oldLikes = urlsLikes[keywordId][urlId];
        RedBlackTree.Tree storage tree = likesTree[keywordId];
        if (oldLikes == 0) {
            total[keywordId]++;
        } else {
            Bytes32Array.Array storage oldLikesArray = likesUrls[keywordId][oldLikes];
            oldLikesArray.remove(urlId);
            if (oldLikesArray.length() == 0) {
                tree.remove(oldLikes);
            }
        }
        uint256 newLikes = oldLikes + amount;
        Bytes32Array.Array storage newLikesArray = likesUrls[keywordId][newLikes];
        newLikesArray.insert(urlId);
        tree.insert(newLikes);
        urlsLikes[keywordId][urlId] = newLikes;
        urlsLikesBalances[keywordId][urlId][sender] += amount;
        emit Liked(keywordId, urlId, sender, amount, newLikes);
    }
    function like(
        bytes32 keywordId, UrlLibrary.Url memory url, uint256 amount
    ) public returns (bool){
        transfer(address(this),amount);
        _like(keywordId, url, _msgSender(), amount);
        return true;
    }
    function likeFrom(address sender,bytes32 keywordId, UrlLibrary.Url memory url, uint256 amount) public returns (bool){
        transferFrom(sender,address(this),amount);
        _like(keywordId, url, sender, amount);
        return true;
    }
    function withdraw(
        bytes32 keywordId,
        bytes32 urlId,
        uint256 amount
    ) public returns (bool) {
        require(amount > 0);
        require(urlsLikesBalances[keywordId][urlId][_msgSender()] >= amount,"Out of balance");
        _transfer(address(this),_msgSender(),amount);
        uint256 oldLikes = urlsLikes[keywordId][urlId];
        RedBlackTree.Tree storage tree = likesTree[keywordId];
        Bytes32Array.Array storage oldLikesArray = likesUrls[keywordId][oldLikes];
        oldLikesArray.remove(urlId);
        if (oldLikesArray.length() == 0) {
            tree.remove(oldLikes);
        }
        uint256 newLikes = urlsLikes[keywordId][urlId] - amount;
        if (newLikes == 0) {
            total[keywordId]--;
        } else {
            Bytes32Array.Array storage newLikesArray = likesUrls[keywordId][newLikes];
            newLikesArray.insert(urlId);
            tree.insert(newLikes);
        }
        urlsLikes[keywordId][urlId] = newLikes;
        urlsLikesBalances[keywordId][urlId][_msgSender()] -= amount;
        emit Withdrawn(keywordId, urlId, _msgSender(), amount, newLikes);
        return true;
    }

    function getAt(
        bytes32 keywordId,
        uint256 index,
        bool descending
    ) public view returns (uint256 _likes, bytes32[] memory _urlIds) {
        RedBlackTree.Tree storage tree = likesTree[keywordId];
        _likes = tree.getAt(index, descending);
        Bytes32Array.Array storage likesArray = likesUrls[keywordId][_likes];
        _urlIds = likesArray.getAll();
    }

    function getBatch(
        bytes32 keywordId,
        uint256 from,
        uint8 size,
        bool descending
    )
        public
        view
        returns (bytes32[][] memory _urlIds, uint256[] memory _likes)
    {
        RedBlackTree.Tree storage tree = likesTree[keywordId];
        _likes = tree.getBatch(from, size, descending);
        _urlIds = new bytes32[][](size);
        for (uint8 i; i < size; i++) {
            if (_likes[i] != 0) {
                    Bytes32Array.Array storage likesArray
                 = likesUrls[keywordId][_likes[i]];
                _urlIds[i] = likesArray.getAll();
            } else {
                break;
            }
        }
    }

    function totalRanking(bytes32 keywordId) public view returns (uint256) {
        RedBlackTree.Tree storage tree = likesTree[keywordId];
        return tree.total;
    }

    function indexOf(
        bytes32 keywordId,
        bytes32 urlId,
        bool descending
    ) public view returns (bool _found, uint256 _index) {
        RedBlackTree.Tree storage tree = likesTree[keywordId];
        (bool f, uint256 i) = tree.getIndex(
            urlsLikes[keywordId][urlId],
            descending
        );
        if (f) {
            return (true, i);
        } else {
            return (false, 0);
        }
    }
}