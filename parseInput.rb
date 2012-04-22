require './util'

inputFile = ARGV[0]
if inputFile.nil? or inputFile == ""
    puts "Input file was not specified!"
	puts " ruby parseInput.rb <file>"
	exit
end
outputDir = "samples"

lines = IO.readlines(inputFile)
n = 1
outfile = nil
out = nil
Dir.mkdir(outputDir) if (not File.directory?(outputDir))
# flag to indicate if the next line will be the start of a new sentance
lineStartsSentance = 1

lines.each do |line|
    line = line.force_encoding('ASCII-8BIT')
    line.gsub!(/[#{194.chr}#{160.chr}]/, "")  # weird characters, get rid of them!
    line.gsub!(/#{146.chr}/, "'")
    
    line = Util.addPuncMarkup(line, lineStartsSentance)
    lineStartsSentance = (line =~ /(<stop>|<excalamation>|<question>)\s+$/) ? 1 : 0
    
    # first line: start a new sample file
    if (line =~ /<start> Team\s*<comma>$/i)
        outfile = "#{outputDir}/sample-#{n}.txt"
        puts "Writing #{outfile}"
        out = File.new(outfile, "w")
        lineStartsSentance = 1
    # ignore the 'best regards' at the end, he doesn't really mean it
    elsif (line =~ /<start> (best)?\s*(regards|wishes)\s*(<comma>)?\s*$/i)
        next
    # end of message, close the sample file
    elsif (line =~ /<start> Tom$/)
        outfile = nil
        out.close
        n += 1
    else
        if (not outfile.nil?)
            out.print("#{line}\n")
        else
            if not line.empty?
                puts "I have a line to print, but no file to print it to! n = #{n}!"
                puts "line = '#{line}'"
            end
        end
    end
end
