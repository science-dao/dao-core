// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {CommonTypes} from "@filecoin/contracts/v0.8/types/CommonTypes.sol";
import {MarketTypes} from "@filecoin/contracts/v0.8/types/MarketTypes.sol";
import {FilAddresses} from "@filecoin/contracts/v0.8/utils/FilAddresses.sol";
import {MarketCBOR} from "@filecoin/contracts/v0.8/cbor/MarketCbor.sol";
import "./Structs.sol";
import "./Utils.sol";

contract DealProposalSerializer {
    function serializeDealProposal(Structs.DealRequest calldata deal) external view returns (bytes memory) {
        MarketTypes.DealProposal memory ret;
        ret.piece_cid = CommonTypes.Cid(deal.piece_cid);
        ret.piece_size = deal.piece_size;
        ret.verified_deal = deal.verified_deal;
        ret.client = Utils.getDelegatedAddress(address(this));
        // Set a dummy provider. The provider that picks up this deal will need to set its own address.
        ret.provider = FilAddresses.fromActorID(0);
        ret.label = CommonTypes.DealLabel(bytes(deal.label), true);
        ret.start_epoch = CommonTypes.ChainEpoch.wrap(deal.start_epoch);
        ret.end_epoch = CommonTypes.ChainEpoch.wrap(deal.end_epoch);
        ret.storage_price_per_epoch = Utils.uintToBigInt(
            deal.storage_price_per_epoch
        );
        ret.provider_collateral = Utils.uintToBigInt(deal.provider_collateral);
        ret.client_collateral = Utils.uintToBigInt(deal.client_collateral);

        return MarketCBOR.serializeDealProposal(ret);
    }
}