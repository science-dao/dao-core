// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../utils/Base64.sol";
import "./BaseToken.sol";
import "../utils/Structs.sol";

contract AccessToken is BaseToken {
    using Strings for uint256;

    address public DAO;

    // mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => Structs.AccessTokenMetadata) tokenMetadatas; // mapping from token id to metadata

    modifier onlyDao() {
        require(msg.sender == DAO, "Only DAO can call");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_
    ) BaseToken(name_, symbol_) {}

    function mint(address /* to */) external pure override {
        revert();
    }

    function mint(address _to, string calldata _cid) external onlyDao returns (uint256) {
        tokenCount++;

        string memory tokenUri = _formatTokenURI(_to, _cid);

        Structs.AccessTokenMetadata memory _metadata = Structs.AccessTokenMetadata(DAO, _to, _cid);

        _mint(_to, tokenCount);

        _setTokenURI(tokenCount, tokenUri);

        tokenMetadatas[tokenCount] = _metadata;

        return tokenCount;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token has not been minted yet");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function getTokenMetadata(
        uint256 _tokenId
    ) external view returns (Structs.AccessTokenMetadata memory) {
        return tokenMetadatas[_tokenId];
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual override {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _formatTokenURI(
        address _to,
        string calldata _cid
    ) internal view returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{name: "DeSci Access Token", description: "This token grants access to scientific research.", "owner": "',
                                Strings.toHexString(uint256(uint160(_to)), 20),
                                '", DAO: "',
                                Strings.toHexString(uint256(uint160(DAO)), 20),
                                '", data_cid: "',
                                _cid,
                                '"}'
                            )
                        )
                    )
                )
            )
        );
    }
}
