Pod::Spec.new do |s|
  s.name                        = "FTAPIKit"
  s.version                     = "1.1.2"
  s.summary                     = "Declarative, generic and protocol-oriented REST API framework using URLSession and Codable"
  s.description                 = <<-DESC
    Protocol-oriented framework for communication with REST APIs.
    Endpoint protocols describe the API resource access points
    and the requests/responses codable types. Server protocol describes web services
    and enables the user to call endoints in a type-safe manner.
  DESC
  s.homepage                    = "https://github.com/futuredapp/FTAPIKit"
  s.license                     = { type: "MIT", file: "LICENSE" }
  s.author                      = { "Matěj Kašpar Jirásek": "matej.jirasek@futured.app" }
  s.social_media_url            = "https://twitter.com/Futuredapps"

  s.source                      = { git: "https://github.com/futuredapp/FTAPIKit.git", tag: s.version.to_s }
  s.source_files                = "Sources/FTAPIKit/**/*"

  s.frameworks                  = ["Foundation", "CoreServices"]
  s.weak_frameworks             = ["Combine"]

  s.swift_version               = "5.1"
  s.ios.deployment_target       = "8.0"
  s.osx.deployment_target       = "10.10"
  s.watchos.deployment_target   = "5.0"
  s.tvos.deployment_target      = "12.0"
end
