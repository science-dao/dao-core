// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../utils/Structs.sol";

interface IUtils {
    function serializeDealProposal(Structs.DealRequest calldata deal) external view returns (bytes memory);
    function serializeExtraParamsV1(Structs.ExtraParamsV1 memory params) external pure returns (bytes memory);
}