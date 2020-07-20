package de.mintware.barcode_scan.scanner

import android.os.Parcelable
import kotlinx.android.parcel.Parcelize

@Parcelize
data class StorageResult(val code:String,val operationType:Int) : Parcelable {

    companion object{
        const val OPERATION_TYPE_SCANNER = 0
        const val OPERATION_TYPE_INPUT = 1
        const val OPERATION_TYPE_HISTORY = 2
    }
}