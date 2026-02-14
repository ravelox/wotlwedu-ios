import Foundation

final class MediaService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func createImageRecord(name: String, description: String?, workgroupId: String? = nil) async throws -> WotlweduImage {
        struct Payload: Encodable { let name: String; let description: String?; let workgroupId: String? }
        let endpoint = Endpoint(
            path: "image/",
            method: .post,
            body: try JSONEncoder.api.encode(Payload(name: name, description: description, workgroupId: workgroupId))
        )
        let response: APIResponse<WotlweduImage> = try await api.send(endpoint)
        guard let data = response.data else { throw APIError.server(message: response.message ?? "Missing image data", url: nil) }
        return data
    }

    func updateImageRecord(id: String, name: String, description: String?, workgroupId: String? = nil) async throws -> WotlweduImage {
        struct Payload: Encodable { let name: String; let description: String?; let workgroupId: String? }
        let endpoint = Endpoint(
            path: "image/\(id)",
            method: .put,
            body: try JSONEncoder.api.encode(Payload(name: name, description: description, workgroupId: workgroupId))
        )
        let response: APIResponse<WotlweduImage> = try await api.send(endpoint)
        guard let data = response.data else { throw APIError.server(message: response.message ?? "Missing image data", url: nil) }
        return data
    }

    func uploadImageFile(imageId: String, data: Data, fileExtension: String = "jpg", mimeType: String = "image/jpeg") async throws {
        let boundary = UUID().uuidString
        var body = Data()

        func append(_ string: String) {
            if let data = string.data(using: .utf8) {
                body.append(data)
            }
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"fileextension\"\r\n\r\n")
        append("\(fileExtension)\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"imageUpload\"; filename=\"upload.\(fileExtension)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        append("\r\n")
        append("--\(boundary)--\r\n")

        var endpoint = Endpoint(path: "image/file/\(imageId)", method: .post)
        endpoint.contentType = "multipart/form-data; boundary=\(boundary)"
        endpoint.body = body
        let _: APIResponse<MessageResponse> = try await api.send(endpoint)
    }
}
