import Foundation

struct MultipartFormDataBuilder {
    private let boundary: String = "Boundary-\(UUID().uuidString)"
    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    func build(parts: [(name: String, filename: String?, mime: String?, data: Data)]) -> (Data, String) {
        var body = Data()
        let lb = "\r\n"
        for part in parts {
            body.append("--\(boundary)\(lb)".data(using: .utf8)!)
            if let filename = part.filename, let mime = part.mime {
                body.append("Content-Disposition: form-data; name=\(part.name); filename=\(filename)\(lb)".data(using: .utf8)!)
                body.append("Content-Type: \(mime)\(lb + lb)".data(using: .utf8)!)
            } else {
                body.append("Content-Disposition: form-data; name=\(part.name)\(lb + lb)".data(using: .utf8)!)
            }
            body.append(part.data)
            body.append(lb.data(using: .utf8)!)
        }
        body.append("--\(boundary)--\(lb)".data(using: .utf8)!)
        return (body, contentType)
    }
}