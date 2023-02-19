// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {IConnext} from "@connext/smart-contracts/contracts/core/connext/interfaces/IConnext.sol";
import "./lib/GenesisUtils.sol";
import "./interfaces/ICircuitValidator.sol";
import "./verifiers/ZKPVerifier.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract parichaySBT is ERC721, ERC721Burnable, ZKPVerifier {
    IConnext public immutable connext;

    using Counters for Counters.Counter;
    uint64 public constant TRANSFER_REQUEST_ID = 1;
    uint64 public constant UPDATE_REQUEST_ID = 2;
    Counters.Counter private _tokenIdCounter;

    mapping(address => uint256) public addressToExpiry;
    // mapping(uint256 => address) public idToAddress;
    mapping(address => uint256) public addressToTokenId;

    constructor(address _connext) ERC721("Parichay", "PSBT") {
        connext = IConnext(_connext);
    }

    function _beforeProofSubmit(
        uint64, /* requestId */
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal view override {
        // check that challenge input of the proof is equal to the msg.sender
        address addr = GenesisUtils.int256ToAddress(
            inputs[validator.getChallengeInputIndex()]
        );
        require(
            _msgSender() == addr,
            "address in proof is not a sender"
        );
    }

    function _afterProofSubmit(
        uint64 _requestId,
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal override {
        if (_requestId == TRANSFER_REQUEST_ID){
            require(balanceOf(_msgSender()) == 0, "error2");
            safeMint();
            addressToExpiry[_msgSender()] = block.timestamp + 15780000;
        } if(_requestId == UPDATE_REQUEST_ID){
            updateExpiry(_msgSender());
        }
    }

    function safeMint() internal {
        require(balanceOf(_msgSender()) == 0);

        if(addressToTokenId[_msgSender()] == 0){
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            addressToTokenId[_msgSender()] = tokenId;
            _safeMint(_msgSender(), tokenId);
        }
        else{
            _safeMint(_msgSender(), addressToTokenId[_msgSender()]);
            updateExpiry(_msgSender());
        }
    }

    function xPort(
        address target,
        uint32 destinationDomain,
        uint256 relayerFee,
        bool isMantle
    ) external payable {
        require(balanceOf(_msgSender()) == 1);
        bool isPort = true;
        burn(addressToTokenId[_msgSender()]);
        
            bytes memory callData = abi.encode(
                _msgSender(),
                addressToTokenId[_msgSender()],
                addressToExpiry[_msgSender()],
                isPort,
                isMantle
            );

            connext.xcall{value: relayerFee}(
                destinationDomain, 
                target,
                address(0), 
                msg.sender, 
                0,
                0, 
                callData 
            );
        }

    function xUpdateExpiry(address target,
        uint32 destinationDomain,
        uint256 relayerFee,
        bool isMantle
        ) external payable {
            require(balanceOf(_msgSender()) == 1);
            bool isPort = false;

            bytes memory callData = abi.encode(
                _msgSender(),
                addressToTokenId[_msgSender()],
                addressToExpiry[_msgSender()],
                isPort,
                isMantle
            );

            connext.xcall{value: relayerFee}(
                destinationDomain, // _destination: Domain ID of the destination chain
                target, // _to: address of the target contract
                address(0), // _asset: use address zero for 0-value transfers
                msg.sender, // _delegate: address that can revert or forceLocal on destination
                0, // _amount: 0 because no funds are being transferred
                0, // _slippage: can be anything between 0-10000 because no funds are being transferred
                callData // _callData: the encoded calldata to send
            );

    }

    function xClone(
        address target,
        uint32 destinationDomain,
        uint256 relayerFee,
        bool isMantle
    ) external payable {

        require(balanceOf(_msgSender()) == 1);
        bool isPort = true;
        bytes memory callData = abi.encode(
            _msgSender(),
            addressToTokenId[_msgSender()],
            addressToExpiry[_msgSender()],
            isPort,
            isMantle
        );

            connext.xcall{value: relayerFee}(
                destinationDomain, // _destination: Domain ID of the destination chain
                target, // _to: address of the target contract
                address(0), // _asset: use address zero for 0-value transfers
                msg.sender, // _delegate: address that can revert or forceLocal on destination
                0, // _amount: 0 because no funds are being transferred
                0, // _slippage: can be anything between 0-10000 because no funds are being transferred
                callData // _callData: the encoded calldata to send
            );
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
            "For updating, you need to have your SBT"
        );
        addressToExpiry[_addr] = block.timestamp + 15780000;
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
