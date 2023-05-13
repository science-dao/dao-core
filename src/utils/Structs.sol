// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Enums.sol";

library Structs {
    // Extra parameters associated with the deal request. These are off-protocol flags that
    // the storage provider will need.
    struct ExtraParamsV1 {
        string location_ref;
        uint64 car_size;
        bool skip_ipni_announce;
        bool remove_unsealed_copy;
    }

    // User request for this contract to make a deal. This structure is modelled after Filecoin's Deal
    // Proposal, but leaves out the provider, since any provider can pick up a deal broadcast by this
    // contract.
    struct DealRequest {
        bytes piece_cid;
        uint64 piece_size;
        bool verified_deal;
        string label;
        int64 start_epoch;
        int64 end_epoch;
        uint256 storage_price_per_epoch;
        uint256 provider_collateral;
        uint256 client_collateral;
        string dataCid;
        uint64 extra_params_version;
        ExtraParamsV1 extra_params;
    }

    struct RequestId {
        bytes32 requestId;
        bool valid;
    }

    // request index
    struct RequestIdx {
        uint256 idx;
        bool valid;
    }

    struct DataCid {
        string cid;
        bool isActive;
    }

    struct ProviderSet {
        bytes provider;
        bool valid;
    }

    struct FundingDuration {
        uint256 minFundingDuration;
        uint256 maxFundingDuration;
    }

    struct ResearchProposal {
        bytes32 id;
        address creator;
        ResearchState state;
        string title;
        string descriptionUrl;
        address fundingToken;
        uint256 fundingAmount;
        uint256 fundingDuration;
        uint256 researchDuration;
        uint256 fundingStartedAt;
        uint256 researchStartedAt;
        uint256 amountInvested;
        uint256[] investorTokens;
    }

    struct InvestorTokenMetadata {
        address dao;
        address owner;
        InvestmentState state;
        bytes32 proposalId;
        address token;
        uint256 amount;
        uint256 timestamp;
    }

    struct ResearchVoteResult {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 extendVotes;
        uint256 votingStarted;
        mapping(address => bool) hasVoted;
    }

    struct Research {
        bytes32 dealId;
        address uploader;
        string cid;
        string title;
        string description;
        uint256 price;
    }

    struct AccessTokenMetadata {
        address dao;
        address owner;
        string cid;
    }
}
