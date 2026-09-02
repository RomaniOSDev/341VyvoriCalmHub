import UIKit

enum AppLinks: String {
    case privacy = "https://vyvori341calmhub.site/privacy/446"
    case terms = "https://vyvori341calmhub.site/terms/446"

    var url: URL? { URL(string: rawValue) }
}
