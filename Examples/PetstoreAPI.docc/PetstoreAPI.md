# Petstore API

The Swagger Petstore is a sample API that demonstrates the capabilities of OpenAPI and provides a simple pet store interface.

## Overview

This API allows you to manage pets, orders, and users in a pet store. You can:

- Add, update, and remove pets from the store
- Place and track orders for pets
- Manage user accounts

## Getting Started

To use this API, you'll need to:

1. Create an account to get your API key
2. Use the API key in the `api_key` header for authenticated endpoints
3. Start making requests to the available endpoints

## Topics

### Endpoints

- ``listPets()``
- ``createPet(_:)``
- ``getPet(id:)``
- ``updatePet(_:)``
- ``deletePet(id:)``

### Data Models

- ``Pet``
- ``Category``
- ``Tag``
- ``Order``
- ``User``

### Authentication

- ``ApiKeyAuth``
- ``OAuth2Auth``

## Example Usage

Here's a quick example of how to fetch a pet by ID:

```swift
let client = PetstoreAPI.Client(apiKey: "your-api-key")

client.getPet(id: 123) { result in
    switch result {
    case .success(let pet):
        print("Found pet: \(pet.name)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## API Reference

For detailed information about each endpoint and data type, see the API Reference section. 
