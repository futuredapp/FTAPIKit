Pod::Spec.new do |spec|
  spec.name         = "FTAPIKit"
  spec.version      = "0.4.0"
  spec.summary      = "Declarative, generic REST API framework using URLSession and Codable"
  spec.description  = <<-DESC
    Protocol-oriented REST API library for communication with REST APIspec.
    APIEndpoint protocols allow description of the API access points
    and the requests/responses codable typespec. APIAdapter handles execution
    of calls to this endpointspec.
  DESC
  spec.homepage     = "https://github.com/thefuntasty/FTAPIKit"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "Matěj Kašpar Jirásek" => "matej.jirasek@thefuntasty.com" }
  spec.social_media_url   = "https://twitter.com/thefuntasty"
  spec.ios.deployment_target = "8.0"
  spec.osx.deployment_target = "10.9"
  spec.watchos.deployment_target = "2.0"
  spec.tvos.deployment_target = "9.0"
  spec.source       = { :git => "https://github.com/thefuntasty/FTAPIKit.git", :tag => spec.version.to_s }
  spec.source_files  = "Sources/**/*"
  spec.frameworks  = "Foundation"
  spec.swift_version = "5.0"

  spec.subspec 'PromiseKit' do |subspec|
    subspec.source_files = Dir['Extensions/PromiseKit/*']
    subspec.dependency 'PromiseKit', '~> 6.0'
  end
end
