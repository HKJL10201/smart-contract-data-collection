// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Linkable {
    struct LinkData {
        string name;
        address link;
        string description;
        string linkType;
        string meta;
    }

    LinkData internal _tempLink;

    LinkData[] public links;

    modifier onlyOwner() virtual {
        _;
    }

    modifier onlyOwnerOrEntryPoint() virtual {
        _;
    }

    // addLink adds a new link to the links array
    function addLink(
        string memory name,
        address link,
        string memory description,
        string memory linkType,
        string memory meta
    ) public onlyOwnerOrEntryPoint {
        LinkData memory newLink = LinkData(
            name,
            link,
            description,
            linkType,
            meta
        );
        links.push(newLink);
    }

    // updateLink updates a link in the links array
    function updateLink(
        uint256 index,
        string memory name,
        address link,
        string memory description,
        string memory linkType,
        string memory meta
    ) public onlyOwnerOrEntryPoint {
        LinkData memory updatedLink = LinkData(
            name,
            link,
            description,
            linkType,
            meta
        );
        links[index] = updatedLink;
    }

    // removeLink removes a link from the links array
    function removeLink(uint256 index) public onlyOwnerOrEntryPoint {
        delete links[index];
    }

    // clearLinks clears the links array
    function clearLinks() public onlyOwnerOrEntryPoint {
        delete links;
    }

    // getLinks returns the links array
    function getLinks() public view returns (LinkData[] memory) {
        return links;
    }
}
