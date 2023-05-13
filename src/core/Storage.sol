// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../utils/Structs.sol";
import "../utils/Enums.sol";
import "../interfaces/IUtils.sol";

contract Storage {
    mapping(bytes32 => Structs.RequestIdx) public dealRequestIdx; // contract deal id -> deal index
    Structs.DealRequest[] public dealRequests;

    mapping(bytes => Structs.RequestId) public pieceRequests; // commP -> dealProposalID
    mapping(bytes => Structs.ProviderSet) public pieceProviders; // commP -> provider
    mapping(bytes => uint64) public pieceDeals; // commP -> deal ID
    mapping(bytes => Status) public pieceStatus;

    string[] activeCids; // data cids
    mapping(address => uint256[]) cidIdxs; // data cid indexes per member

    // array for address containing papers: title, description URL, CID, price
    bytes32[] public dealIds;
    mapping(bytes32 => Structs.Research) public researchDeals;

    mapping(address => uint256) public filDeposits;

    mapping(bytes32 => Structs.ResearchProposal) public researchProposals;

    mapping(address => bool) public supportedTokens;

    mapping(bytes32 => Structs.ResearchVoteResult) private _researchVoteResults;

    address client;
    address dao;
    address governance;
    IUtils utils;

    constructor(address _governance, IUtils _utils) {
        governance = _governance;
        utils = _utils;
    }

    modifier authorize() {
        require(msg.sender == client || msg.sender == dao, "Unauthorized");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance can call");
        _;
    }

    function setAuth(address _client, address _dao) external {
        require(client == address(0) && dao == address(0), "Already set");
        client = _client;
        dao = _dao;
    }

    function getProviderSet(
        bytes calldata cid
    ) public view returns (Structs.ProviderSet memory) {
        return pieceProviders[cid];
    }

    function getProposalIdSet(
        bytes calldata cid
    ) public view returns (Structs.RequestId memory) {
        return pieceRequests[cid];
    }

    function dealsLength() public view returns (uint256) {
        return dealRequests.length;
    }

    function getDealByIndex(
        uint256 index
    ) public view returns (Structs.DealRequest memory) {
        return dealRequests[index];
    }

    // helper function to get deal request based from id
    function getDealRequest(
        bytes32 requestId
    ) public view returns (Structs.DealRequest memory) {
        Structs.RequestIdx memory ri = dealRequestIdx[requestId];
        require(ri.valid, "proposalId not available");
        return dealRequests[ri.idx];
    }

    function getDealRequestsLength() external view returns (uint256) {
        return dealRequests.length;
    }

    function addDealRequest(Structs.DealRequest calldata deal) external {
        dealRequests.push(deal);
    }

    function setDealRequestIdx(bytes32 id, uint256 index, address uploader) external authorize {
        dealRequestIdx[id] = Structs.RequestIdx(index, true);
        dealIds.push(id);
        researchDeals[id] = Structs.Research(id, uploader, "", "", "", 0);
    }

    function setResearchDeal(bytes32 _id, Structs.Research calldata _researchDeal) external authorize {
        researchDeals[_id] = _researchDeal;
    }

    function setPieceRequest(
        bytes calldata pieceCid,
        bytes32 requestId
    ) external authorize {
        pieceRequests[pieceCid] = Structs.RequestId(requestId, true);
    }

    function setPieceStatus(
        bytes calldata pieceCid,
        Status status
    ) external authorize {
        pieceStatus[pieceCid] = status;
    }

    function setPieceProvider(
        bytes calldata cid,
        Structs.ProviderSet calldata pieceProvider
    ) external authorize {
        pieceProviders[cid] = pieceProvider;
    }

    function setPieceDeal(
        bytes calldata cid,
        uint64 dealId
    ) external authorize {
        pieceDeals[cid] = dealId;
    }

    function setFilDeposit(address user, uint256 amount) external authorize {
        filDeposits[user] = amount;
    }

    function getActiveCids() public view returns (string[] memory) {
        return activeCids;
    }

    function getActiveCidsLength() public view returns (uint256) {
        return activeCids.length;
    }

    function activateCid(bytes calldata pieceCid) external authorize {
        Structs.RequestId memory reqId = pieceRequests[pieceCid];
        Structs.RequestIdx memory reqIdx = dealRequestIdx[reqId.requestId];
        Structs.DealRequest memory req = dealRequests[reqIdx.idx];
        activeCids.push(req.dataCid);
    }

    function getExtraParams(
        bytes32 proposalId
    ) public view returns (bytes memory extra_params) {
        Structs.DealRequest memory deal = getDealRequest(proposalId);
        return utils.serializeExtraParamsV1(deal.extra_params);
    }

    // Returns a CBOR-encoded DealProposal.
    function getDealProposal(
        bytes32 proposalId
    ) public view returns (bytes memory) {
        Structs.DealRequest memory deal = getDealRequest(proposalId);
        return utils.serializeDealProposal(deal);
    }

    function getResearchProposal(
        bytes32 proposalId
    ) external view returns (Structs.ResearchProposal memory) {
        return researchProposals[proposalId];
    }

    function setResearchProposal(
        Structs.ResearchProposal calldata proposal
    ) external authorize {
        Structs.ResearchProposal memory r = researchProposals[proposal.id];
        require(r.id == 0, "Proposal already exists");
        researchProposals[proposal.id] = proposal;
    }

    function updateResearchProposalInvestedAmount(bytes32 _proposalId, uint256 _amount) external authorize {
        Structs.ResearchProposal memory r = researchProposals[_proposalId];
        require(r.id != 0, "Proposal doesn't exist");
        r.amountInvested = _amount;
        researchProposals[_proposalId] = r;
    }

    function updateResearchProposalState(bytes32 _proposalId, ResearchState _state) external authorize {
        Structs.ResearchProposal memory r = researchProposals[_proposalId];
        require(r.id != 0, "Proposal doesn't exist");
        r.state = _state;
        researchProposals[_proposalId] = r;   
    }

    function startResearch(bytes32 _proposalId) external authorize {
        Structs.ResearchProposal memory r = researchProposals[_proposalId];
        require(r.id != 0, "Proposal doesn't exist");
        r.state = ResearchState.IN_PROGRESS;
        r.researchStartedAt = block.timestamp;
        researchProposals[_proposalId] = r;
    }

    function startVotingOnResearchResult(bytes32 _proposalId) external authorize {
        Structs.ResearchVoteResult storage _researchVoteResult = _researchVoteResults[_proposalId];
        _researchVoteResult.votingStarted = block.timestamp;
    }

    function supportToken(address _token) external onlyGovernance {
        supportedTokens[_token] = true;
    }

    function removeToken(address _token) external onlyGovernance {
        supportedTokens[_token] = false;
    }

    function isTokenSupported(address _token) external view returns (bool) {
        return supportedTokens[_token];
    }

    function addInvestorTokenToProposal(bytes32 _proposalId, uint256 _tokenId) external authorize {
        Structs.ResearchProposal storage r = researchProposals[_proposalId];
        require(r.id != 0, "Proposal doesn't exist");
        r.investorTokens.push(_tokenId);
        researchProposals[_proposalId] = r;
    }

    function getInvestorTokensForProposal(bytes32 _proposalId) external view returns (uint256[] memory) {
        Structs.ResearchProposal memory r = researchProposals[_proposalId];
        require(r.id != 0, "Proposal doesn't exist");
        return r.investorTokens;
    }

    function voteOnResearch(bytes32 _proposalId, address account, ResearchVote vote) external authorize {
        Structs.ResearchVoteResult storage _researchVoteResult = _researchVoteResults[_proposalId];
        require(!_researchVoteResult.hasVoted[account], "Vote already cast");

        _researchVoteResult.hasVoted[account] = true;

        if (vote == ResearchVote.FOR) {
            _researchVoteResult.forVotes += 1;
        } else if (vote == ResearchVote.AGAINST) {
            _researchVoteResult.againstVotes += 1;
        } else if (vote == ResearchVote.EXTEND) {
            _researchVoteResult.extendVotes += 1;
        }
    }
}
