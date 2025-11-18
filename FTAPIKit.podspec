Pod::Spec.new do |s|
  s.name                        = "FTAPIKit"
  s.version                     = "2.0.0"
  s.summary                     = "Declarative, async/await REST API framework using URLSession and Codable"
  s.description                 = <<-DESC
    Protocol-oriented async/await framework for communication with REST APIs.
    Endpoint protocols describe the API resource access points
    and the requests/responses codable types. Server protocol describes web services
    and enables the user to call endpoints in a type-safe manner using Swift concurrency.
  DESC
  s.homepage                    = "https://github.com/futuredapp/FTAPIKit"
  s.license                     = { type: "MIT", file: "LICENSE" }
  s.author                      = { "Matěj Kašpar Jirásek": "matej.jirasek@futured.app" }
  s.social_media_url            = "https://twitter.com/Futuredapps"

  s.source                      = { git: "https://github.com/futuredapp/FTAPIKit.git", tag: s.version.to_s }
  s.source_files                = "Sources/FTAPIKit/**/*"
  s.exclude_files               = "Sources/FTAPIKit/Documentation.docc/**/*"

  s.frameworks                  = ["Foundation"]

  s.swift_version               = "6.1"
  s.ios.deployment_target       = "15.0"
  s.osx.deployment_target       = "12.0"
  s.watchos.deployment_target   = "8.0"
  s.tvos.deployment_target      = "15.0"
end
