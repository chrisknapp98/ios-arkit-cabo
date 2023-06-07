//
//  SequenceExtension.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 07.06.23.
//

import Foundation

extension Sequence {
    func forEachAsync(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
