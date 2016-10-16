module Open3
  # @param [Array<String>] - command to execute
  # @return [String, String, Process::Status] - stdout, stderr, status
  def capture3(*cmd)
    out_r, out_w = IO.pipe
    err_r, err_w = IO.pipe
    pid = spawn(*cmd, { 'out' => out_w.to_i, 'err' => err_w.to_i })

    out_w.close
    err_w.close

    stdout = ''
    stderr = ''
    output = { out_r => stdout, err_r => stderr }

    remaining_ios = [out_r, err_r]
    until remaining_ios.empty?
      readable_ios, = IO.select(remaining_ios)
      readable_ios.each do |io|
        begin
          loop do
            begin
              output[io] << io.read_nonblock
            rescue Errno::EAGAIN
              break
            end
          end
        #rescue EOFError
        #  remaining_ios.delete(io)
        end
      end
    end

    _, status = Process.waitpid2(pid)
    [stdout, stderr, status]
  end
  module_function :capture3
end
