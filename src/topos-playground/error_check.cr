class ToposPlayground
  def error_check
    check_for_conflicting_verbose_and_quiet
    verify_working_directory_existence
    verify_execution_path_existence
  end

  private def check_for_conflicting_verbose_and_quiet
    if config.verbose? && config.quiet?
      Error.error { "You can't use both --verbose and --quiet at the same time." }
      exit 1
    end
  end

  private def verify_working_directory_existence
  end

  private def verify_execution_path_existence
  end
end
