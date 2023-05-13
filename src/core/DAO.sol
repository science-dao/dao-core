// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../token/MemberToken.sol";
import "../token/InvestorToken.sol";
import "../token/AccessToken.sol";
import "../utils/Structs.sol";
import "../interfaces/IStorage.sol";
import "../utils/Enums.sol";

contract DAO {
    address public governance;
    MemberToken public membershipToken;
    InvestorToken public investorToken;
    AccessToken public accessToken;

    Structs.FundingDuration public fundingDuration;
    IStorage public daoStorage;

    uint256 public fundingResultVoteTimeframe;

    constructor(
        address _governance,
        MemberToken _membershipToken,
        InvestorToken _investorToken,
        AccessToken _accessToken,
        Structs.FundingDuration memory _fundingDuration,
        IStorage _storage
    ) {
        governance = _governance;
        membershipToken = _membershipToken;
        investorToken = _investorToken;
        accessToken = _accessToken;
        fundingDuration = _fundingDuration;
        daoStorage = _storage;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance can call");
        _;
    }

    modifier onlyMember() {
        require(
            MemberToken(membershipToken).balanceOf(msg.sender) == 1,
            "Only DAO member can call"
        );
        _;
    }

    function setFundingDuration(
        Structs.FundingDuration calldata _fundingDuration
    ) external onlyGovernance {
        require(
            _fundingDuration.minFundingDuration > 0 &&
                _fundingDuration.minFundingDuration <
                _fundingDuration.maxFundingDuration,
            "Invalid voting duration"
        );
        fundingDuration = _fundingDuration;
    }

    function setFundingResultVoteTimeframe(uint256 _fundingResultVoteTimeframe) external onlyGovernance {
        fundingResultVoteTimeframe = _fundingResultVoteTimeframe;
    }

    // TODO: Custom proposals & votes for:
    //    - funding proposal
    //    - accepting result of research
    //    - adding new members
    function createFundingProposal(
        string calldata _title,
        string calldata _descriptionUrl,
        address _fundingToken,
        uint256 _fundingAmount,
        uint256 _fundingDuration,
        uint256 _researchDuration
    ) external onlyMember {
        // check that token is supported
        require(
            daoStorage.isTokenSupported(_fundingToken),
            "Unsupported token"
        );

        // check voting duration
        require(
            _fundingDuration > fundingDuration.minFundingDuration &&
                _fundingDuration < fundingDuration.maxFundingDuration,
            "Invalid voting duration"
        );

        bytes32 id = keccak256(
            abi.encodePacked(
                _title,
                _descriptionUrl,
                _fundingToken,
                _fundingAmount,
                _fundingDuration,
                _researchDuration
            )
        );

        uint256[] memory _investors;
        Structs.ResearchProposal memory _researchProposal = Structs
            .ResearchProposal(
                id,
                msg.sender,
                ResearchState.FUNDING,
                _title,
                _descriptionUrl,
                _fundingToken,
                _fundingAmount,
                _fundingDuration,
                _researchDuration,
                block.timestamp,
                0,
                0,
                _investors
            );

        daoStorage.setResearchProposal(_researchProposal);
    }

    function fundResearchProposal(
        bytes32 _proposalId,
        uint256 _investedAmount
    ) external {
        Structs.ResearchProposal memory _researchProposal = daoStorage
            .getResearchProposal(_proposalId);
        // check that proposal exists
        require(_researchProposal.id == _proposalId, "Invalid proposal id");

        // check that state is in progress
        require(
            _researchProposal.state == ResearchState.FUNDING,
            "Funding proposal is not in progress"
        );

        // check that funding proposal hasn't expired yet
        uint256 _fundingExpirationTstamp = _researchProposal.fundingStartedAt +
            _researchProposal.fundingDuration;
        require(
            _fundingExpirationTstamp < block.timestamp,
            "Funding proposal expired"
        );

        uint256 newInvestedAmount = _researchProposal.amountInvested +
            _investedAmount;

        // check that amount invested hasn't been reached yet
        require(
            newInvestedAmount <= _researchProposal.fundingAmount,
            "Trying to invest too much"
        );

        // transfer tokens from investor to DAO
        IERC20(_researchProposal.fundingToken).transferFrom(msg.sender, address(this), _investedAmount);

        // increase funding for proposal
        daoStorage.updateResearchProposalInvestedAmount(_proposalId, newInvestedAmount);

        // check whether funding goal has been reached
        // if yes update state to successful
        if (newInvestedAmount == _researchProposal.fundingAmount) {
            daoStorage.updateResearchProposalState(_proposalId, ResearchState.SUCCESSFUL);
        }

        // mint SBT to investor
        uint256 _tokenId = investorToken.mint(msg.sender, _proposalId, _researchProposal.fundingToken, _investedAmount);

        // add investor to proposal
        daoStorage.addInvestorTokenToProposal(_proposalId, _tokenId);
    }

    // starts the research - only creator can call
    function startResearch(bytes32 _proposalId) external {
        // get proposal
        Structs.ResearchProposal memory _researchProposal = daoStorage.getResearchProposal(_proposalId);

        // check that proposal exists
        require(_researchProposal.id == _proposalId, "Proposal does not exist");

        // check that caller is the proposal creator
        require(msg.sender == _researchProposal.creator, "Only proposal creator can call");
        
        // check that funding amount has been reached
        require(_researchProposal.fundingAmount == _researchProposal.amountInvested, "Target funding has not been reach");

        // start research
        daoStorage.startResearch(_proposalId);
    }

    // if research expired anyone can call & investors get their money back
    function resetExpiredResearchProposal(bytes32 _proposalId) external {
        // get proposal
        Structs.ResearchProposal memory _researchProposal = daoStorage.getResearchProposal(_proposalId);

        // check that it exists
        require(_researchProposal.id == _proposalId, "Proposal does not exist");

        // check that time limit expired
        require(block.timestamp > _researchProposal.fundingStartedAt + _researchProposal.fundingDuration, "Proposal has not expired yet");

        // check that funding has not been reached
        require(_researchProposal.amountInvested < _researchProposal.fundingAmount, "Proposal was successfully completed already");

        // update state to expired
        daoStorage.updateResearchProposalState(_proposalId, ResearchState.EXPIRED);

        // refund investors the tokens
        uint256[] memory _investorTokens = daoStorage.getInvestorTokensForProposal(_proposalId);
        for (uint256 i = 0; i < _investorTokens.length; i++) {
            // get token for investor
            uint256 _tokenId = _investorTokens[i];
            Structs.InvestorTokenMetadata memory _metadata = investorToken.getTokenMetadata(_tokenId);
            // transfer the tokens back to the investor 
            IERC20(_metadata.token).transfer(_metadata.owner, _metadata.amount);

            // update state to refunded
            investorToken.refundInvestment(_tokenId);
        }
    }

    function startVotingOnResearchResult(bytes32 _proposalId) external {
        // get proposal
        Structs.ResearchProposal memory _researchProposal = daoStorage.getResearchProposal(_proposalId);

        // check that it exists
        require(_researchProposal.id == _proposalId, "Proposal does not exist");

        // check that state is in progress
        require(_researchProposal.state == ResearchState.IN_PROGRESS, "Invalid state");

        // check that research timeframe has completed
        require(block.timestamp > _researchProposal.researchStartedAt + _researchProposal.researchDuration, "Research period is not over");

        daoStorage.updateResearchProposalState(_proposalId, ResearchState.VOTING);
    }

    function voteOnResearchResult(
        bytes32 _proposalId,
        ResearchVote vote
    ) external {
        Structs.ResearchProposal memory _researchProposal = daoStorage.getResearchProposal(_proposalId);
        // check that proposal exists
        require(_researchProposal.id != 0, "Proposal doesn't exist");

        // check that state is voting
        require(_researchProposal.state == ResearchState.VOTING, "Voting is not open");

        // TODO check that address can vote

        daoStorage.voteOnResearch(_proposalId, msg.sender, vote);
    }

    function setResearchDeal(bytes32 _id, string calldata _title, string calldata _description, uint256 _price) external {
        Structs.Research memory _research = daoStorage.researchDeals(_id);
        require(_research.uploader == msg.sender, "Only uploader can set research deal");

        Structs.RequestIdx memory _idx = daoStorage.dealRequestIdx(_id);
        Structs.DealRequest memory _dealRequest = daoStorage.dealRequests(_idx.idx);
        
        _research.cid = _dealRequest.dataCid;
        _research.title = _title;
        _research.description = _description;
        _research.price = _price;

        daoStorage.setResearchDeal(_id, _research);
    }

    function buyResearchDeal(bytes32 _id) external payable {
        Structs.Research memory _research = daoStorage.researchDeals(_id);

        // check that exists
        require(_research.dealId == _id, "Research deal doesn't exist");

        // check that msg.value == price
        require(msg.value == _research.price, "Invalid amount sent");

        // mint access SBT
        accessToken.mint(msg.sender, _research.cid);
    } 
}
