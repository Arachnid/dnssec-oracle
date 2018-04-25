pragma solidity ^0.4.17;

import "./BytesUtils.sol";
import "./Buffer.sol";

library RRUtils {
    using BytesUtils for *;
    using Buffer for *;

    /**
     * @dev Returns the number of bytes in the DNS name at 'offset' in 'self'.
     * @param self The byte array to read a name from.
     * @param offset The offset to start reading at.
     * @return The length of the DNS name at 'offset', in bytes.
     */
    function nameLength(bytes memory self, uint offset) internal pure returns(uint) {
        uint idx = offset;
        while (true) {
            assert(idx < self.length);
            uint labelLen = self.readUint8(idx);
            idx += labelLen + 1;
            if (labelLen == 0) break;
        }
        return idx - offset;
    }

    /**
     * @dev Returns the number of labels in the DNS name at 'offset' in 'self'.
     * @param self The byte array to read a name from.
     * @param offset The offset to start reading at.
     * @return The number of labels in the DNS name at 'offset', in bytes.
     */
    function labelCount(bytes memory self, uint offset) internal pure returns(uint) {
        uint count = 0;
        while (true) {
            assert(offset < self.length);
            uint labelLen = self.readUint8(offset);
            offset += labelLen + 1;
            if (labelLen == 0) break;
            count += 1;
        }
        return count;
    }

    /**
     * @dev Reads a resource record from a byte string.
     * @param self The byte string to read from.
     * @param off The offset to start reading at.
     * @return dnstype The DNS type ID for the RR.
     * @return class The DNS class ID for the RR.
     * @return ttl The TTL for the RR.
     * @return rdataOffset The offset from the start of the byte array to the RR's RDATA.
     * @return next The offset to the start of the next record (if any).
     */
    function readRR(bytes memory self, uint off) internal pure returns (uint16 dnstype, uint16 class, uint32 ttl, uint rdataOffset, uint next) {
        if (off >= self.length) {
            return (0, 0, 0, 0, 0);
        }

        // Skip the name
        off += nameLength(self, off);

        // Read type, class, and ttl
        dnstype = self.readUint16(off); off += 2;
        class = self.readUint16(off); off += 2;
        ttl = self.readUint32(off); off += 4;

        // Read the rdata
        uint rdataLength = self.readUint16(off); off += 2;
        rdataOffset = off;
        next = off + rdataLength;
    }

    /**
     * @dev Checks if a given RR type exists in a type bitmap.
     * @param self The byte string to read the type bitmap from.
     * @param offset The offset to start reading at.
     * @param rrtype The RR type to check for.
     * @return True if the type is found in the bitmap, false otherwise.
     */
    function checkTypeBitmap(bytes memory self, uint offset, uint16 rrtype) internal pure returns (bool) {
        uint8 typeWindow = uint8(rrtype >> 8);
        uint8 windowByte = uint8((rrtype & 0xff) / 8);
        uint8 windowBitmask = uint8(1 << (7 - (rrtype & 0x7)));
        for(uint off = 0; off < self.length;) {
            uint8 window = self.readUint8(off);
            uint8 len = self.readUint8(off + 1);
            if(typeWindow < window) {
                // We've gone past our window; it's not here.
                return false;
            } else if(typeWindow == window) {
                // Check this type bitmap
                if(len * 8 <= windowByte) {
                    // Our type is past the end of the bitmap
                    return false;
                }

                return (self.readUint8(off + windowByte + 2) & windowBitmask) != 0;
            } else {
                // Skip this type bitmap
                off += len + 2;
            }
        }

        return false;
    }
}
