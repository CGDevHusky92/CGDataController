Pod::Spec.new do |s|
  s.name             = "CGDataController"
  s.version          = "0.7.5"
  s.summary          = "CGDataController is an asynchronous core data library to help manage different models."
  s.description      = <<-DESC
                       CGDataController is an asynchronous core data library to help manage different models. Make it easier to generate different class objects and modify them with information necessary for a much more seemless synchronization.
                       DESC
  s.license          = 'MIT'
  s.homepage         = 'http://www.revision-works.com/'
  s.author           = { "Chase Gorectke" => "nbvikingsidiot001@gmail.com" }
  s.source           = { :git => "https://github.com/CGDevHusky92/CGDataController.git", :tag => "0.7.5" }

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Classes/'
  s.public_header_files = 'Classes/**/*.h'
  s.frameworks = 'CoreData', 'Foundation'
end
