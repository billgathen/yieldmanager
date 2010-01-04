module PatchDetector
  def needs_patching?(opts={})
    
    ruby_version, minimum_ruby_version_for_patch = opts.values_at(:ruby_version, :minimum_ruby_version_for_patch)
    
    [ruby_version, minimum_ruby_version_for_patch].each do |extracted_option|
      raise(ArgumentError, "requires :ruby_version and :minimum_ruby_version_for_patch") if extracted_option.nil? || extracted_option.empty?
    end
    
    return false if ruby_version.nil? || minimum_ruby_version_for_patch.nil?

    minimum_ruby_version_for_patch =~ /(\d+)\.(\d+)\.(\d+)/
    min_release_milestone, min_release_feature, min_release_bug_fix = [$1, $2, $3].collect(&:to_i)
    
    ruby_version =~ /(\d+)\.(\d+)\.(\d+)/
    ruby_version_milestone, ruby_version_feature, ruby_version_bug_fix = [$1, $2, $3].collect(&:to_i)
  
    return true if (ruby_version_milestone >= min_release_milestone) && (ruby_version_feature >= min_release_feature) && (ruby_version_bug_fix >= min_release_bug_fix)  
    return false
  end
end

