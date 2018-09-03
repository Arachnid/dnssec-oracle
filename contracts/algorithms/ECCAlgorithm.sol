pragma solidity ^0.4.23;

import "./Algorithm.sol";
import "./CurveInterface.sol";
import "../BytesUtils.sol";

//   o  DNSKEY and RRSIG RRs signifying ECDSA with the P-256 curve and
//      SHA-256 use the algorithm number 13.
contract ECCAlgorithm is Algorithm {

    using BytesUtils for *;

    CurveInterface public curve;

    constructor(CurveInterface _curve) public {
        curve = _curve;
    }

    function verify(bytes key, bytes data, bytes signature) external view returns (bool) {
        curve.validateSignature(data.readBytes32(0), parse(signature), parse(key));
    }

    function parse(bytes data) internal view returns (uint256[2]) {
        return [data.readUint256(0), data.readUint256(32)];
    }

}