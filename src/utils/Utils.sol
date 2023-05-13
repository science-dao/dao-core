// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {CommonTypes} from "@filecoin/contracts/v0.8/types/CommonTypes.sol";
import {BigIntCBOR} from "@filecoin/contracts/v0.8/cbor/BigIntCbor.sol";
import {CBORDecoder} from "@filecoin/contracts/v0.8/utils/CborDecode.sol";
import {AccountTypes} from "@filecoin/contracts/v0.8/types/AccountTypes.sol";
import {MarketTypes} from "@filecoin/contracts/v0.8/types/MarketTypes.sol";
import {MarketCBOR} from "@filecoin/contracts/v0.8/cbor/MarketCbor.sol";
import {FilAddresses} from "@filecoin/contracts/v0.8/utils/FilAddresses.sol";
import "@solidity-cborutils/contracts/CBOR.sol";
import "@solidity-bignumber/src/BigNumbers.sol";
import "./Structs.sol";
import "./Constants.sol";
import "./Errors.sol";

library Utils {
    using CBOR for CBOR.CBORBuffer;
    using CBORDecoder for bytes;
    using BigIntCBOR for CommonTypes.BigInt;
    using BigIntCBOR for bytes;

    // TODO: Below 2 funcs need to go to filecoin.sol
    function uintToBigInt(
        uint256 value
    ) public view returns (CommonTypes.BigInt memory) {
        BigNumber memory bigNumVal = BigNumbers.init(value, false);
        CommonTypes.BigInt memory bigIntVal = CommonTypes.BigInt(
            bigNumVal.val,
            bigNumVal.neg
        );
        return bigIntVal;
    }

    function bigIntToUint(
        CommonTypes.BigInt memory bigInt
    ) public view returns (uint256) {
        BigNumber memory bigNumUint = BigNumbers.init(bigInt.val, bigInt.neg);
        uint256 bigNumExtractedUint = uint256(bytes32(bigNumUint.val));
        return bigNumExtractedUint;
    }

    // TODO fix in filecoin-solidity. They're using the wrong hex value.
    function getDelegatedAddress(
        address addr
    ) public pure returns (CommonTypes.FilAddress memory) {
        return CommonTypes.FilAddress(abi.encodePacked(hex"040a", addr));
    }

    function serializeExtraParamsV1(
        Structs.ExtraParamsV1 memory params
    ) public pure returns (bytes memory) {
        CBOR.CBORBuffer memory buf = CBOR.create(64);
        buf.startFixedArray(4);
        buf.writeString(params.location_ref);
        buf.writeUInt64(params.car_size);
        buf.writeBool(params.skip_ipni_announce);
        buf.writeBool(params.remove_unsealed_copy);
        return buf.data();
    }

    function serializeDealProposal(Structs.DealRequest calldata deal) external view returns (bytes memory) {
        MarketTypes.DealProposal memory ret;
        ret.piece_cid = CommonTypes.Cid(deal.piece_cid);
        ret.piece_size = deal.piece_size;
        ret.verified_deal = deal.verified_deal;
        ret.client = getDelegatedAddress(address(this));
        // Set a dummy provider. The provider that picks up this deal will need to set its own address.
        ret.provider = FilAddresses.fromActorID(0);
        ret.label = CommonTypes.DealLabel(bytes(deal.label), true);
        ret.start_epoch = CommonTypes.ChainEpoch.wrap(deal.start_epoch);
        ret.end_epoch = CommonTypes.ChainEpoch.wrap(deal.end_epoch);
        ret.storage_price_per_epoch = uintToBigInt(
            deal.storage_price_per_epoch
        );
        ret.provider_collateral = uintToBigInt(deal.provider_collateral);
        ret.client_collateral = uintToBigInt(deal.client_collateral);

        return MarketCBOR.serializeDealProposal(ret);
    }
}