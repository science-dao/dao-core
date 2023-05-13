// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../utils/Structs.sol";
import "../utils/Enums.sol";

interface IStorage {
    function isTokenSupported(address _token) external view returns (bool);
    function setResearchProposal(Structs.ResearchProposal calldata proposal) external;
    function getResearchProposal(bytes32 proposalId) external view returns (Structs.ResearchProposal memory);
    function updateResearchProposalInvestedAmount(bytes32 _proposalId, uint256 amount) external;
    function updateResearchProposalState(bytes32 _proposalId, ResearchState _state) external;
    function startResearch(bytes32 _proposalId) external;
    function addInvestorTokenToProposal(bytes32 _proposalId, uint256 _tokenId) external;
    function getInvestorTokensForProposal(bytes32 _proposalId) external view returns (uint256[] memory);
    function voteOnResearch(bytes32 _proposalId, address account, ResearchVote vote) external;
    function researchDeals(bytes32 _id) external view returns (Structs.Research memory);
    function dealRequestIdx(bytes32 _id) external view returns (Structs.RequestIdx memory);
    function dealRequests(uint256 _idx) external view returns (Structs.DealRequest memory);
    function setResearchDeal(bytes32 _id, Structs.Research calldata _researchDeal) external;
}