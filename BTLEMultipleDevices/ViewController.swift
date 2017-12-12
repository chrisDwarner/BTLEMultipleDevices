//
//  ViewController.swift
//  BTLEMultipleDevices
//
//  Created by chris warner on 12/12/17.
//  Copyright © 2017 chris warner. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var updates: UITextView!

    fileprivate var centralManager: CBCentralManager?
    fileprivate var discoveredPeripherals: [CBPeripheral] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Start up the CBCentralManager
        centralManager = CBCentralManager(delegate: self, queue: nil)
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

    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected from \(peripheral). (\(error!.localizedDescription))")

        cleanup(peripheral: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")

        cleanup(peripheral: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered \(String(describing: peripheral.name)) at \(RSSI)")

        // Ok, it's in range - have we already seen it?

        if  peripheral.name == "Bean+"  && peripheral.state == .disconnected  {
            // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
            discoveredPeripherals.insert(peripheral, at:0 )

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            // And connect
            print("Connecting to peripheral \(peripheral)")

            centralManager?.connect(peripheral, options: nil)
        }

    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

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

