module Ohai
  module Mixin

    # This module helps in splitting a given command on spaces. Since Java's ProcessBuilder expects an array of command and arguments
    # we need to take care of splitting the command that the Ohai plugins pass.
    module CommandSplitter
      def quoted_command_parts(command)
        in_quote = false
        original_command = ""
        all_quoted_word = []
        word = ""
        command.chars.each do |char|
          if char == "\""
            in_quote = !in_quote
            if !in_quote
              all_quoted_word << word
              word = ""
              original_command = original_command + "__SOMETHING_THAT_MOST_LIKELY_IS_NOT_IN_THE_ARGUMENTS__"
            end
          else
            if in_quote
              word = word + char.to_s
            else
              original_command = original_command + char.to_s
            end
          end
        end
        return original_command, all_quoted_word
      end

      # This splits the command on a space. Whatever is in a quote is treated as a sinle entity and is not splitted
      # For example: ruby -e "puts 'hello world'" would become: [ruby, -e, puts 'hello world']. Note that the double quotes
      # are not retained
      def split_command(command)
        command, quoted = quoted_command_parts(command)
        quote_replaced_command = command.split
        command_parts = []
        quote_replaced_command.each do |t|
          if t == "__SOMETHING_THAT_MOST_LIKELY_IS_NOT_IN_THE_ARGUMENTS__"
            command_parts << quoted.delete_at(0)
          else
            command_parts << t
          end
        end
        command_parts
      end
    end
  end
end
