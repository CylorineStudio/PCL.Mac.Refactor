//
//  UUIDUtilsTest.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/14.
//

import Foundation
import Core
import Testing

struct UUIDUtilsTest {
    @Test func test() throws {
        let uuid: UUID = .init(uuidString: "01234567-0123-0123-0123-0123456789AB")!
        #expect(UUIDUtils.string(of: uuid, withHyphens: false) == "012345670123012301230123456789AB".lowercased())
        #expect(UUIDUtils.string(of: uuid, withHyphens: true) == "01234567-0123-0123-0123-0123456789AB".lowercased())
        #expect(UUIDUtils.uuid(of: "012345670123012301230123456789AB") == uuid)
        #expect(UUIDUtils.uuid(of: "01234567-0123-0123-0123-0123456789AB") == uuid)
        #expect(throws: UUIDError.invalidUUIDFormat) {
            _ = try UUIDUtils.uuidThrowing(of: "01234567-0123-0123-0123-0123456789A")
        }
        #expect(throws: UUIDError.invalidUUIDFormat) {
            _ = try UUIDUtils.uuidThrowing(of: "01234567-0123-0123-0123-012#456789AB")
        }
    }
}
