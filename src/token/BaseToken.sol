// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BaseToken is ERC721 {
    uint256 public tokenCount;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {}

    function _transfer(
        address /* from */,
        address /* to */,
        uint256 /* tokenId */
    ) internal virtual override {
        revert();
    }

    function mint(address to) external virtual {
        require(balanceOf(to) == 0, "Address is already a member");
        tokenCount++;
        _mint(to, tokenCount);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token has not been minted yet");
        return super.tokenURI(tokenId);
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {}

    function _formatTokenURI(
        bytes32 _proposalId,
        address _token,
        uint256 _amount,
        uint256 _tstamp
    ) internal view virtual returns (string memory) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
