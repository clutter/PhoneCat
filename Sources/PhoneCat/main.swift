import ArgumentParser
import Combine
import CSV
import Foundation

struct PhoneCat: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for exporting MDM Data.",
        version: "1.0.0",
        subcommands: [Devices.self, Groups.self]
    )
}

struct Options: ParsableArguments {
    @Option(
        help: "SimpleMDM API Token."
    )
    var token: String
}

extension PhoneCat {
    struct Devices: ParsableCommand {
        static var configuration =
            CommandConfiguration(abstract: "List All Devices in MDM.")

        @OptionGroup var options: Options

        private func fetchDevices(token: String) throws -> [SimpleMDM.Device] {
            return try SimpleMDM.API(token: token)
                .allDevices()
                .awaitOutput()
        }

        mutating func run() throws {
            let devices = try fetchDevices(token: options.token)

            let csv = try CSVWriter(stream: .toMemory())
            try csv.write(row: ["id", "name", "serial", "udid"])

            for device in devices {
                csv.beginNewRow()
                try csv.write(field: String(device.id))
                try csv.write(field: device.name)
                try csv.write(field: device.serial)
                try csv.write(field: device.UDID)
            }

            csv.stream.close()

            let csvData = csv.stream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
            let csvString = String(data: csvData, encoding: .utf8)!
            print(csvString)
        }
    }
}

extension PhoneCat {
    struct Groups: ParsableCommand {
        static var configuration =
            CommandConfiguration(abstract: "List Device Groups in MDM.")

        @OptionGroup var options: Options

        private func fetchGroups(token: String) throws -> [SimpleMDM.Group] {
            return try SimpleMDM.API(token: token)
                .allGroups()
                .awaitOutput()
        }

        mutating func run() throws {
            let groups = try fetchGroups(token: options.token)

            let csv = try CSVWriter(stream: .toMemory())
            try csv.write(row: ["id", "name"])

            for group in groups {
                csv.beginNewRow()
                try csv.write(field: String(group.id))
                try csv.write(field: group.name)
            }

            csv.stream.close()

            let csvData = csv.stream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
            let csvString = String(data: csvData, encoding: .utf8)!
            print(csvString)
        }
    }
}


PhoneCat.main()
