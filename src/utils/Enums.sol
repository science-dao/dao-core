// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum Status {
    None,
    RequestSubmitted,
    DealPublished,
    DealActivated,
    DealTerminated
}

enum ResearchVote {
    FOR, // accept the result of research
    AGAINST, // deny the result of research
    EXTEND // request more work from researchers
}

enum ResearchState {
    FUNDING,
    IN_PROGRESS,
    EXPIRED,
    VOTING,
    SUCCESSFUL,
    FAILED
}

enum InvestmentState {
    INVESTED,
    REFUNDED
}