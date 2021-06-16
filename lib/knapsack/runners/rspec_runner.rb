module Knapsack
  module Runners
    class RSpecRunner
      def self.run(args)
        allocator = Knapsack::AllocatorBuilder.new(Knapsack::Adapters::RSpecAdapter).allocator

        Knapsack.logger.info
        Knapsack.logger.info 'Report specs:'
        Knapsack.logger.info allocator.report_node_tests
        Knapsack.logger.info
        Knapsack.logger.info 'Leftover specs:'
        Knapsack.logger.info allocator.leftover_node_tests
        Knapsack.logger.info

        # https://github.com/rails/spring/issues/113#issuecomment-135896880
        generated_seed = srand % 0xFFFF unless ARGV.any? { |arg| arg =~ /seed/ }

        circle_cmd = %Q[bin/rspec #{args} --seed #{generated_seed} --default-path #{allocator.test_dir} -- #{allocator.stringify_node_tests}]
        files = circle_cmd.scan(/"\/home\/circleci\/super_samurai\/.*"/)
        files_without_circle_path = files.map { |f| f.gsub(Regexp.new(Regexp.escape('/home/circleci/super_samurai/')), '') }.join('')
        bisect_command = "bin/rspec --seed #{generated_seed} #{files_without_circle_path} --bisect"

        output = <<~HEREDOC
          Underlying rspec command invoked by knapsack:
          #{circle_cmd}


          *** Transient failure? Bisect can help! ***
          ~~ Option 1 Non-parallel:
          DISABLE_SPRING=1 #{bisect_command}


          ~~ Option 2 Parallel:
          If you haven't already, you need to setup the extra databases first:
          rake parallel:create

          Run bisect in parallel:
          /usr/bin/env TEST_ENV_NUMBER=2 DISABLE_SPRING=1 parallel_rspec -n 1 -e '#{bisect_command}'


        HEREDOC

        puts output
        system(circle_cmd)
        exit($?.exitstatus) unless $?.exitstatus == 0
      end
    end
  end
end
