import Foundation

extension CharacterSet {
    private static let urlGeneralDelimiters: CharacterSet = [":", "/", "?", "#", "[", "]", "@"]
    private static let urlSubDelimiters: CharacterSet = ["!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="]
    private static let urlDelimiters = CharacterSet.urlGeneralDelimiters.union(.urlSubDelimiters)

    /// All characters allowed in URL query name or value.
    ///
    /// > Note: The list of characters is derived from
    /// > [RFC-3986 Section 2.2](https://tools.ietf.org/html/rfc3986#section-2.2).
    static let urlQueryNameValueAllowed = CharacterSet.urlQueryAllowed.subtracting(.urlDelimiters)
}
