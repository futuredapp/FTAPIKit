Pod::Spec.new do |s|
  s.name         = "FTAPIKit"
  s.version      = "0.4.1"
  s.summary      = "Declarative, generic REST API framework using URLSession and Codable"
  s.description  = <<-DESC
    Protocol-oriented REST API library for communication with REST APIs.
    APIEndpoint protocols allow description of the API access points
    and the requests/responses codable types. APIAdapter handles execution
    of calls to this endpoints.
  DESC
  s.homepage     = "https://github.com/thefuntasty/FTAPIKit"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Matěj Kašpar Jirásek" => "matej.jirasek@thefuntasty.com" }
  s.social_media_url   = "https://twitter.com/thefuntasty"
  s.default_subspec = 'Core'
  s.swift_version = "4.2"
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/thefuntasty/FTAPIKit.git", :tag => s.version.to_s }

  s.subspec 'Core' do |ss|
    ss.source_files  = "Sources/FTAPIKit/*"
    ss.framework  = "Foundation"
    ss.ios.framework = "MobileCoreServices"
    ss.tvos.framework = "MobileCoreServices"
    ss.watchos.framework = "MobileCoreServices"
  end

  s.subspec 'PromiseKit' do |ss|
    ss.source_files = Dir['Sources/FTAPIKitPromises/*']
    ss.dependency 'PromiseKit', '~> 6.0'
    ss.dependency 'FTAPIKit/Core'
  end
end
