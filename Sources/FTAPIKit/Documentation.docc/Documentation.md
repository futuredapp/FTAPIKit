# ``FTAPIKit``

Declarative, generic and protocol-oriented REST API framework using `URLSession` and `Codable`

## Overview

Declarative and generic REST API framework using `Codable`.
With standard implementation using `URLSesssion` and JSON encoder/decoder.
Easily extensible for your asynchronous framework or networking stack.

![Tree with a API Client root element. Its branches are servers. Each server branch has some endpoint branches.](Architecture)

## Topics

### Server

- ``Server``
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

### Encoding and decoding

- ``Encoding``
- ``JSONEncoding``
- ``Decoding``
- ``JSONDecoding``

### Error handling

- ``APIError``
- ``APIErrorStandard``
