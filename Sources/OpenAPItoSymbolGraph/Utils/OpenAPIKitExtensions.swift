import Foundation
import OpenAPIKit

// Extensions to provide compatibility with our code that accesses OpenAPIKit differently than its current API

// MARK: - Example Compatibility

/// Providing an OpenAPIKit.Example type to match our usage in formatExamples
extension OpenAPIKit.OpenAPI {
    struct Example {
        let summary: String?
        let description: String?
        let value: Any?
        let externalValue: URL?

        init(from apiExample: OpenAPIKit.OpenAPI.Example) {
            self.summary = apiExample.summary
            self.description = apiExample.description
            self.value = apiExample.value?.value
            self.externalValue = apiExample.externalValue
        }
    }
}

// MARK: - Operation Extensions

extension OpenAPIKit.OpenAPI.Operation {
    /// Compatibility accessor for operationId
    var operationId: String? {
        // Access the operationId based on current OpenAPIKit structure
        // In OpenAPIKit 3.x, this is likely directly available
        return self.id
    }

    /// Compatibility accessor for security requirements
    var security: [OpenAPIKit.OpenAPI.SecurityRequirement]? {
        // Access the security based on OpenAPIKit structure
        // In OpenAPIKit 3.x, this might be in a different location
        return self.securityRequirements
    }
}

// MARK: - Parameter Extensions

extension OpenAPIKit.OpenAPI.Parameter {
    /// Compatibility accessor for description
    var description: String? {
        // In OpenAPIKit 3.x, the description might be in a different location
        return self.parameterSchemaOrContent.schemaValue?.description
    }
}

// MARK: - Info Extensions

extension OpenAPIKit.OpenAPI.Document.Info {
    /// Compatibility accessor for contact information
    var contact: Contact? {
        // In OpenAPIKit 3.x, contact information might be structured differently
        return self._contact
    }

    // Define a nested type to match our code's expected structure
    struct Contact {
        var name: String?
        var email: String?
        var url: URL?

        init?(from openAPIContact: OpenAPIKit.OpenAPI.Document.Info.Contact?) {
            guard let contact = openAPIContact else { return nil }
            self.name = contact.name
            self.email = contact.email
            self.url = contact.url
        }
    }
}

// MARK: - Helper methods for converting between types

extension OpenAPIKit.OpenAPI.Document.Info {
    /// Provide the contact information in our expected format
    fileprivate var _contact: Contact? {
        return Contact(from: self.contact)
    }
}

// MARK: - JSONSchema Extensions

extension JSONSchema {
    /// Get the description from the schema
    var description: String? {
        return coreContext.description
    }
}

// MARK: - PathItem Extensions

extension OpenAPIKit.OpenAPI.PathItem {
    /// Get all operations in this path item as (method, operation) pairs
    func allOperations() -> [(OpenAPIKit.OpenAPI.HttpMethod, OpenAPIKit.OpenAPI.Operation)] {
        var operations: [(OpenAPIKit.OpenAPI.HttpMethod, OpenAPIKit.OpenAPI.Operation)] = []

        if let get = self.get {
            operations.append((.get, get))
        }
        if let put = self.put {
            operations.append((.put, put))
        }
        if let post = self.post {
            operations.append((.post, post))
        }
        if let delete = self.delete {
            operations.append((.delete, delete))
        }
        if let options = self.options {
            operations.append((.options, options))
        }
        if let head = self.head {
            operations.append((.head, head))
        }
        if let patch = self.patch {
            operations.append((.patch, patch))
        }
        if let trace = self.trace {
            operations.append((.trace, trace))
        }

        return operations
    }
}
