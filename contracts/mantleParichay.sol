//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ICrossDomainMessenger} from "@mantleio/contracts/libraries/bridge/ICrossDomainMessenger.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract parichaySBTy is ERC721, ERC721Burnable, Ownable{

    address public cdmAddr;
    mapping(address => uint256) public addressToExpiry;
    mapping(address => uint256) public addressToTokenId;

    constructor() ERC721("Parichay", "PSBT") {
    }

    modifier onlySource() {
        require(msg.sender == cdmAddr,"Not Allowed");
        _;
    }

    function safeMint(uint256 tokenId, address user, uint256 expiry) external onlySource{
        require(balanceOf(user) == 0, "Already Minted to Address!");
        addressToTokenId[user] = tokenId;
        addressToExpiry[user] = expiry;
        _safeMint(user, tokenId);
    }

    function isExpired(address _addr) public view returns (bool) {
        if (addressToExpiry[_addr] >= block.timestamp) {
            return false;
        }
        return true;
    }

    function updateExpiry(address _addr) external onlySource{
        require(
            balanceOf(_addr) == 1,
            "For updating, you need to have your SBT on this chain."
        );
        addressToExpiry[_addr] = block.timestamp + 15780000;
    }

    function setcdmAddr(address _cdmAddr) external onlyOwner {
        cdmAddr = _cdmAddr;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, 1);
        require(from == address(0) || to == address(0), "Not Allowed");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}