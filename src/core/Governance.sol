// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "../token/MemberToken.sol";

contract Governance is
    Governor,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction
{
    address public membershipToken;

    constructor(
        string memory _name,
        IVotes _token
    ) Governor(_name) GovernorVotes(_token) GovernorVotesQuorumFraction(51) {
        membershipToken = address(_token);
    }

    modifier onlyMember() {
        require(MemberToken(membershipToken).balanceOf(msg.sender) == 1, "Only DAO member can call");
        _;
    }

    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    // TODO: Voting period has to be set on a per proposal basis
    function votingPeriod() public pure override returns (uint256) {
        return 50400; // 1 week
    }

    // The following functions are overrides required by Solidity.
    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    // adds a new member to the DAO
    function addMember(address _newMember) public onlyGovernance {
        MemberToken(membershipToken).mint(_newMember);
    }

}
