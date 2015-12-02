Pod::Spec.new do |s|
  s.name         = "mockingbird"
  s.version      = "1.0.0"
  s.summary      = "HTTP-Response mocking for iOS and OS X."
  s.description  = <<-DESC
                   HTTP-Response mocking for iOS and OS X

                   Features:
                   - Intercepts all requests going through the NSURLSession interface
                   - Allows to send binary files
                   - Mocking dataset may be changed at all times to mock server data changes
                   - Data is organized in bundles that are easy to maintain
                   DESC

  s.homepage     = "https://github.com/anfema/amp-ios-client"
  s.license      = { :type => "BSD", :file => "mockingbird/LICENSE.txt" }
  s.author             = { "Johannes Schriewer" => "j.schriewer@anfe.ma" }
  s.social_media_url   = "http://twitter.com/dunkelstern"

  s.ios.deployment_target = "8.4"
  s.osx.deployment_target = "10.10"

  s.source       = { :git => "git@github.com:anfema/amp-ios-client.git", :tag => "mocking-1.0.0" }
  s.source_files  = "amp-client/cache/*.swift", "amp-client/communication/*.swift", "amp-client/helper/*.swift", "amp-client/model/**/*.swift", "amp-client/search/*.swift"
  
  s.framework  = "Alamofire", "DEjson"

  s.dependency "Alamofire", "~> 3.0"
  s.dependency "DEjson", "~> 1.0"
end
