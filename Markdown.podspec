Pod::Spec.new do |s|
  s.name         = "Markdown"
  s.version      = "5.0.0"
  s.summary      = "Markdown parser in swift."
  s.description  = <<-DESC
                   Markdown parser in swift.
                   Uses regular expressions and multiple passes over the Markdown document
                   to build a DOM Tree that may be serialized into different formats.

                   Included renderers:
                   - HTML
                   - Plain Text
                   - NSAttributedString
                   DESC

  s.homepage     = "https://github.com/anfema/amp-ios-client"
  s.license      = { :type => "BSD", :file => "Markdown/LICENSE.txt" }
  s.author             = { "Johannes Schriewer" => "j.schriewer@anfe.ma" }
  s.social_media_url   = "http://twitter.com/dunkelstern"

  s.ios.deployment_target = "13.0"
  s.osx.deployment_target = "11.0"
  s.swift_version = '5.5'
  
  s.source       = { :git => "git@github.com:anfema/amp-ios-client.git", :tag => "markdown-5.0.0" }
  s.source_files  = "Markdown/src/*.swift"
  
end
