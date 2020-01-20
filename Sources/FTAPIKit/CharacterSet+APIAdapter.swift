import Foundation

extension CharacterSet {
    private static let urlGeneralDelimiters: CharacterSet = [":", "/", "?", "#", "[", "]", "@"]
    private static let urlSubDelimiters: CharacterSet = ["!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="]
    private static let urlDelimiters = CharacterSet.urlGeneralDelimiters.union(.urlSubDelimiters)

    /// https://tools.ietf.org/html/rfc3986#section-2.2
    static let urlQueryNameValueAllowed = CharacterSet.urlQueryAllowed.subtracting(.urlDelimiters)
}
