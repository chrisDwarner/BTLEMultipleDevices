//
//  ViewController.swift
//  BTLEMultipleDevices
//
//  Created by chris warner on 12/12/17.
//  Copyright © 2017 chris warner. All rights reserved.
//

import UIKit
import CoreBluetooth


// data service UUID: A495FF10-C5B1-4B44-B512-1370F02D74DE

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var updates: UITextView!

    fileprivate var centralManager: CBCentralManager?
    fileprivate var discoveredPeripherals: [CBPeripheral] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Start up the CBCentralManager
        centralManager = CBCentralManager(delegate: self, queue: nil)
        updates.text = ""

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        print("Stopping scan")
        if let manager = centralManager {
            manager.stopScan()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func update( withString string: String ) {
        DispatchQueue.main.async {
            self.updates.text = self.updates.text + "\n" + string
            let range = NSMakeRange((self.updates.text as NSString).length-1, 1)
            self.updates.scrollRangeToVisible(range)
        }
    }
    
    @IBAction func startScanningAction(_ sender: Any) {
        print("Start scan")
        if let manager = centralManager {
            let scanningOptions:[String:Any] = [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: true as Bool)]
            manager.scanForPeripherals( withServices: nil, options: scanningOptions)
        }
    }

    @IBAction func stopScanningAction(_ sender: Any) {
        print("Stopping scan")
        if let manager = centralManager {
            manager.stopScan()
        }
    }

    fileprivate func cleanup(peripheral: CBPeripheral) {

        let idx = discoveredPeripherals.index(of: peripheral)
        if let index = idx {
            discoveredPeripherals.remove(at: index )
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        // Don't do anything if we're not connected
        // self.discoveredPeripheral.isConnected is deprecated
        guard peripheral.state == .connected else {
            return
        }

        // See if we are subscribed to a characteristic on the peripheral
        guard let services = peripheral.services else {
            if let manager = centralManager {
                manager.cancelPeripheralConnection(peripheral)
            }
            return
        }

        for service in services {
            guard let characteristics = service.characteristics else {
                continue
            }

            for characteristic in characteristics {
                if characteristic.isNotifying {
//                    if characteristic.uuid.isEqual(transferCharacteristicUUID) && characteristic.isNotifying {
                    peripheral.setNotifyValue(false, for: characteristic)
                    // And we're done.
                    return
                }
            }
        }
    }

    //MARK: - CBCentralManagerDelegate methods
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected \(String(describing: peripheral.name)) UUID \(peripheral.identifier.uuidString)")

        let string:String = "Connected to \(peripheral)."
        print(string)
        self.update(withString: string)
        peripheral.delegate = self
        peripheral.discoverServices(nil)

    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected from \(peripheral). (\(error!.localizedDescription))")
        let string:String = "disconnected from \(peripheral)."
        print(string)
        self.update(withString: string)

        cleanup(peripheral: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")

        cleanup(peripheral: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        // Ok, it's in range - have we already seen it?

        if  peripheral.name == "Bean+"  && peripheral.state == .disconnected  {
            let string:String = "Discovered \(String(describing: peripheral.name)) UUID \(peripheral.identifier.uuidString) at \(RSSI)"
            print(string)

            // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
            discoveredPeripherals.insert(peripheral, at:0 )

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }

            self.update(withString: string)

            // And connect
            print("Connecting to peripheral \(peripheral)")

            centralManager?.connect(peripheral, options: nil)
        }

    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            cleanup(peripheral: peripheral)
            return
        }

        guard let services = peripheral.services else {
            return
        }

        // Discover the characteristic we want...

        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        for service in services {
            let string:String = "services\(service)"
            print(string)
            self.update(withString: string)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Deal with errors (if any)
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            cleanup(peripheral: peripheral)
            return
        }


        guard let characteristics = service.characteristics else {
            return
        }

        // Again, we loop through the array, just in case.
        for characteristic in characteristics {
            let string:String = "characteristic \(characteristic)"
            print(string)
            self.update(withString: string)

//            // And check if it's the right one
//            if characteristic.uuid.isEqual(transferCharacteristicUUID) {
//                // If it is, subscribe to it
//                peripheral.setNotifyValue(true, for: characteristic)
//            }
        }
        // Once this is complete, we just need to wait for the data to come in.
    }


    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredPeripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell?
        cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        if let cell = cell {
            let peripheral = discoveredPeripherals[indexPath.row]

            if let name = peripheral.name {
                cell.textLabel?.text = name
            }
            let identifier = peripheral.identifier
            cell.detailTextLabel?.text = identifier.uuidString

        }
        return cell!
    }

}

