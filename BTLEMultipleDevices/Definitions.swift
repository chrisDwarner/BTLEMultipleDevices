//
//  Definitions.swift
//  Bluetooth
//
//  Created by Mick on 12/20/14.
//  Copyright (c) 2014 MacCDevTeam LLC. All rights reserved.
//

import CoreBluetooth

let TRANSFER_SERVICE_UUID = "EAD14537-9287-6482-6A5B-BE66D118FAC2"
let TRANSFER_CHARACTERISTIC_UUID = "A495FF11-C5B1-4B44-B512-1370F02D74DE"
let NOTIFY_MTU = 20

let transferServiceUUID = CBUUID(string: TRANSFER_SERVICE_UUID)
let transferCharacteristicUUID = CBUUID(string: TRANSFER_CHARACTERISTIC_UUID)
