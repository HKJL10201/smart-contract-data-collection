// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Base64.sol";

contract NFTwitter is ERC721, Ownable {

    struct Tweet {
        uint256 tweetId;
        uint256 parentId;
        string content;
        uint256 timestamp;
        address author;
        address owner;
        uint256 likes;
    }

    uint256 private _tweetIds;
    mapping(uint256 => Tweet) private tweets;
    mapping(address => uint256[]) private tweetsByOwner;
    mapping(uint256 => uint256[]) private tweetsReplies;
    mapping(uint256 => address[]) private likersByTweetId;

    string baseSvg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='black' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    uint256 private tipsOwnerPercent;
    uint256 private tipsAuthorPercent;
    uint256 private tipsPlatformPercent;

    event newTweet(uint256 tweetId);
    event tweetDeleted(uint256 tweetId);
    event tweetLiked(uint256 tweetId, address liker, uint256 newNbLikes);
    event tweetUnliked(uint256 tweetId, address liker, uint256 newNbLikes);

    modifier requireTweetExists(uint256 _tokenId)
    {
        require(_exists(_tokenId), "Tweet does not exists");
        _;
    }

    constructor() ERC721("NFTwitter", "NFTT") Ownable() {
        _tweetIds = 1;

        tipsOwnerPercent = 70;
        tipsAuthorPercent = 20;
        tipsPlatformPercent = 10;
    }

    function updateTipsPercent(uint256 owner, uint256 author, uint256 platform) external onlyOwner
    {
        require(owner + author + platform == 100, "All percents should reach 100%");

        tipsOwnerPercent = owner;
        tipsAuthorPercent = author;
        tipsPlatformPercent = platform;
    }

    function tweet(string memory content, uint256 parentId) external {
        require(bytes(content).length > 0, "Tweet must have a content !");
        require(_exists(parentId) || parentId == 0, "Parent tweet does not exist");         //no parent -> id = 0 (tweets ids starts at 1)
        uint256 newTweetId = _tweetIds;
        _safeMint(msg.sender, newTweetId);

        tweets[newTweetId] = Tweet({
            tweetId: newTweetId, parentId: parentId, content: content, timestamp: block.timestamp, author: msg.sender, owner: msg.sender, likes: 0
        });

        tweetsByOwner[msg.sender].push(_tweetIds);
        if(parentId != 0)
        {
            tweetsReplies[parentId].push(newTweetId);
        }
        
        _tweetIds++;

        emit newTweet(newTweetId);
    }

    function deleteTweet(uint256 _tokenId) external {
        _burn(_tokenId);

        emit tweetDeleted(_tokenId);
    }

    function likeTweet(uint256 _tokenId) external requireTweetExists(_tokenId) {
        require(tweets[_tokenId].author != msg.sender, "You can't like your own tweet !");
        require(!didILikedTweet(_tokenId), "Tweet already liked !");
        
        likersByTweetId[_tokenId].push(msg.sender);
        tweets[_tokenId].likes++;

        emit tweetLiked(_tokenId, msg.sender, tweets[_tokenId].likes);
    }

    function unlikeTweet(uint256 _tokenId) external requireTweetExists(_tokenId) {
        address[] memory likers = likersByTweetId[_tokenId];
        bool found = false;
        uint indice = 0;
        for(uint i = 0; i < likers.length && !found; i++)
        {
            if(likers[i] == msg.sender)
            {
                found = true;
                indice = i;
            }
        }

        require(found, "Tweet not liked !");

        delete likersByTweetId[_tokenId][indice];
        tweets[_tokenId].likes--;

        emit tweetUnliked(_tokenId, msg.sender, tweets[_tokenId].likes);
    }

    function tipTweet(uint256 _tokenId) external payable requireTweetExists(_tokenId) {
        require(msg.value > 0);
        
        Tweet memory tweetTipped = tweets[_tokenId];
        if(tweetTipped.author == tweetTipped.owner)
        {
            uint256 authorOwnerPercent = tipsAuthorPercent + tipsOwnerPercent;
            uint authorAmount = authorOwnerPercent * msg.value / 100;
            payable(tweetTipped.author).transfer(authorAmount);
        }
        else
        {
            uint authorAmount = tipsAuthorPercent * msg.value / 100;
            payable(tweetTipped.author).transfer(authorAmount);

            uint ownerAmount = tipsOwnerPercent * msg.value / 100;
            payable(tweetTipped.owner).transfer(ownerAmount);
        }

        uint platformAmount = tipsPlatformPercent * msg.value / 100;
        payable(owner()).transfer(platformAmount);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transfer(from, to, tokenId);

        tweets[tokenId].owner = to;
        tweetsByOwner[to].push(tokenId);
        delete tweetsByOwner[from][tokenId];
    }

    function tokenURI(uint256 _tokenId) public view override requireTweetExists(_tokenId) returns (string memory) {
        string memory json = Base64.encode(
            bytes(
            string(
                abi.encodePacked(
                '{"name": "NFTweet #',
                Strings.toString(_tokenId),
                '", "description": "This NFT is a tweet.", "image": "',
                tweetImageURI(_tokenId),
                '", "attributes": [ { "trait_type": "Parent Tweet Id", "value": "', Strings.toString(tweets[_tokenId].parentId),'"}, { "trait_type": "Content", "value": "',
                tweets[_tokenId].content,'"} , { "trait_type": "Likes", "value": "', Strings.toString(tweets[_tokenId].likes),'"}]}'
                )
            )
            )
        );

        string memory output = string(
            abi.encodePacked('data:application/json;base64,', json)
        );
        
        return output;
    }

    function tweetImageURI(uint256 _tokenId) public view requireTweetExists(_tokenId) returns (string memory) {
        string memory svg = string(abi.encodePacked(baseSvg, tweets[_tokenId].content, '</text></svg>'));
        
        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(svg))));
    }

    function getTweetsOfOwner(address owner) public view returns (Tweet[] memory) {
        uint256[] memory ownerTweets = tweetsByOwner[owner];
        uint totalCount = ownerTweets.length;

        uint count = 0;
        for(uint i = 1; i < totalCount; i++)
        {
            if(_exists(ownerTweets[i]))
                count++;
        }

        Tweet[] memory tweetsList = new Tweet[](count);
        uint indice = 0;
        for(uint i = 0; i < count; i++)
        {
            if(_exists(ownerTweets[i]))
            {
                tweetsList[indice] = tweets[ownerTweets[i]];
                indice++;
            }
        }

        return tweetsList;
    }

    function getTweet(uint256 _tokenId) public view requireTweetExists(_tokenId) returns (Tweet memory) {
        return tweets[_tokenId];
    }

    function getReplies(uint256 _tokenId) public view requireTweetExists(_tokenId) returns (Tweet[] memory) {
        uint256[] memory replies = tweetsReplies[_tokenId];
        uint totalCount = replies.length;

        uint count = 0;
        for(uint i = 1; i < totalCount; i++)
        {
            if(_exists(replies[i]))
                count++;
        }

        Tweet[] memory tweetsList = new Tweet[](count);
        uint indice = 0;
        for(uint i = 0; i < count; i++)
        {
            if(_exists(replies[i]))
            {
                tweetsList[indice] = tweets[replies[i]];
                indice++;
            }
        }

        return tweetsList;
    }

    function getTweets() public view returns (Tweet[] memory tweetsList, bool[] memory likedBySender) 
    {
        uint count = 0;
        for(uint i = 1; i < _tweetIds; i++)
        {
            if(_exists(i))
                count++;
        }
        tweetsList = new Tweet[](count);
        likedBySender = new bool[](count);

        uint indice = 0;
        for(uint i = 1; i < _tweetIds; i++)
        {
            if(_exists(i))
            {
                tweetsList[indice] = tweets[i];
                likedBySender[indice] = didILikedTweet(tweets[i].tweetId);
                indice++;
            }
        }
        return (tweetsList, likedBySender);
    }

    function didUserLikedTweet(address user, uint256 _tokenId) public view requireTweetExists(_tokenId) returns (bool liked) 
    {
        address[] memory likers = likersByTweetId[_tokenId];
        bool found = false;
        for(uint i = 0; i < likers.length && !found; i++)
        {
            if(likers[i] == user)
            {
                found = true;
            }
        }

        return found;
    }

    function didILikedTweet(uint256 _tokenId) public view requireTweetExists(_tokenId) returns (bool liked) 
    {
        return didUserLikedTweet(msg.sender, _tokenId);
    }
}