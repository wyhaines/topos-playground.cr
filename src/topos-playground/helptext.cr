class ToposPlayground
  HelpText = <<-EHELP

    topos-playground is a CLI tool which handles all of the orchestration necessary to run local Topos devnets with subnets, a TCE network, and apps.


    Example Usage

      $ topos-playground start
        Start the Topos-Playground. This command will output the status of the playground creation to the terminal as it runs, and will log a more detailed status to a log file.

      $ topos-playground start --verbose
        This will also start the topos playground, but the terminal output as well as the log file output will contain more information.
        This is useful for debugging if there are errors starting the playground.

      $ topos-playground start -q
        This will start the topos playground quietly. Most output will be suppressed.

      $ topos-playground clean
        This will clean the topos playground. It will shut down all containers, and remove all filesystem artifacts except for log files.

      $ topos-playground version
        This will print the version of the topos playground.

      $ topos-playground version -q')
        This will print only the numbers of the topos-playground version, with no other output.

    Configuration

      topos-playground follows the XDG Base Directory Specification, which means that data files for use during runs of the playground are stored in $XDG_DATA_HOME/topos-playground, which defaults to $HOME/.local/share/topos-playground and log files are stored in $XDG_STATE_HOME/topos-playground/logs, which defaults to $HOME/.local/state/topos-playground/logs.

      These locations can be overridden by setting the environment variables HOME, XDG_DATA_HOME, and XDG_STATE_HOME.

    Component Versions

      #{ToposPlayground::Command::Init::GIT_REPOS.map {|data| "#{data[:repo]}: #{data[:branch]}"}.join("\n  ")} 
    EHELP
end
