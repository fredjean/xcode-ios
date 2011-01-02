require 'Find'
require 'erb'

def project_file
  Find.find(PROJECT_DIR) do |f|
    if f =~ /\.xcodeproj$/
      return f
    end
  end
  nil
end

def xcodebuild
  "xcodebuild -project #{File.basename(project_file)}"
end

def project_name  
  @name ||= File.basename(project_file, ".xcodeproj")
end

def project_build_dir(configuration = "Release", sdk = "iphoneos")
  "#{PROJECT_DIR}/build/#{configuration}-#{sdk}"
end

def build_app(target = "#{project_name}", configuration = "Release", sdk = "iphoneos#{SDK_VERSION}")
  puts %x{
    #{xcodebuild} -target "#{target}" -configuration "#{configuration}" -sdk #{sdk}
  }
end

def package_app(configuration = "Release", sdk = "iphoneos", name = "#{project_name}")
  puts %x{
    /usr/bin/xcrun -sdk #{sdk} PackageApplication -v "#{project_build_dir(configuration,sdk)}/#{name}.app" \
                   -o "#{project_build_dir(configuration,sdk)}/#{name}.ipa" \
                   --sign "iPhone Distribution" \
                   --embed "#{PROJECT_DIR}/build/TWCTV_Ad_Hoc.mobileprovision"
  }
  generate_ota_plist(configuration, sdk, name)
end

def generate_ota_plist(configuration = "Release", sdk = "iphoneos", name = "#{project_name}")
  template = File.read("#{PROJECT_DIR}/#{project_name}.plist.erb")
  build_url = ENV['BUILD_URL'] || "http://test.com/"
  File.open("#{project_build_dir(configuration, sdk)}/#{name}.plist", "w+") do |f|
    f.write(ERB.new(template).result(binding))
  end
end

def clean_build(target = "#{project_name}", configuration = "Release", sdk = "iphoneos")
  puts %x{
    #{xcodebuild} -target "#{target}" -configuration "#{configuration}" -sdk "#{sdk}#{SDK_VERSION}" clean
  }
  Find.find(project_build_dir(configuration, sdk)) do |f|
    if f =~ /\.ipa$/ or f =~ /#{target}.plist$/
      puts "Deleting #{f}"
      File.delete f
    end
  end
end
