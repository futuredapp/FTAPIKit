# ``FTAPIKit``

Declarative async/await REST API framework using Swift Concurrency and Codable.

## Overview

Declarative async/await REST API framework using `Codable`.
With standard implementation using `URLSession` and JSON encoder/decoder.
Built for Swift 6.1+ with full concurrency safety.

![Tree with a API Client root element. Its branches are servers. Each server branch has some endpoint branches.](Architecture)

## Topics

### Server

- ``URLServer``

### Endpoint

- ``Endpoint``
- ``DataEndpoint``
- ``UploadEndpoint``
- ``MultipartEndpoint``
- ``URLEncodedEndpoint``
- ``EncodableEndpoint``
- ``ResponseEndpoint``
- ``RequestEndpoint``
- ``RequestResponseEndpoint``

### Request Configuration

- ``RequestConfiguring``

### Endpoint configuration

- ``HTTPMethod``
- ``URLQuery``
- ``MultipartBodyPart``

### Encoding and decoding

- ``Encoding``
- ``JSONEncoding``
- ``Decoding``
- ``JSONDecoding``

### Observers

- ``NetworkObserver``

### Error handling

- ``APIError``
- ``APIErrorStandard``
