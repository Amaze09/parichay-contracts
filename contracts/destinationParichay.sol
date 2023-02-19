// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {IXReceiver} from "@connext/smart-contracts/contracts/core/connext/interfaces/IXReceiver.sol";
import {ICrossDomainMessenger} from "@mantleio/contracts/libraries/bridge/ICrossDomainMessenger.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract parichaySBTx is ERC721, ERC721Burnable, IXReceiver, Ownable {
    address public immutable connext;

    // The domain ID where the source contract is deployed
    uint32 public immutable originDomain;

    // The address of the source contract
    address public immutable source;

    address public crossDomainMessengerAddr;
    address public parichayMantleAddr;

    mapping(address => uint256) public addressToExpiry;
    mapping(address => uint256) public addressToTokenId;

    modifier onlySource(address _originSender, uint32 _origin) {
        require(
            _origin == originDomain &&
                _originSender == source &&
                msg.sender == connext,
            "Expected original caller to be source contract on origin domain and this to be called by Connext"
        );
        _;
    }

    constructor(
        uint32 _originDomain,
        address _source,
        address _connext,
        address _cdma
    ) ERC721("Parichay", "PSBT") {
        originDomain = _originDomain;
        source = _source;
        connext = _connext;
        crossDomainMessengerAddr = _cdma;
    }

    function safeMint(address user, uint256 tokenId) internal {
        require(balanceOf(user) == 0, "Already Minted to Address!");
        addressToTokenId[user] = tokenId;
        _safeMint(user, tokenId);
    }

    function xReceive(
        bytes32 _transferId,
        uint256 _amount,
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _callData
    ) external onlySource(_originSender, _origin) returns (bytes memory) {
        // Unpack the _callData
        (
            address user,
            uint256 tokenId,
            uint256 expiry,
            bool condition,
            bool isMantle
        ) = abi.decode(_callData, (address, uint256, uint256, bool, bool));
        if (condition && !isMantle) {
            //port or clone on any chain
            require(balanceOf(user) == 0, "already present");
            safeMint(user, tokenId);
            addressToExpiry[user] = expiry;
        } if (!condition && !isMantle) {
            //update on any chain
            updateExpiry(user);
        } if (condition && isMantle) {
            //port or clone on mantle
            bytes memory message;

            message = abi.encodeWithSignature(
                "safeMint(uint256,address,uint256)",
                tokenId,
                user,
                expiry
            );

            ICrossDomainMessenger(crossDomainMessengerAddr).sendMessage(
                parichayMantleAddr,
                message,
                1000000
            );
        } if (!condition && isMantle) {
            //update on mantle
            bytes memory message;

            message = abi.encodeWithSignature("updateExpiry(address)", user);

            ICrossDomainMessenger(crossDomainMessengerAddr).sendMessage(
                parichayMantleAddr,
                message,
                1000000
            );
        }
    }

    function isExpired(address _addr) public view returns (bool) {
        if (addressToExpiry[_addr] >= block.timestamp) {
            return false;
        }
        return true;
    }

    function updateExpiry(address _addr) internal {
        require(
            balanceOf(_addr) == 1,
            "For updating, you need to have your SBT on this chain."
        );
        addressToExpiry[_addr] = block.timestamp + 15780000;
    }

    function setMantleSBT(address _parichayMantleAddr) external onlyOwner {
        parichayMantleAddr = _parichayMantleAddr;
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
