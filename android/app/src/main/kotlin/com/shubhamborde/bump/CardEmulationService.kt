package com.shubhamborde.bump

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import java.io.ByteArrayOutputStream

/**
 * NFC Host Card Emulation (HCE) service.
 *
 * Makes the phone behave as an NFC Type 4 Tag that contains an NDEF message
 * with a vCard.  When another phone (or NFC reader) taps this device, the
 * reader goes through the standard NDEF Type 4 Tag read sequence:
 *
 *   1. SELECT NDEF App  (AID D2760000850101)
 *   2. SELECT CC file   (E103)
 *   3. READ BINARY CC
 *   4. SELECT NDEF file (E104)
 *   5. READ BINARY NDEF (length prefix, then body)
 *
 * The vCard payload is set dynamically from Flutter via [NfcBridge].
 */
class CardEmulationService : HostApduService() {

    companion object {
        // Standard status words
        private val SW_OK      = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val SW_NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())
        private val SW_WRONG_P1P2 = byteArrayOf(0x6A.toByte(), 0x86.toByte())

        // File IDs
        private val CC_FILE_ID   = byteArrayOf(0xE1.toByte(), 0x03.toByte())
        private val NDEF_FILE_ID = byteArrayOf(0xE1.toByte(), 0x04.toByte())

        // NDEF Application AID
        private val NDEF_AID = byteArrayOf(
            0xD2.toByte(), 0x76.toByte(), 0x00.toByte(), 0x00.toByte(),
            0x85.toByte(), 0x01.toByte(), 0x01.toByte()
        )

        // Capability Container (CC) file — tells the reader about our NDEF file.
        // 15 bytes: CC length (000F), version (20), max read (00FF), max write (00FF),
        // NDEF TLV (04 06), NDEF file ID (E104), max size (1000 = 4096), read (00), write (FF).
        private val CC_FILE = byteArrayOf(
            0x00, 0x0F,                   // CC length = 15
            0x20,                         // Mapping version 2.0
            0x00, 0xFF.toByte(),          // Max R-APDU = 255
            0x00, 0xFF.toByte(),          // Max C-APDU = 255
            0x04, 0x06,                   // NDEF File Control TLV (tag, length)
            0xE1.toByte(), 0x04,          //   NDEF file ID
            0x10, 0x00,                   //   Max NDEF size = 4096
            0x00,                         //   Read access: free
            0xFF.toByte()                 //   Write access: denied
        )

        /** The NDEF file currently served. Set from Flutter via [NfcBridge]. */
        @Volatile
        var ndefFile: ByteArray = buildDefaultNdefFile()

        /**
         * Build an NDEF file (2-byte length prefix + NDEF message) from raw
         * vCard text.
         */
        fun setVCard(vcf: String) {
            ndefFile = buildNdefFileFromVCard(vcf)
        }

        /**
         * Build an NDEF file from a bump:// exchange URI.
         */
        fun setExchangeUri(uri: String) {
            ndefFile = buildNdefFileFromUri(uri)
        }

        // ---- internal NDEF builders ----

        private fun buildDefaultNdefFile(): ByteArray {
            return buildNdefFileFromUri("https://bump.app")
        }

        private fun buildNdefFileFromVCard(vcf: String): ByteArray {
            val payload = vcf.toByteArray(Charsets.UTF_8)
            // NDEF record: TNF=2 (media), type="text/vcard", payload=vcf
            val typeBytes = "text/vcard".toByteArray(Charsets.US_ASCII)
            val record = buildNdefRecord(0x02, typeBytes, payload, isFirstRecord = true, isLastRecord = true)
            return wrapInNdefFile(record)
        }

        private fun buildNdefFileFromUri(uri: String): ByteArray {
            // NDEF record: TNF=1 (well-known), type="U", payload=URI
            val typeBytes = byteArrayOf(0x55) // 'U'
            // URI identifier code 0x00 = no prefix
            val uriPayload = ByteArrayOutputStream()
            uriPayload.write(0x00) // no abbreviation
            uriPayload.write(uri.toByteArray(Charsets.UTF_8))
            val record = buildNdefRecord(0x01, typeBytes, uriPayload.toByteArray(), isFirstRecord = true, isLastRecord = true)
            return wrapInNdefFile(record)
        }

        private fun buildNdefRecord(tnf: Int, type: ByteArray, payload: ByteArray, isFirstRecord: Boolean, isLastRecord: Boolean): ByteArray {
            val out = ByteArrayOutputStream()
            var flag = tnf and 0x07
            if (isFirstRecord) flag = flag or 0x80  // MB
            if (isLastRecord)  flag = flag or 0x40  // ME
            val shortRecord = payload.size < 256
            if (shortRecord) flag = flag or 0x10     // SR
            out.write(flag)
            out.write(type.size)
            if (shortRecord) {
                out.write(payload.size)
            } else {
                out.write((payload.size shr 24) and 0xFF)
                out.write((payload.size shr 16) and 0xFF)
                out.write((payload.size shr 8) and 0xFF)
                out.write(payload.size and 0xFF)
            }
            out.write(type)
            out.write(payload)
            return out.toByteArray()
        }

        private fun wrapInNdefFile(ndefMessage: ByteArray): ByteArray {
            // NDEF file = 2-byte length + NDEF message bytes
            val out = ByteArrayOutputStream()
            out.write((ndefMessage.size shr 8) and 0xFF)
            out.write(ndefMessage.size and 0xFF)
            out.write(ndefMessage)
            return out.toByteArray()
        }
    }

    private enum class SelectedFile { NONE, CC, NDEF }
    private var selectedFile = SelectedFile.NONE

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        if (commandApdu.size < 4) return SW_NOT_FOUND

        val ins = commandApdu[1].toInt() and 0xFF
        val p1  = commandApdu[2].toInt() and 0xFF
        val p2  = commandApdu[3].toInt() and 0xFF

        return when (ins) {
            0xA4 -> handleSelect(commandApdu)
            0xB0 -> handleReadBinary(p1, p2, commandApdu)
            else -> SW_NOT_FOUND
        }
    }

    override fun onDeactivated(reason: Int) {
        selectedFile = SelectedFile.NONE
    }

    // ---- APDU handlers ----

    private fun handleSelect(apdu: ByteArray): ByteArray {
        if (apdu.size < 5) return SW_NOT_FOUND
        val lc = apdu[4].toInt() and 0xFF
        if (apdu.size < 5 + lc) return SW_NOT_FOUND
        val data = apdu.copyOfRange(5, 5 + lc)

        return when {
            data.contentEquals(NDEF_AID)     -> { selectedFile = SelectedFile.NONE; SW_OK }
            data.contentEquals(CC_FILE_ID)   -> { selectedFile = SelectedFile.CC;   SW_OK }
            data.contentEquals(NDEF_FILE_ID) -> { selectedFile = SelectedFile.NDEF; SW_OK }
            else -> SW_NOT_FOUND
        }
    }

    private fun handleReadBinary(p1: Int, p2: Int, apdu: ByteArray): ByteArray {
        val offset = (p1 shl 8) or p2
        val le = if (apdu.size >= 5) apdu[4].toInt() and 0xFF else 0

        val fileData = when (selectedFile) {
            SelectedFile.CC   -> CC_FILE
            SelectedFile.NDEF -> ndefFile
            else -> return SW_NOT_FOUND
        }

        if (offset >= fileData.size) return SW_WRONG_P1P2

        val end = minOf(offset + (if (le == 0) 256 else le), fileData.size)
        val chunk = fileData.copyOfRange(offset, end)

        return chunk + SW_OK
    }
}
