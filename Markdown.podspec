Pod::Spec.new do |s|
  s.name         = "Markdown"
  s.version      = "1.0.7"
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

  s.ios.deployment_target = "8.4"
  s.osx.deployment_target = "10.10"

  s.source       = { :git => "git@github.com:anfema/amp-ios-client.git", :tag => "markdown-1.0.7" }
  s.source_files  = "Markdown/src/*.swift"  
end
